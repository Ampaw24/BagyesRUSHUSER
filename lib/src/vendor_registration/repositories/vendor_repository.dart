import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';

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
