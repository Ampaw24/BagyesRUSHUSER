import '../models/vendor_conversation.dart';
import '../models/vendor_chat_message.dart';
import 'i_chat_repository.dart';

/// Chat/conversations — no backend endpoints exist, stays mocked.
class ChatRepositoryImpl implements IChatRepository {
  static final _now = DateTime.now();

  @override
  List<VendorConversation> getConversations() => [
        VendorConversation(
          id: 'c1',
          participantName: 'Royal Pervej',
          participantInitials: 'RP',
          participantRole: 'Supplier',
          lastMessage: 'Thanks, the delivery is on the way!',
          lastMessageAt: _now.subtract(const Duration(minutes: 2)),
          unreadCount: 0,
          messages: getMessages('c1'),
        ),
        VendorConversation(
          id: 'c2',
          participantName: 'Cameron Williamson',
          participantInitials: 'CW',
          participantRole: 'Customer',
          lastMessage: 'Ok, you can hurry up little bit',
          lastMessageAt: _now.subtract(const Duration(minutes: 15)),
          unreadCount: 2,
          messages: getMessages('c2'),
        ),
        VendorConversation(
          id: 'c3',
          participantName: 'Ralph Edwards',
          participantInitials: 'RE',
          participantRole: 'Delivery Rider',
          lastMessage: 'Private Message',
          lastMessageAt: _now.subtract(const Duration(hours: 1)),
          unreadCount: 0,
          messages: getMessages('c3'),
        ),
        VendorConversation(
          id: 'c4',
          participantName: 'Cody Fisher',
          participantInitials: 'CF',
          participantRole: 'Customer',
          lastMessage: 'Is my order ready?',
          lastMessageAt: _now.subtract(const Duration(hours: 2)),
          unreadCount: 1,
          messages: getMessages('c4'),
        ),
        VendorConversation(
          id: 'c5',
          participantName: 'Eleanor Pena',
          participantInitials: 'EP',
          participantRole: 'Customer',
          lastMessage: 'Thanks for the fast delivery, loved the food!',
          lastMessageAt: _now.subtract(const Duration(hours: 4)),
          unreadCount: 0,
          messages: getMessages('c5'),
        ),
      ];

  @override
  List<VendorChatMessage> getMessages(String conversationId) {
    final base = _now;
    return [
      VendorChatMessage(
        id: '${conversationId}_m1',
        senderId: 'customer',
        text: 'Hi, I just placed an order. When will it be ready?',
        sentAt: base.subtract(const Duration(minutes: 30)),
        isFromVendor: false,
        status: MessageStatus.read,
      ),
      VendorChatMessage(
        id: '${conversationId}_m2',
        senderId: 'vendor',
        text: 'Hello! Your order is being prepared right now. Around 20 minutes.',
        sentAt: base.subtract(const Duration(minutes: 28)),
        isFromVendor: true,
        status: MessageStatus.read,
      ),
      VendorChatMessage(
        id: '${conversationId}_m3',
        senderId: 'customer',
        text: 'Great, thank you! Can I get extra sauce on the side?',
        sentAt: base.subtract(const Duration(minutes: 25)),
        isFromVendor: false,
        status: MessageStatus.read,
      ),
      VendorChatMessage(
        id: '${conversationId}_m4',
        senderId: 'vendor',
        text: 'Of course! I\'ll add extra sauce for you.',
        sentAt: base.subtract(const Duration(minutes: 22)),
        isFromVendor: true,
        status: MessageStatus.delivered,
      ),
      VendorChatMessage(
        id: '${conversationId}_m5',
        senderId: 'customer',
        text: 'Thanks for the fast delivery, loved the food!',
        sentAt: base.subtract(const Duration(minutes: 5)),
        isFromVendor: false,
        status: MessageStatus.delivered,
      ),
    ];
  }

  @override
  VendorConversation sendMessage(VendorConversation conversation, String text) {
    final newMsg = VendorChatMessage(
      id: '${conversation.id}_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'vendor',
      text: text,
      sentAt: DateTime.now(),
      isFromVendor: true,
      status: MessageStatus.sent,
    );
    return conversation.copyWith(
      messages: [...conversation.messages, newMsg],
      lastMessage: text,
      lastMessageAt: newMsg.sentAt,
    );
  }

  @override
  VendorConversation markConversationRead(VendorConversation conversation) =>
      conversation.copyWith(unreadCount: 0);
}
