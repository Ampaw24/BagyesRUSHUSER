import 'package:flutter/foundation.dart';

enum ConsumerNotificationType { orderPlaced, orderUpdate, delivery, promo, system }

@immutable
class ConsumerNotification {
  final String id;
  final String senderName;
  final String senderInitials;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final ConsumerNotificationType type;

  const ConsumerNotification({
    required this.id,
    required this.senderName,
    required this.senderInitials,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    required this.type,
  });

  ConsumerNotification copyWith({bool? isRead}) => ConsumerNotification(
        id: id,
        senderName: senderName,
        senderInitials: senderInitials,
        body: body,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        type: type,
      );

  /// Maps the backend's notification payload. Field names are inferred from
  /// the endpoint path alone — verify against a real `GET notifications`
  /// response and adjust if they don't match.
  factory ConsumerNotification.fromJson(Map<String, dynamic> json) {
    final senderName =
        json['title'] as String? ?? json['sender_name'] as String? ?? 'Notification';
    return ConsumerNotification(
      id: json['id'].toString(),
      senderName: senderName,
      senderInitials: senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      isRead: json['is_read'] as bool? ?? json['read_at'] != null,
      type: _typeFromString(json['type'] as String?),
    );
  }

  static ConsumerNotificationType _typeFromString(String? value) {
    switch (value) {
      case 'order_placed':
        return ConsumerNotificationType.orderPlaced;
      case 'order_update':
        return ConsumerNotificationType.orderUpdate;
      case 'delivery':
        return ConsumerNotificationType.delivery;
      case 'promo':
        return ConsumerNotificationType.promo;
      default:
        return ConsumerNotificationType.system;
    }
  }
}
