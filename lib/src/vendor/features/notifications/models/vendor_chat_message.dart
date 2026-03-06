import 'package:flutter/foundation.dart';

enum MessageStatus { sent, delivered, read }

@immutable
class VendorChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final MessageStatus status;
  final bool isFromVendor;

  const VendorChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.status = MessageStatus.sent,
    required this.isFromVendor,
  });
}
