import 'package:bagyesrushappusernew/core/utils/json_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';

/// Parses `GET /realtime/config` — connection details for the realtime
/// (Reverb/Pusher-protocol) layer. Fetched once per session; host/port/key
/// are never hardcoded or `.env`-based per the API contract.
class RealtimeConfig {
  const RealtimeConfig({
    required this.driver,
    required this.key,
    required this.host,
    required this.port,
    required this.useTls,
    required this.authEndpoint,
    required this.channelTemplates,
  });

  final String driver;
  final String key;
  final String host;
  final int port;
  final bool useTls;
  final String authEndpoint;

  /// e.g. `{"order": "private-order.{order_id}", "conversation": "private-conversation.{conversation_id}"}`.
  final Map<String, String> channelTemplates;

  static const adminRidersChannel = 'private-admin.riders';

  factory RealtimeConfig.fromJson(DataMap json) {
    final channels = json['channels'];
    return RealtimeConfig(
      driver: JsonUtils.asString(json['driver']),
      key: JsonUtils.asString(json['key']),
      host: JsonUtils.asString(json['host']),
      port: JsonUtils.asInt(json['port'], 443),
      useTls: JsonUtils.asBool(json['use_tls'], true),
      authEndpoint: JsonUtils.asString(json['auth_endpoint']),
      channelTemplates: channels is DataMap
          ? channels.map((key, value) => MapEntry(key, JsonUtils.asString(value)))
          : const {},
    );
  }

  String orderChannel(String orderId) =>
      (channelTemplates['order'] ?? 'private-order.{order_id}')
          .replaceAll('{order_id}', orderId);

  String conversationChannel(String conversationId) =>
      (channelTemplates['conversation'] ?? 'private-conversation.{conversation_id}')
          .replaceAll('{conversation_id}', conversationId);

  String riderChannel(String userId) => 'private-rider.$userId';
}
