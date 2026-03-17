import '../models/consumer_notification.dart';
import '../models/consumer_conversation.dart';
import '../models/consumer_chat_message.dart';

abstract interface class IConsumerNotificationRepository {
  List<ConsumerNotification> getNotifications();

  List<ConsumerNotification> markAsRead(
    List<ConsumerNotification> current,
    String notificationId,
  );

  List<ConsumerNotification> markAllAsRead(List<ConsumerNotification> current);

  List<ConsumerConversation> getConversations();

  List<ConsumerChatMessage> getMessages(String conversationId);

  ConsumerConversation sendMessage(ConsumerConversation conversation, String text);

  ConsumerConversation markConversationRead(ConsumerConversation conversation);
}
