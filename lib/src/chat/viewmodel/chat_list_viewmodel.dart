import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/chat/model/conversation.dart';
import 'package:bagyesrushappusernew/src/chat/repository/chat_repository.dart';

/// Sealed states for the conversation inbox.
sealed class ChatListState {
  const ChatListState();
}

class ChatListLoading extends ChatListState {
  const ChatListLoading();
}

class ChatListLoaded extends ChatListState {
  const ChatListLoaded({required this.conversations});
  final List<Conversation> conversations;
}

class ChatListError extends ChatListState {
  const ChatListError({required this.message});
  final String message;
}

/// Screen-scoped — one fresh instance per `ChatListView` visit, owned and
/// disposed directly by its State (mirrors `MyReportsViewModel`). Being
/// re-created on every visit means a message sent from a thread and popped
/// back to shows up immediately without a manual cache-invalidation call.
class ChatListViewModel extends ViewModel<ChatListState> {
  ChatListViewModel({required ChatRepository repository})
    : _repository = repository,
      super(const ChatListLoading()) {
    _load();
  }

  final ChatRepository _repository;

  Future<void> _load() async {
    try {
      final all = await _repository.getConversations();
      // Unlike a general-purpose messaging app, this inbox is not a
      // permanent archive — it's scoped to orders still in progress. A
      // thread with no embedded order (shouldn't happen per the API, but
      // handled defensively) is kept rather than silently dropped.
      final active = all.where((c) => c.order?.isActive ?? true).toList()
        ..sort((a, b) {
          final aTime = a.lastMessageAt ?? a.createdAt ?? DateTime(0);
          final bTime = b.lastMessageAt ?? b.createdAt ?? DateTime(0);
          return bTime.compareTo(aTime);
        });
      emit(ChatListLoaded(conversations: active));
    } catch (e) {
      emit(ChatListError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refresh() => _load();
}
