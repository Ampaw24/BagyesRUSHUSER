import '../models/vendor_notification.dart';
import '../models/vendor_conversation.dart';
import '../models/vendor_chat_message.dart';

/// Defines the contract for notification and messaging operations.
/// Depends on abstractions, not concretions (Dependency Inversion).
abstract interface class INotificationRepository {
  /// Returns all notifications for the vendor.
  List<VendorNotification> getNotifications();

  /// Marks a single notification as read.
  List<VendorNotification> markAsRead(
    List<VendorNotification> current,
    String notificationId,
  );

  /// Marks all notifications as read.
  List<VendorNotification> markAllAsRead(List<VendorNotification> current);

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
