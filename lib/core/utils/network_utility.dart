import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../constant/baseurl.dart';
import '../router/app_routes.dart';
import '../router/app_router.dart' show appRouter;
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
          if (e.response?.statusCode == 401) {
            // Token expired or invalid — clear session and redirect to login.
            await _sessionManager.logout();
            appRouter.go(AppRoutes.login);
          }
          return handler.next(e);
        },
      ),
    );

    // Log requests/responses only in debug builds.
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  Dio get dio => _dio;
}