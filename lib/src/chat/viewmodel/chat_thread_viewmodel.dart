import 'dart:async';

import 'package:uuid/uuid.dart';

import 'package:bagyesrushappusernew/core/services/realtime_service.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/chat/model/chat_message.dart';
import 'package:bagyesrushappusernew/src/chat/model/chat_realtime_events.dart';
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

/// Chat opens once a rider is assigned — this order hasn't got one yet
/// (the REST fetch returned 422). Distinct from [ChatThreadError] so the
/// UI can show "not available yet" instead of a generic error/retry state.
class ChatThreadUnavailable extends ChatThreadState {
  const ChatThreadUnavailable({required this.message});
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
    this.peerTyping = false,
    this.peerReadAt,
  });

  final Conversation conversation;
  final List<ChatMessage> messages;
  final bool hasMoreOlder;
  final bool isLoadingOlder;
  final bool isSending;

  /// True for a few seconds after a `conversation.typing` event — there is
  /// no "stopped typing" event, so this expires client-side on a timer.
  final bool peerTyping;

  /// Set from `conversation.read` — own messages at/before this timestamp
  /// show a "read" tick.
  final DateTime? peerReadAt;

  ChatThreadLoaded copyWith({
    Conversation? conversation,
    List<ChatMessage>? messages,
    bool? hasMoreOlder,
    bool? isLoadingOlder,
    bool? isSending,
    bool? peerTyping,
    DateTime? peerReadAt,
  }) => ChatThreadLoaded(
    conversation: conversation ?? this.conversation,
    messages: messages ?? this.messages,
    hasMoreOlder: hasMoreOlder ?? this.hasMoreOlder,
    isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
    isSending: isSending ?? this.isSending,
    peerTyping: peerTyping ?? this.peerTyping,
    peerReadAt: peerReadAt ?? this.peerReadAt,
  );
}

/// Screen-scoped — one fresh instance per `ChatThreadView` push, owned and
/// disposed directly by its State (mirrors `ReportDetailViewModel`).
///
/// New messages, typing indicators and read receipts arrive via
/// `RealtimeService`'s `private-conversation.{id}` channel; sending a
/// message/typing-ping/read-receipt stays a REST call as before — only the
/// receive side moved off polling.
class ChatThreadViewModel extends ViewModel<ChatThreadState> {
  ChatThreadViewModel({
    required ChatRepository repository,
    required RealtimeService realtimeService,
    required this.args,
  })  : _repository = repository,
        _realtimeService = realtimeService,
        super(const ChatThreadLoading()) {
    _init();
  }

  static const _typingThrottle = Duration(seconds: 3);
  static const _typingIndicatorTtl = Duration(seconds: 3);
  static const _readDebounce = Duration(seconds: 3);
  static const _maxBodyLength = 2000;
  static const _uuid = Uuid();

  final ChatRepository _repository;
  final RealtimeService _realtimeService;
  final ChatThreadArgs args;

  String? _nextCursor;
  String? _subscribedConversationId;
  StreamSubscription<ChatMessage>? _messageSub;
  StreamSubscription<ConversationTypingEvent>? _typingSub;
  StreamSubscription<ConversationReadEvent>? _readSub;
  StreamSubscription<RealtimeChannelError>? _channelErrorSub;
  Timer? _typingTimer;
  Timer? _typingIndicatorTimer;
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
      _subscribeRealtime(conversation.id);
    } on ConversationNotAvailableException catch (e) {
      emit(ChatThreadUnavailable(message: e.message));
    } catch (e) {
      appLogger.e('ChatThreadViewModel._init → failed', error: e);
      emit(
        ChatThreadError(
          message: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  void _subscribeRealtime(String conversationId) {
    _subscribedConversationId = conversationId;
    _realtimeService.subscribeToConversation(conversationId);
    _messageSub = _realtimeService.messageEvents.listen(_onIncomingMessage);
    _typingSub = _realtimeService.typingEvents.listen(_onPeerTyping);
    _readSub = _realtimeService.readEvents.listen(_onPeerRead);
    _channelErrorSub = _realtimeService.channelErrors.listen(_onChannelError);
  }

  /// A 403 here means this account isn't a participant in this conversation
  /// — shown distinctly from a generic error via [ChatThreadUnavailable]
  /// rather than [ChatThreadError]. A session-expiry error needs no
  /// separate handling here: the rest of the app's existing token-refresh/
  /// login-redirect flow already reacts to a cleared session.
  void _onChannelError(RealtimeChannelError error) {
    if (error.channelName != _realtimeService.conversationChannelName(_subscribedConversationId ?? '')) {
      return;
    }
    if (error.type != RealtimeChannelErrorType.forbidden) return;
    emit(const ChatThreadUnavailable(message: "You don't have access to this conversation."));
  }

  /// `messageEvents` is a single stream shared by whichever conversation
  /// channel(s) are currently subscribed — filtering by conversation id is
  /// required, not decorative. Dedupes by `id`/`clientUuid`, the exact rule
  /// the old polling path used, since a push notification and this socket
  /// event can both fire for the same message.
  void _onIncomingMessage(ChatMessage message) {
    final current = state;
    if (current is! ChatThreadLoaded) return;
    if (message.conversationId != current.conversation.id) return;
    final existingIds = current.messages.map((m) => m.id).toSet();
    final existingClientUuids = current.messages
        .map((m) => m.clientUuid)
        .whereType<String>()
        .toSet();
    final isDuplicate = existingIds.contains(message.id) ||
        (message.clientUuid != null && existingClientUuids.contains(message.clientUuid));
    if (isDuplicate) return;
    final merged = [...current.messages, message]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    emit(current.copyWith(messages: merged));
    _markReadDebounced();
  }

  void _onPeerTyping(ConversationTypingEvent event) {
    final current = state;
    if (current is! ChatThreadLoaded) return;
    if (event.conversationId != current.conversation.id) return;
    if (event.userId != current.conversation.counterpart?.userId) return;
    emit(current.copyWith(peerTyping: true));
    _typingIndicatorTimer?.cancel();
    _typingIndicatorTimer = Timer(_typingIndicatorTtl, () {
      final latest = state;
      if (latest is ChatThreadLoaded) emit(latest.copyWith(peerTyping: false));
    });
  }

  void _onPeerRead(ConversationReadEvent event) {
    final current = state;
    if (current is! ChatThreadLoaded) return;
    if (event.conversationId != current.conversation.id) return;
    if (event.userId != current.conversation.counterpart?.userId) return;
    emit(current.copyWith(peerReadAt: event.readAt));
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
    _messageSub?.cancel();
    _typingSub?.cancel();
    _readSub?.cancel();
    _channelErrorSub?.cancel();
    _typingTimer?.cancel();
    _typingIndicatorTimer?.cancel();
    final conversationId = _subscribedConversationId;
    if (conversationId != null) {
      _realtimeService.unsubscribeFromConversation(conversationId);
    }
    super.dispose();
  }
}
