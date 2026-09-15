import 'package:bagyesrushappusernew/core/utils/json_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';

/// Payload of the `conversation.typing` realtime event. There is no
/// "stopped typing" event — the receiving side is expected to expire the
/// indicator client-side on a short timer.
class ConversationTypingEvent {
  const ConversationTypingEvent({required this.conversationId, required this.userId});

  final String conversationId;
  final String userId;

  factory ConversationTypingEvent.fromJson(DataMap json) => ConversationTypingEvent(
        conversationId: JsonUtils.asString(json['conversation_id']),
        userId: JsonUtils.asString(json['user_id']),
      );
}

/// Payload of the `conversation.read` realtime event — the other
/// participant caught up, flip this device's own sent-message ticks to
/// "read" up to [readAt].
class ConversationReadEvent {
  const ConversationReadEvent({
    required this.conversationId,
    required this.userId,
    this.readAt,
  });

  final String conversationId;
  final String userId;
  final DateTime? readAt;

  factory ConversationReadEvent.fromJson(DataMap json) => ConversationReadEvent(
        conversationId: JsonUtils.asString(json['conversation_id']),
        userId: JsonUtils.asString(json['user_id']),
        readAt: JsonUtils.asDateTime(json['read_at']),
      );
}
