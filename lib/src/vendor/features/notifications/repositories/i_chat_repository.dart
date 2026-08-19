import '../models/vendor_conversation.dart';
import '../models/vendor_chat_message.dart';

/// Chat/conversation contract only — the backend has no chat endpoints, so
/// every implementation of this stays on local mock data. Real notification
/// list/read/delete/unread-count now live in `NotificationViewmodel`
/// (`lib/src/notification/`), not here.
abstract interface class IChatRepository {
  /// Returns all conversations.
  List<VendorConversation> getConversations();

  /// Returns messages for a specific conversation.
  List<VendorChatMessage> getMessages(String conversationId);

  /// Adds a new message to a conversation and returns updated conversation.
  VendorConversation sendMessage(
    VendorConversation conversation,
    String text,
  );

  /// Marks all messages in a conversation as read.
  VendorConversation markConversationRead(VendorConversation conversation);
}
