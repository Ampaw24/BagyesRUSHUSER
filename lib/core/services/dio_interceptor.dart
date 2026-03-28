import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/singletons/cache.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';

final _log = appLogger;

class DioInterceptor extends Interceptor {
  static const _authExclusions = [
    'signup',
    'login',
    'forgot-password',
    'otp/send',
    'otp/verify',
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

    _log.i(
      '[REQUEST] ${options.method} ${options.uri}\n'
      'Headers: ${options.headers}\n'
      'Body: ${options.data ?? 'none'}\n'
      'Query: ${options.queryParameters}',
    );

    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log.i(
      '[RESPONSE] ${response.statusCode} ${response.requestOptions.uri}\n'
      'Data: ${response.data}',
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

    // On 401 for authenticated routes, clear the local session cache so the
    // token is not re-sent on subsequent requests. Navigation and UI feedback
    // are handled by the viewmodel layer — not here.
    final path = err.requestOptions.path;
    final isAuthExcluded = _authExclusions.any((e) => path.contains(e));
    if (err.response?.statusCode == 401 && !isAuthExcluded) {
      Cache.instance.resetSession();
    }

    handler.next(err);
  }
}
