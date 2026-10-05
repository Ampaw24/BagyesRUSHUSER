import 'package:dio/dio.dart';

/// Legacy network handle used by vendor/onboarding repositories.
///
/// Wraps the app's shared [Dio] so these repositories get the same auth
/// header, token refresh, session-expiry handling and log redaction as the
/// rest of the app (see `DioInterceptor`) instead of a second client of
/// their own.
class NetworkUtility {
  const NetworkUtility(this._dio);

  final Dio _dio;

  Dio get dio => _dio;
}
