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

  /// Maps the backend's notification payload. Field names are inferred from
  /// the endpoint path alone — verify against a real `GET notifications`
  /// response and adjust if they don't match.
  factory VendorNotification.fromJson(Map<String, dynamic> json) {
    final senderName =
        json['title'] as String? ?? json['sender_name'] as String? ?? 'Notification';
    return VendorNotification(
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

  static VendorNotificationType _typeFromString(String? value) {
    switch (value) {
      case 'new_order':
        return VendorNotificationType.newOrder;
      case 'order_update':
        return VendorNotificationType.orderUpdate;
      case 'payment':
        return VendorNotificationType.payment;
      case 'promo':
        return VendorNotificationType.promo;
      default:
        return VendorNotificationType.system;
    }
  }
}
