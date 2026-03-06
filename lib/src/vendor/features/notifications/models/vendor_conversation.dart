import 'package:flutter/foundation.dart';
import 'vendor_chat_message.dart';

@immutable
class VendorConversation {
  final String id;
  final String participantName;
  final String? participantAvatarUrl;
  final String participantInitials;
  final String? participantRole;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final List<VendorChatMessage> messages;

  const VendorConversation({
    required this.id,
    required this.participantName,
    this.participantAvatarUrl,
    required this.participantInitials,
    this.participantRole,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.messages = const [],
  });

  VendorConversation copyWith({
    int? unreadCount,
    List<VendorChatMessage>? messages,
    String? lastMessage,
    DateTime? lastMessageAt,
  }) =>
      VendorConversation(
        id: id,
        participantName: participantName,
        participantAvatarUrl: participantAvatarUrl,
        participantInitials: participantInitials,
        participantRole: participantRole,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        unreadCount: unreadCount ?? this.unreadCount,
        messages: messages ?? this.messages,
      );
}
