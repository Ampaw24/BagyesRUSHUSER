import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/notification/model/notification.model.dart';

class NotificationRepository {
  const NotificationRepository({required Dio client}) : _client = client;

  final Dio _client;

  // ─── List ──────────────────────────────────────────────────────────────────

  ResultFuture<List<NotificationModel>> getNotifications({
    bool? unread,
    int? perPage,
  }) async {
    appLogger.d(
        'NotificationRepository.getNotifications → unread=$unread, perPage=$perPage');
    try {
      final queryParams = <String, dynamic>{
        'unread': ?unread,
        'per_page': ?perPage,
      };
      final response = await _client.get(
        ApiEndpoints.notifications,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if ([200, 201].contains(response.statusCode)) {
        final notifications = _dataList(response)
            .map((e) => NotificationModel.fromJson(e as DataMap))
            .toList();
        appLogger.i(
            'NotificationRepository.getNotifications → loaded ${notifications.length} notifications');
        return Right(notifications);
      }

      appLogger.w(
          'NotificationRepository.getNotifications → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('NotificationRepository.getNotifications → DioException',
          error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'NotificationRepository',
          methodName: 'getNotifications');
    }
  }

  // ─── Unread Count ──────────────────────────────────────────────────────────

  ResultFuture<int> getUnreadCount() async {
    appLogger.d('NotificationRepository.getUnreadCount → initiated');
    try {
      final response = await _client.get(ApiEndpoints.notificationsUnreadCount);

      if ([200, 201].contains(response.statusCode)) {
        final payload = (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;
        // Confirmed live shape: {data: {unread: N}}
        final count = (payload['unread'] ?? payload['count'] ?? payload['unread_count'])
            as num?;
        appLogger.i(
            'NotificationRepository.getUnreadCount → count=${count ?? 0}');
        return Right(count?.toInt() ?? 0);
      }

      appLogger.w(
          'NotificationRepository.getUnreadCount → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('NotificationRepository.getUnreadCount → DioException',
          error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'NotificationRepository',
          methodName: 'getUnreadCount');
    }
  }

  // ─── Mark as read ──────────────────────────────────────────────────────────

  ResultFuture<NotificationModel> markAsRead(String id) async {
    appLogger.d('NotificationRepository.markAsRead → id=$id');
    try {
      final response = await _client.patch(ApiEndpoints.notificationRead(id));

      if ([200, 201].contains(response.statusCode)) {
        final payload = (response.data as DataMap?)?['data'] as DataMap?;
        final notification = payload != null
            ? NotificationModel.fromJson(payload)
            : NotificationModel(
                id: id,
                type: '',
                title: '',
                body: '',
                data: const {},
                isRead: true,
                readAt: DateTime.now(),
                createdAt: null,
                updatedAt: null,
              );
        appLogger.i('NotificationRepository.markAsRead → id=$id marked read');
        return Right(notification);
      }

      appLogger.w('NotificationRepository.markAsRead → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('NotificationRepository.markAsRead → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'NotificationRepository', methodName: 'markAsRead');
    }
  }

  // ─── Mark all as read ──────────────────────────────────────────────────────

  ResultFuture<bool> markAllAsRead() async {
    appLogger.d('NotificationRepository.markAllAsRead → initiated');
    try {
      final response =
          await _client.patch(ApiEndpoints.notificationsReadAll);

      if ([200, 201, 204].contains(response.statusCode)) {
        appLogger.i('NotificationRepository.markAllAsRead → success');
        return const Right(true);
      }

      appLogger.w(
          'NotificationRepository.markAllAsRead → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('NotificationRepository.markAllAsRead → DioException',
          error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'NotificationRepository',
          methodName: 'markAllAsRead');
    }
  }

  // ─── Delete ────────────────────────────────────────────────────────────────

  ResultFuture<bool> deleteNotification(String id) async {
    appLogger.d('NotificationRepository.deleteNotification → id=$id');
    try {
      final response =
          await _client.delete(ApiEndpoints.notificationById(id));

      if ([200, 201, 204].contains(response.statusCode)) {
        appLogger.i('NotificationRepository.deleteNotification → id=$id deleted');
        return const Right(true);
      }

      appLogger.w(
          'NotificationRepository.deleteNotification → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('NotificationRepository.deleteNotification → DioException',
          error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'NotificationRepository',
          methodName: 'deleteNotification');
    }
  }

  // ─── Private Helpers ───────────────────────────────────────────────────────

  /// Unwraps the notifications array regardless of whether the API returns
  /// it directly under `data`, nested inside a paginator (`data.data`), or
  /// as the raw top-level body.
  List<dynamic> _dataList(Response response) {
    final body = response.data;
    if (body is List) return body;
    if (body is DataMap) {
      final d = body['data'];
      if (d is List) return d;
      if (d is DataMap) {
        // Confirmed live shape: {data: {items: [...], pagination: {...}}}
        for (final key in ['items', 'data', 'notifications']) {
          final inner = d[key];
          if (inner is List) return inner;
        }
      }
    }
    return const [];
  }
}
