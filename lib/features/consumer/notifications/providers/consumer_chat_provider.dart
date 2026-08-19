import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/consumer_conversation.dart';
import '../repositories/i_consumer_chat_repository.dart';
import 'consumer_chat_repository_provider.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class ConsumerChatState {
  final List<ConsumerConversation> conversations;
  final bool isLoading;

  const ConsumerChatState({
    this.conversations = const [],
    this.isLoading = false,
  });

  int get totalUnread =>
      conversations.fold(0, (sum, c) => sum + c.unreadCount);

  ConsumerChatState copyWith({
    List<ConsumerConversation>? conversations,
    bool? isLoading,
  }) =>
      ConsumerChatState(
        conversations: conversations ?? this.conversations,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class ConsumerChatNotifier extends StateNotifier<ConsumerChatState> {
  final IConsumerChatRepository _repository;

  ConsumerChatNotifier(this._repository)
      : super(const ConsumerChatState(isLoading: true)) {
    _load();
  }

  void _load() {
    final items = _repository.getConversations();
    state = state.copyWith(conversations: items, isLoading: false);
  }

  void sendMessage(String conversationId, String text) {
    if (text.trim().isEmpty) return;
    final idx =
        state.conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;
    final updated =
        _repository.sendMessage(state.conversations[idx], text);
    final list = [...state.conversations];
    list[idx] = updated;
    state = state.copyWith(conversations: list);
  }

  void markConversationRead(String conversationId) {
    final idx =
        state.conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;
    final updated =
        _repository.markConversationRead(state.conversations[idx]);
    final list = [...state.conversations];
    list[idx] = updated;
    state = state.copyWith(conversations: list);
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final consumerChatProvider =
    StateNotifierProvider<ConsumerChatNotifier, ConsumerChatState>((ref) {
  final repo = ref.read(consumerChatRepositoryProvider);
  return ConsumerChatNotifier(repo);
});
