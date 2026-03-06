import 'package:dio/dio.dart';
import '../../constant/baseurl.dart';
import '../services/user_session_manager.dart';

class NetworkUtility {
  final Dio _dio;
  final UserSessionManager _sessionManager;

  NetworkUtility(this._sessionManager)
    : _dio = Dio(
        BaseOptions(
          baseUrl: BASEURL,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _sessionManager.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 &&
              _sessionManager.refreshToken != null) {
            // TODO: Implement token refresh logic here if needed
          }
          return handler.next(e);
        },
      ),
    );

    // Add logging interceptor in debug mode
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  Dio get dio => _dio;
}
