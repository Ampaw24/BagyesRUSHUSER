import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
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
    if (refreshToken != null){
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
    appLogger.d('AuthRepository.signup → email=$email phone=$phone role=$role');
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
      appLogger.e('AuthRepository.signup → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'AuthRepository', methodName: 'signup');
    }
  }

  ResultFuture<User> login({
    required String phoneNumber,
    required String password,
  }) async {
    appLogger.d('AuthRepository.login → phone=$phoneNumber');
    try {
      final response = await _client.post(
        ApiEndpoints.login,
        data: {'phone': phoneNumber, 'password': password},
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
      appLogger.e('AuthRepository.login → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'AuthRepository', methodName: 'login');
    }
  }

  ResultFuture sendOtp({required String phone}) async {
    appLogger.d('AuthRepository.sendOtp → phone=$phone');
    try {
      final response = await _client.post(ApiEndpoints.otpSend, data: {'phone': phone});

      if ([200, 201].contains(response.statusCode)) {
        appLogger.i('AuthRepository.sendOtp → OTP dispatched');
        return Right(response.data as DataMap);
      }

      appLogger.w('AuthRepository.sendOtp → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('AuthRepository.sendOtp → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'AuthRepository', methodName: 'sendOtp');
    }
  }

  ResultFuture<void> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    appLogger.d('AuthRepository.verifyOtp → phone=$phone');
    try {
      final response = await _client.post(
        ApiEndpoints.otpVerify,
        data: {'phone': phone, 'otp': otp},
      );

      if ([200, 201].contains(response.statusCode)) {
        appLogger.i('AuthRepository.verifyOtp → verified');
        return const Right(null);
      }

      appLogger.w('AuthRepository.verifyOtp → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('AuthRepository.verifyOtp → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'AuthRepository', methodName: 'verifyOtp');
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

      appLogger.w('AuthRepository.getUserDetails → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('AuthRepository.getUserDetails → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'AuthRepository', methodName: 'getUserDetails');
    }
  }

  ResultFuture<void> logout() async {
    appLogger.d('AuthRepository.logout → clearing session');
    try {
      await _cacheHelper.resetSession();
      appLogger.i('AuthRepository.logout → session cleared');
      return const Right(null);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'AuthRepository', methodName: 'logout');
    }
  }
}
