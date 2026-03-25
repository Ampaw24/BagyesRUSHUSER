import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../constant/typedef.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/network_utility.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final NetworkUtility _networkUtility;

  AuthRepositoryImpl(this._networkUtility);

  @override
  ResultFuture<UserModel> signup(DataMap data) async {
    try {
      final response = await _networkUtility.dio.post(
        ApiEndpoints.customerSignup,
        data: data,
      );
      if (response.data['success'] == true) {
        return Right(UserModel.fromJson(response.data['data']));
      } else {
        return Left(ServerFailure(response.data['message'] ?? 'Signup failed'));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error during signup'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<DataMap> sendOtp(DataMap data) async {
    try {
      final response = await _networkUtility.dio.post(ApiEndpoints.otpSend, data: data);
      if (response.data['success'] == true) {
        return Right(response.data);
      } else {
        return Left(
          ServerFailure(response.data['message'] ?? 'OTP send failed'),
        );
      }
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error sending OTP'));
    }
  }

  @override
  ResultFuture<UserModel> getUserDetails(String id) async {
    try {
      final response = await _networkUtility.dio.post(ApiEndpoints.customerDetails(id));
      if (response.data['success'] == true) {
        return Right(UserModel.fromJson(response.data['data']));
      } else {
        return Left(
          ServerFailure(response.data['message'] ?? 'Failed to get details'),
        );
      }
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error getting details'));
    }
  }
}