import '../models/consumer_conversation.dart';
import '../models/consumer_chat_message.dart';
import 'i_consumer_chat_repository.dart';

/// Chat/conversations — no backend endpoints exist, stays mocked.
class ConsumerChatRepositoryImpl implements IConsumerChatRepository {
  static final _now = DateTime.now();

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
