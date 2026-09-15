import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/services/realtime_config.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';

/// Fetches the realtime (Reverb/Pusher-protocol) connection config.
///
/// Mirrors `ChatRepository`'s plain `Future` + throw style rather than the
/// `ResultFuture`/`Either` convention `AuthRepository` uses — this feeds
/// `RealtimeService`'s internal control flow, not a `fold()`-driven UI state.
class RealtimeRepository {
  RealtimeRepository({required Dio client}) : _client = client;

  final Dio _client;

  Future<RealtimeConfig> getConfig() async {
    appLogger.d('RealtimeRepository.getConfig → initiated');
    try {
      final response = await _client.get(ApiEndpoints.realtimeConfig);
      if (response.statusCode == 200) {
        final config = RealtimeConfig.fromJson(_dataMap(response.data));
        appLogger.i('RealtimeRepository.getConfig → loaded (driver=${config.driver})');
        return config;
      }
      throw Exception(
        _errorMessage(response.data) ?? 'Failed to load realtime config (${response.statusCode}).',
      );
    } on DioException catch (e) {
      appLogger.e('RealtimeRepository.getConfig → DioException', error: e);
      throw Exception(_friendlyMessage(e));
    }
  }

  // ─── Private helpers ─── (mirrors ChatRepository verbatim)

  String _friendlyMessage(DioException e) {
    final message = _errorMessage(e.response?.data);
    if (message != null) return message;
    return e.message ?? 'Something went wrong. Please try again.';
  }

  String? _errorMessage(dynamic data) {
    if (data is! DataMap) return null;
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      return first is List && first.isNotEmpty
          ? first.first.toString()
          : first.toString();
    }
    return data['message']?.toString();
  }

  DataMap _dataMap(dynamic raw) {
    if (raw is DataMap) {
      final data = raw['data'];
      if (data is DataMap) return data;
    }
    return const {};
  }
}
