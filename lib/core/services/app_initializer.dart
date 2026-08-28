import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import 'package:bagyesrushappusernew/constant/baseurl.dart';
import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/helpers/cache_helper.dart';
import 'package:bagyesrushappusernew/core/services/dio_interceptor.dart';
import 'package:bagyesrushappusernew/core/services/fcm_service.dart';
import 'package:bagyesrushappusernew/core/services/places_service.dart';
import 'package:bagyesrushappusernew/src/auth/repositories/auth_repository.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/location_helper.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_viewmodel.dart';

class AppInitializer {
  static final _sl = GetIt.instance;

  static Future<void> initialize() async {
    await _initCriticalServices();
  }

  static Future<void> initializeRemaining() async {
    // Firebase, analytics, push notifications, location — do NOT block splash.
    await FcmService.initialize();
    await LocationHelper.ensurePermission();
    await _logStartupLocation();
  }

  static Future<void> _logStartupLocation() async {
    final result = await LocationHelper.getCurrentLocation();
    final position = result.position;
    appLogger.i(
      '[AppInitializer] Startup location — status: ${result.status.name}, '
      'address: ${result.address}, '
      'lat: ${position?.latitude}, lng: ${position?.longitude}',
    );

    if (position == null) return;

    // Cross-check against Google's own Geocoding API — the native platform
    // geocoder above can have thin address coverage in some regions.
    final googleAddress = await PlacesService.reverseGeocode(
      position.latitude,
      position.longitude,
    );
    appLogger.i(
      '[AppInitializer] Google reverse-geocoded address: '
      '${googleAddress ?? 'unavailable'}',
    );
  }

  static Future<void> _initCriticalServices() async {
    // 1. Secure storage — single storage for all sensitive data
    if (!_sl.isRegistered<FlutterSecureStorage>()) {
      _sl.registerSingleton<FlutterSecureStorage>(
        const FlutterSecureStorage(),
      );
    }

    // 2. CacheHelper — all sensitive keys go through FlutterSecureStorage
    if (!_sl.isRegistered<CacheHelper>()) {
      _sl.registerSingleton<CacheHelper>(
        CacheHelper(secureStorage: _sl()),
      );
    }

    // 3. Warm the in-memory Cache singleton from secure storage so the
    //    DioInterceptor can inject the token on the very first request.
    await _sl<CacheHelper>().getSessionToken();
    await _sl<CacheHelper>().getUserId();

    // 4. Dio singleton with DioInterceptor
    if (!_sl.isRegistered<Dio>()) {
      _sl.registerSingleton<Dio>(_configureDio());
    }

    // 5. CurrentUserProvider — single source of truth for the logged-in user
    if (!_sl.isRegistered<CurrentUserProvider>()) {
      _sl.registerSingleton<CurrentUserProvider>(CurrentUserProvider());
    }

    // 6. AuthRepository
    if (!_sl.isRegistered<AuthRepository>()) {
      _sl.registerSingleton<AuthRepository>(
        AuthRepository(client: _sl(), cacheHelper: _sl()),
      );
    }

    // 7. AuthViewmodel
    if (!_sl.isRegistered<AuthViewmodel>()) {
      _sl.registerSingleton<AuthViewmodel>(
        AuthViewmodel(
          repository: _sl(),
          currentUserProvider: _sl(),
        ),
      );
    }

    // 8. Restore session — re-fetch user profile if token + userId are present
    await _sl<AuthViewmodel>().restoreSession();
  }

  static Dio _configureDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: BASEURL,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
      ),
    );
    dio.interceptors.add(DioInterceptor(
      cacheHelper: _sl<CacheHelper>(),
      dio: dio,
    ));
    if (kDebugMode) {
      // requestBody/responseBody are disabled — DioInterceptor already logs
      // request/response bodies with auth-endpoint redaction applied.
      // Enabling them here would print raw credentials (password, tokens) to
      // the device log via LogInterceptor's own unredacted output.
      dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
          logPrint: (o) => appLogger.d(o.toString()),
        ),
      );
    }
    return dio;
  }
}
