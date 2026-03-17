import '../models/consumer_notification.dart';
import '../models/consumer_conversation.dart';
import '../models/consumer_chat_message.dart';
import 'i_consumer_notification_repository.dart';

/// Concrete implementation using local dummy data.
/// Swap out for an API-backed version without touching any UI code.
class ConsumerNotificationRepositoryImpl
    implements IConsumerNotificationRepository {
  static final _now = DateTime.now();

  @override
  List<ConsumerNotification> getNotifications() => [
        ConsumerNotification(
          id: 'cn1',
          senderName: 'BagyesRUSH',
          senderInitials: 'BR',
          body: 'Your order #5031 has been placed successfully.',
          createdAt: _now.subtract(const Duration(minutes: 3)),
          isRead: false,
          type: ConsumerNotificationType.orderPlaced,
        ),
        ConsumerNotification(
          id: 'cn2',
          senderName: 'Green Garden',
          senderInitials: 'GG',
          body: 'Your food is being prepared. Estimated time: 20 mins.',
          createdAt: _now.subtract(const Duration(minutes: 15)),
          isRead: false,
          type: ConsumerNotificationType.orderUpdate,
        ),
        ConsumerNotification(
          id: 'cn3',
          senderName: 'Kofi (Rider)',
          senderInitials: 'KR',
          body: 'Your order is out for delivery. Track your rider live.',
          createdAt: _now.subtract(const Duration(minutes: 40)),
          isRead: false,
          type: ConsumerNotificationType.delivery,
        ),
        ConsumerNotification(
          id: 'cn4',
          senderName: 'BagyesRUSH',
          senderInitials: 'BR',
          body: '🎉 20% off your next order! Use code RUSH20 at checkout.',
          createdAt: _now.subtract(const Duration(hours: 5)),
          isRead: true,
          type: ConsumerNotificationType.promo,
        ),
        ConsumerNotification(
          id: 'cn5',
          senderName: 'Green Garden',
          senderInitials: 'GG',
          body: 'Order #5028 has been delivered. Enjoy your meal!',
          createdAt: _now.subtract(const Duration(days: 1)),
          isRead: true,
          type: ConsumerNotificationType.orderUpdate,
        ),
        ConsumerNotification(
          id: 'cn6',
          senderName: 'BagyesRUSH',
          senderInitials: 'BR',
          body: 'App updated: faster checkout and live order tracking.',
          createdAt: _now.subtract(const Duration(days: 2)),
          isRead: true,
          type: ConsumerNotificationType.system,
        ),
      ];

  @override
  List<ConsumerNotification> markAsRead(
    List<ConsumerNotification> current,
    String notificationId,
  ) =>
      current
          .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
          .toList();

  @override
  List<ConsumerNotification> markAllAsRead(
          List<ConsumerNotification> current) =>
      current.map((n) => n.copyWith(isRead: true)).toList();

  @override
  List<ConsumerConversation> getConversations() => [
        ConsumerConversation(
          id: 'cc1',
          participantName: 'Green Garden',
          participantInitials: 'GG',
          participantRole: 'Restaurant',
          lastMessage: 'Your food is ready and on the way!',
          lastMessageAt: _now.subtract(const Duration(minutes: 10)),
          unreadCount: 2,
          messages: getMessages('cc1'),
        ),
        ConsumerConversation(
          id: 'cc2',
          participantName: 'Kofi Mensah',
          participantInitials: 'KM',
          participantRole: 'Delivery Rider',
          lastMessage: 'I\'m 5 minutes away from your location.',
          lastMessageAt: _now.subtract(const Duration(minutes: 25)),
          unreadCount: 1,
          messages: getMessages('cc2'),
        ),
        ConsumerConversation(
          id: 'cc3',
          participantName: 'BagyesRUSH Support',
          participantInitials: 'BS',
          participantRole: 'Support',
          lastMessage: 'Your refund has been processed successfully.',
          lastMessageAt: _now.subtract(const Duration(hours: 3)),
          unreadCount: 0,
          messages: getMessages('cc3'),
        ),
        ConsumerConversation(
          id: 'cc4',
          participantName: 'Spice Palace',
          participantInitials: 'SP',
          participantRole: 'Restaurant',
          lastMessage: 'Thank you for your order!',
          lastMessageAt: _now.subtract(const Duration(hours: 6)),
          unreadCount: 0,
          messages: getMessages('cc4'),
        ),
      ];

  @override
  List<ConsumerChatMessage> getMessages(String conversationId) {
    final base = _now;
    return [
      ConsumerChatMessage(
        id: '${conversationId}_m1',
        text: 'Hi, I just placed an order. When will it be ready?',
        sentAt: base.subtract(const Duration(minutes: 30)),
        isFromMe: true,
        status: ConsumerMessageStatus.read,
      ),
      ConsumerChatMessage(
        id: '${conversationId}_m2',
        text: 'Hello! Your order is being prepared right now. Around 20 minutes.',
        sentAt: base.subtract(const Duration(minutes: 28)),
        isFromMe: false,
        status: ConsumerMessageStatus.read,
      ),
      ConsumerChatMessage(
        id: '${conversationId}_m3',
        text: 'Great, can I get extra sauce on the side?',
        sentAt: base.subtract(const Duration(minutes: 25)),
        isFromMe: true,
        status: ConsumerMessageStatus.read,
      ),
      ConsumerChatMessage(
        id: '${conversationId}_m4',
        text: 'Of course! I\'ll add extra sauce for you.',
        sentAt: base.subtract(const Duration(minutes: 22)),
        isFromMe: false,
        status: ConsumerMessageStatus.delivered,
      ),
      ConsumerChatMessage(
        id: '${conversationId}_m5',
        text: 'Your food is ready and on the way!',
        sentAt: base.subtract(const Duration(minutes: 10)),
        isFromMe: false,
        status: ConsumerMessageStatus.delivered,
      ),
    ];
  }

  @override
  ConsumerConversation sendMessage(
      ConsumerConversation conversation, String text) {
    final newMsg = ConsumerChatMessage(
      id: '${conversation.id}_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      sentAt: DateTime.now(),
      isFromMe: true,
      status: ConsumerMessageStatus.sent,
    );
    return conversation.copyWith(
      messages: [...conversation.messages, newMsg],
      lastMessage: text,
      lastMessageAt: newMsg.sentAt,
    );
  }

  @override
  ConsumerConversation markConversationRead(ConsumerConversation conversation) =>
      conversation.copyWith(unreadCount: 0);
}
