import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/consumer_notification.dart';
import '../models/consumer_conversation.dart';
import '../models/consumer_chat_message.dart';
import 'i_consumer_notification_repository.dart';

/// Notification-list methods are real, Dio-backed calls. Chat/conversation
/// methods stay on local dummy data — the backend has no chat endpoints.
class ConsumerNotificationRepositoryImpl
    implements IConsumerNotificationRepository {
  ConsumerNotificationRepositoryImpl({required Dio client}) : _client = client;

  final Dio _client;
  static final _now = DateTime.now();

  @override
  Future<List<ConsumerNotification>> getNotifications() async {
    final response = await _client.get(ApiEndpoints.notifications);
    final list = _dataList(response);
    return list
        .map((e) => ConsumerNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ConsumerNotification>> markAsRead(
    List<ConsumerNotification> current,
    String notificationId,
  ) async {
    await _client.patch(ApiEndpoints.notificationRead(notificationId));
    return current
        .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
        .toList();
  }

  @override
  Future<List<ConsumerNotification>> markAllAsRead(
    List<ConsumerNotification> current,
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
