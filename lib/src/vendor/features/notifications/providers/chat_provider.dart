import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vendor_conversation.dart';
import '../repositories/i_notification_repository.dart';
import 'notification_provider.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class ChatState {
  final List<VendorConversation> conversations;
  final bool isLoading;

  const ChatState({this.conversations = const [], this.isLoading = false});

  int get totalUnread =>
      conversations.fold(0, (sum, c) => sum + c.unreadCount);

  ChatState copyWith({
    List<VendorConversation>? conversations,
    bool? isLoading,
  }) =>
      ChatState(
        conversations: conversations ?? this.conversations,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<ChatState> {
  final INotificationRepository _repository;

  ChatNotifier(this._repository) : super(const ChatState(isLoading: true)) {
    _load();
  }

  void _load() {
    final items = _repository.getConversations();
    state = state.copyWith(conversations: items, isLoading: false);
  }

  void sendMessage(String conversationId, String text) {
    if (text.trim().isEmpty) return;
    final idx = state.conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;
    final updated = _repository.sendMessage(state.conversations[idx], text);
    final list = [...state.conversations];
    list[idx] = updated;
    state = state.copyWith(conversations: list);
  }

  void markConversationRead(String conversationId) {
    final idx = state.conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;
    final updated =
        _repository.markConversationRead(state.conversations[idx]);
    final list = [...state.conversations];
    list[idx] = updated;
    state = state.copyWith(conversations: list);
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repo = ref.read(notificationRepositoryProvider);
  return ChatNotifier(repo);
});
