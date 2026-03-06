import 'package:flutter/foundation.dart';

enum VendorNotificationType { newOrder, orderUpdate, payment, promo, system }

@immutable
class VendorNotification {
  final String id;
  final String senderName;
  final String? senderAvatarUrl;
  final String senderInitials;
  final String body;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final bool isRead;
  final VendorNotificationType type;

  const VendorNotification({
    required this.id,
    required this.senderName,
    this.senderAvatarUrl,
    required this.senderInitials,
    required this.body,
    this.thumbnailUrl,
    required this.createdAt,
    this.isRead = false,
    required this.type,
  });

  VendorNotification copyWith({bool? isRead}) => VendorNotification(
        id: id,
        senderName: senderName,
        senderAvatarUrl: senderAvatarUrl,
        senderInitials: senderInitials,
        body: body,
        thumbnailUrl: thumbnailUrl,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        type: type,
      );
}
