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
}
