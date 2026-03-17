import 'package:flutter/foundation.dart';
import 'consumer_chat_message.dart';

@immutable
class ConsumerConversation {
  final String id;
  final String participantName;
  final String participantInitials;
  final String? participantRole; // e.g. "Restaurant", "Delivery Rider", "Support"
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final List<ConsumerChatMessage> messages;

  const ConsumerConversation({
    required this.id,
    required this.participantName,
    required this.participantInitials,
    this.participantRole,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.messages = const [],
  });

  ConsumerConversation copyWith({
    int? unreadCount,
    List<ConsumerChatMessage>? messages,
    String? lastMessage,
    DateTime? lastMessageAt,
  }) =>
      ConsumerConversation(
        id: id,
        participantName: participantName,
        participantInitials: participantInitials,
        participantRole: participantRole,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        unreadCount: unreadCount ?? this.unreadCount,
        messages: messages ?? this.messages,
      );
}
