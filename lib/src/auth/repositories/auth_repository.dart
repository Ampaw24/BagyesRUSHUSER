import 'package:bagyesrushappusernew/src/auth/models/business_type_model.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:bagyesrushappusernew/core/errors/failure.dart';
import 'package:bagyesrushappusernew/core/helpers/cache_helper.dart';
import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/auth/models/user.dart';

class AuthRepository {
  const AuthRepository({required Dio client, required CacheHelper cacheHelper})
    : _client = client,
      _cacheHelper = cacheHelper;

  final Dio _client;
  final CacheHelper _cacheHelper;

  Future<void> _cacheTokens(DataMap payload) async {
    final token = payload['token'] as String?;
    final refreshToken = payload['refresh_token'] as String?;
    if (token != null) await _cacheHelper.cacheSessionToken(token);
    if (refreshToken != null) {
      await _cacheHelper.cacheRefreshToken(refreshToken);
    }
  }

  ResultFuture<User> signup({
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String role,
    required String firstName,
    required String lastName,
    String? address,
    String? referralCode,
  }) async {
    appLogger.d('AuthRepository.signup → role=$role');
    final data = {
      'email': email,
      'phone': phone,
      'password': password,
      'confirm_password': confirmPassword,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
      'address': address ?? '',
      if (referralCode != null && referralCode.isNotEmpty)
        'referral_code': referralCode,
    };
    try {
      final response = await _client.post(ApiEndpoints.signup, data: data);

      appLogger.d(
        'AuthRepository.signup → RAW RESPONSE\n'
        '  status : ${response.statusCode}\n'
        '  data   : ${response.data}',
      );

      if ([200, 201].contains(response.statusCode)) {
        final payload =
            (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;

        await _cacheTokens(payload);

        final userJson = payload['user'] as DataMap? ?? payload;
        final user = User.fromJson(userJson);
        await _cacheHelper.cacheUserId(user.id);

        appLogger.i('AuthRepository.signup → success id=${user.id}');
        return Right(user);
      }

      appLogger.w('AuthRepository.signup → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'AuthRepository.signup → DioException\n'
        '  type   : ${e.type}\n'
        '  status : ${e.response?.statusCode}\n'
        '  data   : ${e.response?.data}',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'signup',
      );
    }
  }
//[vendor registration]

  ResultFuture<User> vendorRegister({
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String businessName,
    required String businessTypeId,
    required String contactPersonName,
    required String businessAddress,
    required String city,
    required String description,
    required String taxIdentificationNumber,
    required List<String> cuisineTypes,
    required double deliveryRadiusKm,
    required String openingTime,
    required String closingTime,
    required List<String> operatingDays,
    required int estimatedPrepTimeMinutes,
  }) async {
    appLogger.d('AuthRepository.vendorRegister → initiated');
    final data = {
      "email": email,
      "phone": phone,
      "password": password,
      "confirm_password": confirmPassword,
      "role": "vendor",
      "business_name": businessName,
      "business_type_id": businessTypeId,
      "contact_person_name": contactPersonName,
      "business_address": businessAddress,
      "city": city,
      "description": description,
      "tax_identification_number": taxIdentificationNumber,
      "cuisine_types": cuisineTypes,
      "delivery_radius_km": deliveryRadiusKm,
      "opening_time": openingTime,
      "closing_time": closingTime,
      "operating_days": operatingDays,
      "estimated_prep_time_minutes": estimatedPrepTimeMinutes,
    };
    try {
      final response = await _client.post(
        ApiEndpoints.vendorRegister,
        data: data,
      );

      appLogger.d(
        'AuthRepository.vendorRegister → RAW RESPONSE\n'
        '  status : ${response.statusCode}\n'
        '  data   : ${response.data}',
      );

      if ([200, 201].contains(response.statusCode)) {
        final payload =
            (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;

        await _cacheTokens(payload);

        final userJson = payload['user'] as DataMap? ?? payload;
        final user = User.fromJson(userJson);
        await _cacheHelper.cacheUserId(user.id);

        appLogger.i('AuthRepository.vendorRegister → success id=${user.id}');
        return Right(user);
      }

      appLogger.w(
        'AuthRepository.vendorRegister → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'AuthRepository.vendorRegister → DioException\n'
        '  type   : ${e.type}\n'
        '  status : ${e.response?.statusCode}\n'
        '  data   : ${e.response?.data}',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'vendorRegister',
      );
    }
  }
//[/vendor registration end]
///Provide business type for vendor registeration
  ResultFuture<List<BusinessTypeModel>> fetchBusinessTypes() async {
    appLogger.d('AuthRepository.fetchBusinessTypes → initiated');
    try {
      final response = await _client.get(ApiEndpoints.businessTypes);

      if ([200, 201].contains(response.statusCode)) {
        final payload = (response.data as DataMap)['data'] as List<dynamic>? ??
            response.data as List<dynamic>;
        final businessTypes = payload
            .map((e) => BusinessTypeModel.fromJson(e as DataMap))
            .toList();
        appLogger.i(
          'AuthRepository.fetchBusinessTypes → loaded ${businessTypes.length} business types',
        );
        return Right(businessTypes);
      }

      appLogger.w(
        'AuthRepository.fetchBusinessTypes → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('AuthRepository.fetchBusinessTypes → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'fetchBusinessTypes',
      );
    }
  }
//Business Type fetching ends here





  ResultFuture<User> login({
    required String phoneNumber,
    required String password,
  }) async {
    appLogger.d('AuthRepository.login → initiated');
    try {
      final response = await _client.post(
        ApiEndpoints.login,
        data: {'phone': phoneNumber, 'password': password},
      );

      appLogger.d(
        'AuthRepository.login → RAW RESPONSE\n'
        '  status : ${response.statusCode}\n'
        '  headers: ${response.headers}\n'
        '  data   : ${response.data}',
      );

      if ([200, 201].contains(response.statusCode)) {
        final payload =
            (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;

        await _cacheTokens(payload);

        final userJson = payload['user'] as DataMap? ?? payload;
        final user = User.fromJson(userJson);
        await _cacheHelper.cacheUserId(user.id);

        appLogger.i('AuthRepository.login → success id=${user.id}');
        return Right(user);
      }

      appLogger.w('AuthRepository.login → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'AuthRepository.login → DioException\n'
        '  type   : ${e.type}\n'
        '  status : ${e.response?.statusCode}\n'
        '  data   : ${e.response?.data}',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'login',
      );
    }
  }

  ResultFuture sendOtp({required String phone}) async {
    appLogger.d('AuthRepository.sendOtp → initiated');
    try {
      final response = await _client.post(
        ApiEndpoints.otpSend,
        data: {'phone': phone},
      );

      appLogger.d(
        'AuthRepository.sendOtp → RAW RESPONSE\n'
        '  status : ${response.statusCode}\n'
        '  data   : ${response.data}',
      );

      if ([200, 201].contains(response.statusCode)) {
        appLogger.i('AuthRepository.sendOtp → success');
        return Right(response.data as DataMap);
      }

      appLogger.w('AuthRepository.sendOtp → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'AuthRepository.sendOtp → DioException\n'
        '  type   : ${e.type}\n'
        '  status : ${e.response?.statusCode}\n'
        '  data   : ${e.response?.data}',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'sendOtp',
      );
    }
  }

  ResultFuture<void> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    appLogger.d('AuthRepository.verifyOtp → initiated');
    try {
      final response = await _client.post(
        ApiEndpoints.otpVerify,
        data: {'phone': phone, 'otp': otp},
      );

      appLogger.d(
        'AuthRepository.verifyOtp → RAW RESPONSE\n'
        '  status : ${response.statusCode}\n'
        '  data   : ${response.data}',
      );

      if ([200, 201].contains(response.statusCode)) {
        appLogger.i('AuthRepository.verifyOtp → verified');
        return const Right(null);
      }

      appLogger.w('AuthRepository.verifyOtp → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'AuthRepository.verifyOtp → DioException\n'
        '  type   : ${e.type}\n'
        '  status : ${e.response?.statusCode}\n'
        '  data   : ${e.response?.data}',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'verifyOtp',
      );
    }
  }

  ResultFuture<User> getUserDetails(String id) async {
    appLogger.d('AuthRepository.getUserDetails → id=$id');
    try {
      final response = await _client.get(ApiEndpoints.customerDetails(id));

      if (response.statusCode == 200) {
        final responseData = response.data as DataMap;
        final userJson = responseData['data'] as DataMap? ?? responseData;
        final user = User.fromJson(userJson);
        appLogger.i('AuthRepository.getUserDetails → success id=${user.id}');
        return Right(user);
      }

      appLogger.w(
        'AuthRepository.getUserDetails → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('AuthRepository.getUserDetails → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'getUserDetails',
      );
    }
  }

  /// Exchanges the stored refresh token for a new access + refresh token pair.
  ///
  /// On success both tokens are persisted via [CacheHelper] and the in-memory
  /// [Cache] singleton is updated so subsequent requests get the new token
  /// immediately — no app restart needed.
  ///
  /// On failure the caller receives a [Left<Failure>]; local session data is
  /// left intact so the UI can decide whether to force a logout.
  ResultFuture<void> refreshToken() async {
    appLogger.d('AuthRepository.refreshToken → attempting token refresh');
    try {
      final storedRefreshToken = await _cacheHelper.getRefreshToken();

      if (storedRefreshToken == null) {
        appLogger.w('AuthRepository.refreshToken → no refresh token stored');
        return Left(
          const ServerFailure(
            message: 'No refresh token available. Please log in again.',
            statusCode: 401,
            title: 'Session Expired',
          ),
        );
      }

      final response = await _client.post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': storedRefreshToken},
      );

      if ([200, 201].contains(response.statusCode)) {
        final payload =
            (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;

        await _cacheTokens(payload);
        appLogger.i('AuthRepository.refreshToken → new tokens cached');
        return const Right(null);
      }

      appLogger.w('AuthRepository.refreshToken → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('AuthRepository.refreshToken → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'refreshToken',
      );
    }
  }

  ResultFuture<User> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    appLogger.d('AuthRepository.updateProfile → initiated');
    try {
      final response = await _client.patch(
        ApiEndpoints.customerUpdate,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone': phone,
        },
      );

      appLogger.d(
        'AuthRepository.updateProfile → RAW RESPONSE\n'
        '  status : ${response.statusCode}\n'
        '  data   : ${response.data}',
      );

      if ([200, 201].contains(response.statusCode)) {
        final payload =
            (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;
        final userJson = payload['user'] as DataMap? ?? payload;
        final user = User.fromJson(userJson);
        appLogger.i('AuthRepository.updateProfile → success id=${user.id}');
        return Right(user);
      }

      appLogger.w('AuthRepository.updateProfile → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'AuthRepository.updateProfile → DioException\n'
        '  status : ${e.response?.statusCode}\n'
        '  data   : ${e.response?.data}',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'updateProfile',
      );
    }
  }

  /// Logs the user out by invalidating the server session first (while the
  /// token is still available), then clearing all local state.
  ResultFuture<void> logout() async {
    appLogger.d('AuthRepository.logout → clearing session');
    try {
      // Notify server before clearing local tokens so the auth header is sent
      try {
        await _client.post(ApiEndpoints.logout);
      } catch (_) {
        // Server logout is best-effort — always clear local session
      }
      await _cacheHelper.resetSession();
      appLogger.i('AuthRepository.logout → session cleared');
      return const Right(null);
    } catch (e, s) {
      // Even on unexpected failure, ensure local session is cleared
      await _cacheHelper.resetSession();
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'logout',
      );
    }
  }
}
