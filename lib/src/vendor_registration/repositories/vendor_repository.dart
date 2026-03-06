import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/network_utility.dart';

/// Contract for vendor registration API operations
abstract class VendorRepository {
  /// Submit the full vendor registration application
  Future<Either<Failure, Map<String, dynamic>>> submitRegistration(
    Map<String, dynamic> data,
  );

  /// Upload a document file (returns the uploaded file URL/path)
  Future<Either<Failure, String>> uploadDocument(
    String filePath,
    String documentType,
  );

  /// Send OTP for vendor phone/email verification
  Future<Either<Failure, Map<String, dynamic>>> sendVerificationOtp(
    Map<String, dynamic> data,
  );

  /// Verify the OTP code
  Future<Either<Failure, Map<String, dynamic>>> verifyOtp(
    Map<String, dynamic> data,
  );
}

class VendorRepositoryImpl implements VendorRepository {
  final NetworkUtility _networkUtility;

  VendorRepositoryImpl(this._networkUtility);

  @override
  Future<Either<Failure, Map<String, dynamic>>> submitRegistration(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _networkUtility.dio.post(
        '/vendors/register',
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
      final formData = FormData.fromMap({
        'document_type': documentType,
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _networkUtility.dio.post(
        '/vendors/documents/upload',
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
        '/vendors/otp/send',
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
        '/vendors/otp/verify',
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
