import '../models/consumer_notification.dart';
import '../models/consumer_conversation.dart';
import '../models/consumer_chat_message.dart';

abstract interface class IConsumerNotificationRepository {
  Future<List<ConsumerNotification>> getNotifications();

  Future<List<ConsumerNotification>> markAsRead(
    List<ConsumerNotification> current,
    String notificationId,
  );

  Future<List<ConsumerNotification>> markAllAsRead(
    List<ConsumerNotification> current,
  );

  Future<void> deleteNotification(String id);

  Future<int> unreadCount();

  List<ConsumerConversation> getConversations();

  List<ConsumerChatMessage> getMessages(String conversationId);

  ConsumerConversation sendMessage(ConsumerConversation conversation, String text);

  ConsumerConversation markConversationRead(ConsumerConversation conversation);
}
