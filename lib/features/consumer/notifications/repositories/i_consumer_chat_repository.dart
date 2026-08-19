import '../models/consumer_conversation.dart';
import '../models/consumer_chat_message.dart';

/// Chat/conversation contract only — the backend has no chat endpoints, so
/// every implementation of this stays on local mock data. Real notification
/// list/read/delete/unread-count now live in `NotificationViewmodel`
/// (`lib/src/notification/`), not here.
abstract interface class IConsumerChatRepository {
  List<ConsumerConversation> getConversations();

  List<ConsumerChatMessage> getMessages(String conversationId);

  ConsumerConversation sendMessage(ConsumerConversation conversation, String text);

  ConsumerConversation markConversationRead(ConsumerConversation conversation);
}
