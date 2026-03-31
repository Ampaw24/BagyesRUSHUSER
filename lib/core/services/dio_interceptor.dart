import 'dart:async';

import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/helpers/cache_helper.dart';
import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/singletons/cache.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';

final _log = appLogger;

class DioInterceptor extends Interceptor {
  DioInterceptor({required CacheHelper cacheHelper, required Dio dio})
      : _cacheHelper = cacheHelper,
        _dio = dio;

  final CacheHelper _cacheHelper;
  final Dio _dio;

  /// Tracks whether a token refresh is already in progress so concurrent
  /// 401s don't fire multiple refresh calls.
  Completer<bool>? _refreshCompleter;

  static const _authExclusions = [
    'signup',
    'login',
    'forgot-password',
    'otp/send',
    'otp/verify',
    'refresh-token',
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers.addAll({
      'Content-Type': 'application/json',
      'X-Platform': 'mobile',
    });

    final path = options.path;
    final needsToken = !_authExclusions.any((e) => path.contains(e));

    if (needsToken) {
      final token = Cache.instance.sessionToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    // Redact sensitive headers and body for auth endpoints
    final isAuthEndpoint = _authExclusions.any((e) => path.contains(e));
    final safeHeaders = Map<String, dynamic>.from(options.headers)
      ..remove('Authorization');
    _log.d(
      '[REQUEST] ${options.method} ${options.uri}\n'
      'Headers: $safeHeaders\n'
      'Body: ${isAuthEndpoint ? '[REDACTED]' : (options.data ?? 'none')}\n'
      'Query: ${options.queryParameters}',
    );

    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final respPath = response.requestOptions.path;
    final isAuthResp = _authExclusions.any((e) => respPath.contains(e));
    _log.d(
      '[RESPONSE] ${response.statusCode} ${response.requestOptions.uri}\n'
      'Data: ${isAuthResp ? '[REDACTED]' : response.data}',
    );
    super.onResponse(response, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    _log.e(
      '[ERROR] ${err.type.name} ${err.requestOptions.uri}\n'
      'Status: ${err.response?.statusCode}\n'
      'Message: ${err.message}\n'
      'Response: ${err.response?.data}',
      error: err,
    );

    final path = err.requestOptions.path;
    final isAuthExcluded = _authExclusions.any((e) => path.contains(e));

    // Attempt token refresh on 401 for authenticated routes
    if (err.response?.statusCode == 401 && !isAuthExcluded) {
      final didRefresh = await _tryRefreshToken();

      if (didRefresh) {
        // Retry the original request with the new token
        try {
          final opts = err.requestOptions;
          opts.headers['Authorization'] =
              'Bearer ${Cache.instance.sessionToken}';

          final response = await _dio.fetch(opts);
          return handler.resolve(response);
        } on DioException catch (retryErr) {
          return handler.next(retryErr);
        }
      }

      // Refresh failed — clear session so the UI layer can react
      await _cacheHelper.resetSession();
    }

    handler.next(err);
  }

  /// Attempts to refresh the access token using the stored refresh token.
  ///
  /// Uses a [Completer] to ensure only one refresh request runs at a time —
  /// concurrent 401s will await the same future.
  Future<bool> _tryRefreshToken() async {
    // If another refresh is already in flight, wait for it
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await _cacheHelper.getRefreshToken();
      if (refreshToken == null) {
        _log.w('[TOKEN REFRESH] No refresh token available');
        _refreshCompleter!.complete(false);
        return false;
      }

      _log.d('[TOKEN REFRESH] Attempting token refresh…');

      // Use a fresh Dio instance to avoid interceptor recursion
      final freshDio = Dio(BaseOptions(
        baseUrl: _dio.options.baseUrl,
        connectTimeout: _dio.options.connectTimeout,
        receiveTimeout: _dio.options.receiveTimeout,
        contentType: 'application/json',
      ));

      final response = await freshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final payload = data['data'] as Map<String, dynamic>? ?? data;

        final newToken = payload['token'] as String?;
        final newRefreshToken = payload['refresh_token'] as String?;

        if (newToken != null) {
          await _cacheHelper.cacheSessionToken(newToken);
          if (newRefreshToken != null) {
            await _cacheHelper.cacheRefreshToken(newRefreshToken);
          }
          _log.i('[TOKEN REFRESH] Success — new token cached');
          _refreshCompleter!.complete(true);
          return true;
        }
      }

      _log.w('[TOKEN REFRESH] Failed — status ${response.statusCode}');
      _refreshCompleter!.complete(false);
      return false;
    } catch (e) {
      _log.e('[TOKEN REFRESH] Exception during refresh', error: e);
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }
}
