import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:bagyesrushappusernew/core/helpers/cache_helper.dart';
import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/auth/models/user.dart';

class AuthRepository {
  const AuthRepository({
    required Dio client,
    required CacheHelper cacheHelper,
  })  : _client = client,
        _cacheHelper = cacheHelper;

  final Dio _client;
  final CacheHelper _cacheHelper;

  Future<void> _cacheTokens(DataMap payload) async {
    final token = payload['token'] as String?;
    final refreshToken = payload['refresh_token'] as String?;
    if (token != null) await _cacheHelper.cacheSessionToken(token);
    if (refreshToken != null) await _cacheHelper.cacheRefreshToken(refreshToken);
  }

  ResultFuture<User> signup(DataMap data) async {
    try {
      final response = await _client.post(
        ApiEndpoints.customerSignup,
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final payload = (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;

        await _cacheTokens(payload);

        final userJson = payload['user'] as DataMap? ?? payload;
        final user = User.fromJson(userJson);
        await _cacheHelper.cacheUserId(user.id);

        return Right(user);
      }

      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e, s,
        repositoryName: 'AuthRepository',
        methodName: 'signup',
      );
    }
  }

  ResultFuture<User> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        ApiEndpoints.customerLogin,
        data: {'phone': phoneNumber, 'password': password},
      );

      if ([200, 201].contains(response.statusCode)) {
        final payload = (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;

        await _cacheTokens(payload);

        final userJson = payload['user'] as DataMap? ?? payload;
        final user = User.fromJson(userJson);
        await _cacheHelper.cacheUserId(user.id);

        return Right(user);
      }

      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e, s,
        repositoryName: 'AuthRepository',
        methodName: 'login',
      );
    }
  }

  ResultFuture<DataMap> sendOtp(DataMap data) async {
    try {
      final response = await _client.post(ApiEndpoints.otpSend, data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Right(response.data as DataMap);
      }

      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e, s,
        repositoryName: 'AuthRepository',
        methodName: 'sendOtp',
      );
    }
  }

  ResultFuture<User> getUserDetails(String id) async {
    try {
      final response = await _client.get(ApiEndpoints.customerDetails(id));

      if (response.statusCode == 200) {
        final responseData = response.data as DataMap;
        final userJson = responseData['data'] as DataMap? ?? responseData;
        return Right(User.fromJson(userJson));
      }

      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e, s,
        repositoryName: 'AuthRepository',
        methodName: 'getUserDetails',
      );
    }
  }

  ResultFuture<void> logout() async {
    try {
      await _cacheHelper.resetSession();
      return const Right(null);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e, s,
        repositoryName: 'AuthRepository',
        methodName: 'logout',
      );
    }
  }
}
