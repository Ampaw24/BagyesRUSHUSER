import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../constant/baseurl.dart';
import '../helpers/cache_helper.dart';
import '../router/app_routes.dart';
import '../router/app_router.dart' show appRouter;
import '../singletons/cache.dart';

/// Legacy network client used by vendor/onboarding repositories.
///
/// Now reads the session token from [Cache.instance] (the same source the
/// new MVVM [DioInterceptor] uses), eliminating the old
/// `UserSessionManager` as a separate source of truth.
class NetworkUtility {
  final Dio _dio;

  NetworkUtility()
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
          final token = Cache.instance.sessionToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Only a request that carried a token can have an expired
          // session — a guest's 401 must not bounce them to login.
          final sentToken = e.requestOptions.headers['Authorization'] != null;
          if (e.response?.statusCode == 401 && sentToken) {
            final sl = GetIt.instance;
            if (sl.isRegistered<CacheHelper>()) {
              await sl<CacheHelper>().resetSession();
            }
            appRouter.go(AppRoutes.login);
          }
          return handler.next(e);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  Dio get dio => _dio;
}
