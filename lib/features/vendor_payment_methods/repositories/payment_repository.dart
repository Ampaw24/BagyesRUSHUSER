import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../models/payment_method_model.dart';
import '../models/mobile_money_model.dart';

// ── Abstract contract ──────────────────────────────────────────────────────

abstract class PaymentRepository {
  Future<Either<Failure, List<PaymentMethodModel>>> fetchPaymentMethods();

  Future<Either<Failure, PaymentMethodModel>> addMobileMoney(
    MobileMoneyModel model,
  );

  Future<Either<Failure, PaymentMethodModel>> addVisaCard({
    required String rawCardNumber,
    required String cardholderName,
    required String expiry,
    required String cvv,
  });

  Future<Either<Failure, void>> deletePaymentMethod(String id);

  Future<Either<Failure, void>> setDefaultPaymentMethod(String id);

  Future<Either<Failure, void>> toggleEnabled(
    String id, {
    required bool enabled,
  });

  Future<Either<Failure, void>> sendOtp(String paymentMethodId);

  Future<Either<Failure, String>> verifyOtp(
    String paymentMethodId,
    String otp,
  );
}
