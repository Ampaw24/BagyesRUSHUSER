import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/network_utility.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserModel>> signup(Map<String, dynamic> data);
  Future<Either<Failure, Map<String, dynamic>>> sendOtp(
    Map<String, dynamic> data,
  );
  Future<Either<Failure, UserModel>> getUserDetails(String id);
}

class AuthRepositoryImpl implements AuthRepository {
  final NetworkUtility _networkUtility;

  AuthRepositoryImpl(this._networkUtility);

  @override
  Future<Either<Failure, UserModel>> signup(Map<String, dynamic> data) async {
    try {
      final response = await _networkUtility.dio.post(
        '/customers/signup',
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
  Future<Either<Failure, Map<String, dynamic>>> sendOtp(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _networkUtility.dio.post('/otp/send', data: data);
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
  Future<Either<Failure, UserModel>> getUserDetails(String id) async {
    try {
      final response = await _networkUtility.dio.post('/customers/details/$id');
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
