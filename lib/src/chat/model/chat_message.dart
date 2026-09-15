import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/core/utils/json_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';

/// Client-side send lifecycle for a message. The API itself has no such
/// field — this exists purely to drive the optimistic bubble UI while
/// [ChatMessage.clientUuid] round-trips through [ChatRepository.sendMessage].
enum MessageDeliveryStatus { sending, sent, failed }

class ChatMessageSender extends Equatable {
  const ChatMessageSender({required this.id, required this.name});

  final String id;
  final String name;

  factory ChatMessageSender.fromJson(DataMap json) => ChatMessageSender(
    id: JsonUtils.asString(json['id']),
    name: JsonUtils.asString(json['name']),
  );

  @override
  List<Object?> get props => [id, name];
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.type,
    required this.body,
    required this.sender,
    required this.isMine,
    required this.createdAt,
    this.clientUuid,
    this.deliveryStatus = MessageDeliveryStatus.sent,
  });

  final String id;
  final String conversationId;
  final String type;
  final String body;
  final ChatMessageSender sender;
  final bool isMine;
  final String? clientUuid;
  final DateTime createdAt;
  final MessageDeliveryStatus deliveryStatus;

  factory ChatMessage.fromJson(DataMap json) => ChatMessage(
    id: JsonUtils.asString(json['id']),
    conversationId: JsonUtils.asString(json['conversation_id']),
    type: JsonUtils.asString(json['type'], 'text'),
    body: JsonUtils.asString(json['body']),
    sender: ChatMessageSender.fromJson(json['sender'] as DataMap? ?? const {}),
    isMine: JsonUtils.asBool(json['is_mine']),
    clientUuid: JsonUtils.asStringOrNull(json['client_uuid']),
    createdAt: JsonUtils.asDateTime(json['created_at']) ?? DateTime.now(),
  );

  /// A not-yet-confirmed bubble shown immediately on send, before the server
  /// echoes the real row back. Reconciled by [clientUuid] — see
  /// `ChatThreadViewModel.sendMessage`.
  factory ChatMessage.optimistic({
    required String conversationId,
    required String body,
    required String clientUuid,
    required String senderName,
  }) => ChatMessage(
    id: 'local-$clientUuid',
    conversationId: conversationId,
    type: 'text',
    body: body,
    sender: ChatMessageSender(id: '', name: senderName),
    isMine: true,
    clientUuid: clientUuid,
    createdAt: DateTime.now(),
    deliveryStatus: MessageDeliveryStatus.sending,
  );

  ChatMessage copyWith({MessageDeliveryStatus? deliveryStatus}) => ChatMessage(
    id: id,
    conversationId: conversationId,
    type: type,
    body: body,
    sender: sender,
    isMine: isMine,
    createdAt: createdAt,
    clientUuid: clientUuid,
    deliveryStatus: deliveryStatus ?? this.deliveryStatus,
  );

  @override
  List<Object?> get props => [
    id,
    conversationId,
    body,
    isMine,
    clientUuid,
    createdAt,
    deliveryStatus,
  ];
}
