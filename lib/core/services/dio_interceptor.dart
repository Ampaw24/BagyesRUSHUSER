import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:bagyesrushappusernew/core/helpers/cache_helper.dart';
import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/singletons/cache.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';

final _log = appLogger;

class DioInterceptor extends Interceptor {
  DioInterceptor({
    required CacheHelper cacheHelper,
    required Dio dio,
    this.onSessionExpired,
    @visibleForTesting Dio? refreshClient,
  })  : _cacheHelper = cacheHelper,
        _dio = dio,
        _refreshClient = refreshClient;

  final CacheHelper _cacheHelper;
  final Dio _dio;

  /// Sends the refresh call outside this interceptor (no recursion); built
  /// from [_dio]'s options unless injected.
  final Dio? _refreshClient;

  /// Called after a 401 that couldn't be recovered by a token refresh has
  /// cleared the stored session, so the app can end the session and route
  /// to login.
  final void Function()? onSessionExpired;

  /// Tracks whether a token refresh is already in progress so concurrent
  /// 401s don't fire multiple refresh calls.
  Completer<bool>? _refreshCompleter;

  /// Shared by every request that fails while the session is being torn
  /// down, so [onSessionExpired] fires once rather than once per 401.
  Future<void>? _sessionExpiry;

  /// Marks a request already replayed after a 401, so a second 401 on the
  /// replay ends the session instead of looping refresh → retry forever.
  static const _retriedKey = 'auth_retried';

  /// Public endpoints: never sent a bearer token, and a 401 from them means
  /// bad credentials — not an expired session to refresh.
  static const _publicPaths = {
    ApiEndpoints.login,
    ApiEndpoints.signup,
    ApiEndpoints.refreshToken,
    ApiEndpoints.passwordForgot,
    ApiEndpoints.forgotPassword,
  };

  /// Endpoints whose request/response bodies carry credentials, OTPs or
  /// tokens — logged as `{REDACTED}`. Superset of [_publicPaths]: some of
  /// these (password change, account delete) still need the bearer token.
  static const _sensitivePaths = {
    ..._publicPaths,
    ApiEndpoints.phoneSendCode,
    ApiEndpoints.phoneVerify,
    ApiEndpoints.passwordChange,
    ApiEndpoints.accountDelete,
  };

  static bool _matches(String path, Set<String> paths) =>
      paths.any((p) => path == p || path.endsWith(p));

  @visibleForTesting
  static bool isSensitivePath(String path) => _matches(path, _sensitivePaths);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Platform': 'mobile',
    });

    final path = options.path;
    if (!_matches(path, _publicPaths)) {
      final token = Cache.instance.sessionToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    final safeHeaders = Map<String, dynamic>.from(options.headers)
      ..remove('Authorization');
    final logBody =
        _matches(path, _sensitivePaths) ? '{REDACTED}' : (options.data ?? 'none');

    _log.d(
      '[REQUEST] ${options.method} ${options.uri}\n'
      'Headers: $safeHeaders\n'
      'Body: $logBody\n'
      'Query: ${options.queryParameters}',
    );

    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final path = response.requestOptions.path;
    final logData =
        _matches(path, _sensitivePaths) ? '{REDACTED}' : response.data;

    _log.d(
      '[RESPONSE] ${response.statusCode} ${response.requestOptions.uri}\n'
      'Data: $logData',
    );
    super.onResponse(response, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final path = options.path;
    final logResponse =
        _matches(path, _sensitivePaths) ? '{REDACTED}' : err.response?.data;

    _log.e(
      '[ERROR] ${err.type.name} ${options.uri}\n'
      'Status: ${err.response?.statusCode}\n'
      'Message: ${err.message}\n'
      'Response: $logResponse',
      error: err,
    );

    // A guest's request carries no token, so its 401 means "needs an
    // account", not "session expired" — nothing to refresh or clear.
    final sentAuth = options.headers['Authorization'] as String?;
    if (err.response?.statusCode != 401 ||
        sentAuth == null ||
        _matches(path, _publicPaths)) {
      return handler.next(err);
    }

    // Another request already ended this session — nothing left to recover.
    final currentToken = Cache.instance.sessionToken;
    if (currentToken == null) return handler.next(err);

    if (options.extra[_retriedKey] == true) {
      await _expireSession();
      return handler.next(err);
    }

    // The token was rotated by a refresh that finished after this request
    // was sent — replay with the current token instead of refreshing again.
    final tokenIsCurrent = sentAuth == 'Bearer $currentToken';
    if (tokenIsCurrent && !await _tryRefreshToken()) {
      await _expireSession();
      return handler.next(err);
    }

    try {
      options
        ..extra[_retriedKey] = true
        ..headers['Authorization'] = 'Bearer ${Cache.instance.sessionToken}';
      return handler.resolve(await _dio.fetch(options));
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    }
  }

  Future<void> _expireSession() async {
    // Torn down already by an earlier 401 whose expiry has finished.
    if (_sessionExpiry == null && Cache.instance.sessionToken == null) return;
    return _sessionExpiry ??= () async {
      try {
        await _cacheHelper.resetSession();
        onSessionExpired?.call();
      } finally {
        _sessionExpiry = null;
      }
    }();
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

      final freshDio = _refreshClient ?? Dio(BaseOptions(
        baseUrl: _dio.options.baseUrl,
        connectTimeout: _dio.options.connectTimeout,
        receiveTimeout: _dio.options.receiveTimeout,
        contentType: 'application/json',
        headers: {'Accept': 'application/json'},
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
