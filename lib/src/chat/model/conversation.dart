import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/core/utils/json_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';

class ConversationParticipant extends Equatable {
  const ConversationParticipant({
    required this.userId,
    required this.role,
    required this.roleLabel,
    required this.name,
    required this.isMe,
    this.lastReadAt,
  });

  final String userId;
  final String role;
  final String roleLabel;
  final String name;
  final bool isMe;
  final DateTime? lastReadAt;

  factory ConversationParticipant.fromJson(DataMap json) =>
      ConversationParticipant(
        userId: JsonUtils.asString(json['user_id']),
        role: JsonUtils.asString(json['role']),
        roleLabel: JsonUtils.asString(json['role_label']),
        name: JsonUtils.asString(json['name']),
        isMe: JsonUtils.asBool(json['is_me']),
        lastReadAt: JsonUtils.asDateTime(json['last_read_at']),
      );

  @override
  List<Object?> get props => [userId, role, name, isMe, lastReadAt];
}

class ConversationOrderSummary extends Equatable {
  const ConversationOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.statusLabel,
  });

  final String id;
  final String orderNumber;
  final String status;
  final String statusLabel;

  factory ConversationOrderSummary.fromJson(DataMap json) =>
      ConversationOrderSummary(
        id: JsonUtils.asString(json['id']),
        orderNumber: JsonUtils.asString(json['order_number']),
        status: JsonUtils.asString(json['status']),
        statusLabel: JsonUtils.asString(json['status_label']),
      );

  static const _terminalStatuses = {'delivered', 'cancelled', 'canceled', 'rejected'};

  /// Coarse "order still in progress" signal, mirroring `OrderStatus.isActive`
  /// in the consumer-orders feature. Kept as a small self-contained check
  /// here rather than an inter-feature import — chat only needs this to
  /// decide whether a thread still belongs in the "active" inbox, not the
  /// full order-status lifecycle.
  bool get isActive => !_terminalStatuses.contains(status.toLowerCase());

  @override
  List<Object?> get props => [id, orderNumber, status, statusLabel];
}

class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.topic,
    required this.status,
    required this.isOpen,
    required this.participants,
    required this.unreadCount,
    required this.quickReplies,
    this.order,
    this.lastMessageAt,
    this.createdAt,
  });

  final String id;
  final String topic;
  final String status;
  final bool isOpen;
  final ConversationOrderSummary? order;
  final List<ConversationParticipant> participants;
  final int unreadCount;
  final DateTime? lastMessageAt;
  final List<String> quickReplies;
  final DateTime? createdAt;

  factory Conversation.fromJson(DataMap json) => Conversation(
    id: JsonUtils.asString(json['id']),
    topic: JsonUtils.asString(json['topic']),
    status: JsonUtils.asString(json['status']),
    isOpen: JsonUtils.asBool(json['is_open']),
    order: json['order'] is DataMap
        ? ConversationOrderSummary.fromJson(json['order'] as DataMap)
        : null,
    participants: (json['participants'] as List<dynamic>? ?? const [])
        .map((e) => ConversationParticipant.fromJson(e as DataMap))
        .toList(),
    unreadCount: JsonUtils.asInt(json['unread_count']),
    lastMessageAt: JsonUtils.asDateTime(json['last_message_at']),
    quickReplies: JsonUtils.asStringList(json['quick_replies']),
    createdAt: JsonUtils.asDateTime(json['created_at']),
  );

  /// The other side of the thread — used for the thread AppBar title/avatar
  /// and the inbox row. Falls back to `null` for a group thread with no
  /// single counterpart (none of the documented topics are group chats
  /// today, but this keeps callers null-safe if that ever changes).
  ConversationParticipant? get counterpart {
    for (final p in participants) {
      if (!p.isMe) return p;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    topic,
    status,
    isOpen,
    order,
    participants,
    unreadCount,
    lastMessageAt,
    quickReplies,
  ];
}
