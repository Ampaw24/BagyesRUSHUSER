import 'dart:async';

import 'package:uuid/uuid.dart';

import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/chat/model/chat_message.dart';
import 'package:bagyesrushappusernew/src/chat/model/conversation.dart';
import 'package:bagyesrushappusernew/src/chat/repository/chat_repository.dart';
import 'package:bagyesrushappusernew/src/chat/view/chat_thread_args.dart';

/// Sealed states for a single conversation thread.
sealed class ChatThreadState {
  const ChatThreadState();
}

class ChatThreadLoading extends ChatThreadState {
  const ChatThreadLoading();
}

class ChatThreadError extends ChatThreadState {
  const ChatThreadError({required this.message});
  final String message;
}

/// [messages] is always kept **ascending** (oldest first) for a
/// bottom-anchored view — the API itself returns newest-first, reversed on
/// the way in.
class ChatThreadLoaded extends ChatThreadState {
  const ChatThreadLoaded({
    required this.conversation,
    required this.messages,
    required this.hasMoreOlder,
    this.isLoadingOlder = false,
    this.isSending = false,
  });

  final Conversation conversation;
  final List<ChatMessage> messages;
  final bool hasMoreOlder;
  final bool isLoadingOlder;
  final bool isSending;

  ChatThreadLoaded copyWith({
    Conversation? conversation,
    List<ChatMessage>? messages,
    bool? hasMoreOlder,
    bool? isLoadingOlder,
    bool? isSending,
  }) => ChatThreadLoaded(
    conversation: conversation ?? this.conversation,
    messages: messages ?? this.messages,
    hasMoreOlder: hasMoreOlder ?? this.hasMoreOlder,
    isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
    isSending: isSending ?? this.isSending,
  );
}

/// Screen-scoped — one fresh instance per `ChatThreadView` push, owned and
/// disposed directly by its State (mirrors `ReportDetailViewModel`).
///
/// Realtime isn't documented for this API, so new messages arrive via
/// polling (see [_pollInterval]) rather than a socket; typing/read receipts
/// are throttled/debounced client-side per the integration guide.
class ChatThreadViewModel extends ViewModel<ChatThreadState> {
  ChatThreadViewModel({required ChatRepository repository, required this.args})
    : _repository = repository,
      super(const ChatThreadLoading()) {
    _init();
  }

  static const _pollInterval = Duration(seconds: 5);
  static const _typingThrottle = Duration(seconds: 3);
  static const _readDebounce = Duration(seconds: 3);
  static const _maxBodyLength = 2000;
  static const _uuid = Uuid();

  final ChatRepository _repository;
  final ChatThreadArgs args;

  String? _nextCursor;
  Timer? _pollTimer;
  Timer? _typingTimer;
  DateTime? _lastMarkedReadAt;

  /// Re-runs the initial conversation + first-page-of-messages fetch —
  /// exposed for the error state's "Retry" action.
  Future<void> retryLoad() => _init();

