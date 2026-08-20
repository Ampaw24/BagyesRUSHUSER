import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/image_compression_utils.dart';
import '../../../core/utils/network_utility.dart';
import 'vendor_repository.dart';

class VendorRepositoryImpl implements VendorRepository {
  final NetworkUtility _networkUtility;

  VendorRepositoryImpl(this._networkUtility);

  @override
  Future<Either<Failure, Map<String, dynamic>>> submitRegistration(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _networkUtility.dio.post(
        ApiEndpoints.vendorRegister,
        data: data,
      );
      if (response.data['success'] == true) {
        return Right(response.data['data'] as Map<String, dynamic>);
      }
      return Left(
        ServerFailure(response.data['message'] ?? 'Registration failed'),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadDocument(
    String filePath,
    String documentType,
  ) async {
    try {
      final compressed = await ImageCompressionUtils.compressIfNeeded(
        File(filePath),
      );
      final formData = FormData.fromMap({
        'document_type': documentType,
        'file': await MultipartFile.fromFile(compressed.path),
      });
      final response = await _networkUtility.dio.post(
        ApiEndpoints.vendorDocUpload,
        data: formData,
      );
      if (response.data['success'] == true) {
        return Right(response.data['data']['url'] as String);
      }
      return Left(
        ServerFailure(response.data['message'] ?? 'Upload failed'),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> sendVerificationOtp(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _networkUtility.dio.post(
        ApiEndpoints.vendorOtpSend,
        data: data,
      );
      if (response.data['success'] == true) {
        return Right(response.data);
      }
      return Left(
        ServerFailure(response.data['message'] ?? 'Failed to send OTP'),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> verifyOtp(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _networkUtility.dio.post(
        ApiEndpoints.vendorOtpVerify,
        data: data,
      );
      if (response.data['success'] == true) {
        return Right(response.data);
      }
      return Left(
        ServerFailure(response.data['message'] ?? 'OTP verification failed'),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
