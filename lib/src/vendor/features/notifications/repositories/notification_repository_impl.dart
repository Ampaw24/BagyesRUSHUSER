import 'package:dio/dio.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../models/vendor_notification.dart';
import '../models/vendor_conversation.dart';
import '../models/vendor_chat_message.dart';
import 'i_notification_repository.dart';

/// Notification-list methods are real, Dio-backed calls. Chat/conversation
/// methods stay on local dummy data — the backend has no chat endpoints.
class NotificationRepositoryImpl implements INotificationRepository {
  NotificationRepositoryImpl({required Dio client}) : _client = client;

  final Dio _client;
  static final _now = DateTime.now();

  @override
  Future<List<VendorNotification>> getNotifications() async {
    final response = await _client.get(ApiEndpoints.notifications);
    final list = _dataList(response);
    return list
        .map((e) => VendorNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<VendorNotification>> markAsRead(
    List<VendorNotification> current,
    String notificationId,
  ) async {
    await _client.patch(ApiEndpoints.notificationRead(notificationId));
    return current
        .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
        .toList();
  }

  @override
  Future<List<VendorNotification>> markAllAsRead(
    List<VendorNotification> current,
  ) async {
    await _client.patch(ApiEndpoints.notificationsReadAll);
    return current.map((n) => n.copyWith(isRead: true)).toList();
  }

  @override
  Future<void> deleteNotification(String id) async {
    await _client.delete(ApiEndpoints.notificationById(id));
  }

  @override
  Future<int> unreadCount() async {
    final response = await _client.get(ApiEndpoints.notificationsUnreadCount);
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      final count = data is Map<String, dynamic> ? data['count'] : body['count'];
      return (count as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  List<dynamic> _dataList(Response response) {
    final body = response.data;
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      final d = body['data'];
      if (d is List) return d;
      if (d is Map<String, dynamic>) {
        final inner = d['data'];
        if (inner is List) return inner;
      }
    }
    return const [];
  }

  // ─── Chat/conversations — no backend endpoints exist, stays mocked ────────

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