  Future<void> _init() async {
    try {
      final conversation = args.conversationId != null
          ? await _repository.getConversation(args.conversationId!)
          : await _repository.getConversationForOrder(args.orderId!);
      final page = await _repository.getMessages(conversation.id);
      _nextCursor = page.nextCursor;
      emit(
        ChatThreadLoaded(
          conversation: conversation,
          messages: page.items.reversed.toList(),
          hasMoreOlder: page.hasMore,
        ),
      );
      _markReadDebounced();
      _startPolling();
    } catch (e) {
      appLogger.e('ChatThreadViewModel._init → failed', error: e);
      emit(
        ChatThreadError(
          message: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollNewMessages());
  }

  Future<void> _pollNewMessages() async {
    final current = state;
    if (current is! ChatThreadLoaded) return;
    try {
      final page = await _repository.getMessages(current.conversation.id);
      final existingIds = current.messages.map((m) => m.id).toSet();
      final existingClientUuids = current.messages
          .map((m) => m.clientUuid)
          .whereType<String>()
          .toSet();
      final freshOnes = page.items.where(
        (m) =>
            !existingIds.contains(m.id) &&
            !(m.clientUuid != null &&
                existingClientUuids.contains(m.clientUuid)),
      );
      if (freshOnes.isEmpty) return;

      final merged = [...current.messages, ...freshOnes.toList().reversed]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final latest = state;
      if (latest is! ChatThreadLoaded) return;
      emit(latest.copyWith(messages: merged));
      _markReadDebounced();
    } catch (e) {
      // Polling failures should never surface to the UI — the next tick
      // retries on its own.
      appLogger.w('ChatThreadViewModel._pollNewMessages → failed: $e');
    }
  }

  Future<void> loadOlderMessages() async {
    final current = state;
    if (current is! ChatThreadLoaded ||
        !current.hasMoreOlder ||
        current.isLoadingOlder) {
      return;
    }
    emit(current.copyWith(isLoadingOlder: true));
    try {
      final page = await _repository.getMessages(
        current.conversation.id,
        cursor: _nextCursor,
      );
      _nextCursor = page.nextCursor;
      final latest = state;
      if (latest is! ChatThreadLoaded) return;
      emit(
        latest.copyWith(
          messages: [...page.items.reversed, ...latest.messages],
          hasMoreOlder: page.hasMore,
          isLoadingOlder: false,
        ),
      );
    } catch (e) {
      appLogger.w('ChatThreadViewModel.loadOlderMessages → failed: $e');
      final latest = state;
      if (latest is ChatThreadLoaded) {
        emit(latest.copyWith(isLoadingOlder: false));
      }
    }
  }

  /// Optimistically appends [text] as a `sending` bubble, then reconciles it
  /// (by `client_uuid`) with the server row on success, or marks it
  /// `failed` — tap-to-retry — on failure.
  Future<void> sendMessage(String text) async {
    final body = text.trim();
    if (body.isEmpty || body.length > _maxBodyLength) return;
    final current = state;
    if (current is! ChatThreadLoaded || !current.conversation.isOpen) return;

    final clientUuid = _uuid.v4();
    final optimistic = ChatMessage.optimistic(
      conversationId: current.conversation.id,
      body: body,
      clientUuid: clientUuid,
      senderName: 'You',
    );
    emit(current.copyWith(messages: [...current.messages, optimistic]));

    try {
      final sent = await _repository.sendMessage(
        current.conversation.id,
        body: body,
        clientUuid: clientUuid,
      );
      _replaceByClientUuid(clientUuid, sent);
    } catch (e) {
      appLogger.w('ChatThreadViewModel.sendMessage → failed: $e');
      _markFailed(clientUuid);
    }
  }

  /// Re-sends a bubble stuck in [MessageDeliveryStatus.failed].
  Future<void> retry(ChatMessage failedMessage) async {
    final current = state;
    if (current is! ChatThreadLoaded || failedMessage.clientUuid == null) {
      return;
    }
    final clientUuid = failedMessage.clientUuid!;
    _replaceByClientUuid(
      clientUuid,
      failedMessage.copyWith(deliveryStatus: MessageDeliveryStatus.sending),
    );
    try {
      final sent = await _repository.sendMessage(
        current.conversation.id,
        body: failedMessage.body,
        clientUuid: clientUuid,
      );
      _replaceByClientUuid(clientUuid, sent);
    } catch (e) {
      appLogger.w('ChatThreadViewModel.retry → failed: $e');
      _markFailed(clientUuid);
    }
  }

  void _replaceByClientUuid(String clientUuid, ChatMessage replacement) {
    final latest = state;
    if (latest is! ChatThreadLoaded) return;
    emit(
      latest.copyWith(
        messages: [
          for (final m in latest.messages)
            if (m.clientUuid == clientUuid) replacement else m,
        ],
      ),
    );
  }

  void _markFailed(String clientUuid) {
    final latest = state;
    if (latest is! ChatThreadLoaded) return;
    emit(
      latest.copyWith(
        messages: [
          for (final m in latest.messages)
            if (m.clientUuid == clientUuid)
              m.copyWith(deliveryStatus: MessageDeliveryStatus.failed)
            else
              m,
        ],
      ),
    );
  }

  /// Throttled to roughly one call per [_typingThrottle] window while the
  /// composer has focus, per the API's guidance. Ignores failures itself
  /// (see [ChatRepository.sendTyping]).
  void notifyTyping() {
    if (_typingTimer != null) return;
    final current = state;
    if (current is! ChatThreadLoaded || !current.conversation.isOpen) return;
    _repository.sendTyping(current.conversation.id);
    _typingTimer = Timer(_typingThrottle, () => _typingTimer = null);
  }

  /// Debounced — call whenever the thread is visible (init, poll ticks) but
  /// never per-message; the endpoint returns no state worth re-fetching for.
  void _markReadDebounced() {
    final now = DateTime.now();
    if (_lastMarkedReadAt != null &&
        now.difference(_lastMarkedReadAt!) < _readDebounce) {
      return;
    }
    _lastMarkedReadAt = now;
    final current = state;
    if (current is! ChatThreadLoaded) return;
    _repository.markRead(current.conversation.id);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }
}
