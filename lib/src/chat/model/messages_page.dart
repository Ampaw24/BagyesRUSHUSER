import 'package:bagyesrushappusernew/core/utils/json_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/chat/model/chat_message.dart';

/// One cursor-paginated page of `GET conversations/:id/messages`.
///
/// [items] arrive **newest-first**, exactly as the API returns them — callers
/// that render a bottom-anchored thread are responsible for reversing.
class MessagesPage {
  const MessagesPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
    this.previousCursor,
  });

  final List<ChatMessage> items;
  final String? nextCursor;
  final String? previousCursor;
  final bool hasMore;

  factory MessagesPage.fromJson(DataMap json) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    final cursor = json['cursor'] as DataMap? ?? const {};
    return MessagesPage(
      items: itemsJson
          .map((e) => ChatMessage.fromJson(e as DataMap))
          .toList(),
      nextCursor: JsonUtils.asStringOrNull(cursor['next']),
      previousCursor: JsonUtils.asStringOrNull(cursor['previous']),
      hasMore: JsonUtils.asBool(cursor['has_more']),
    );
  }
}
