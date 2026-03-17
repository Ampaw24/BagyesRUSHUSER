import 'package:flutter/foundation.dart';

enum ConsumerMessageStatus { sent, delivered, read }

@immutable
class ConsumerChatMessage {
  final String id;
  final String text;
  final DateTime sentAt;
  final bool isFromMe; // true = sent by the consumer
  final ConsumerMessageStatus status;

  const ConsumerChatMessage({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.isFromMe,
    this.status = ConsumerMessageStatus.sent,
  });
}
