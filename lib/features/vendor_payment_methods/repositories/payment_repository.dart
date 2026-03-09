import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/errors/failures.dart';
import '../models/payment_method_model.dart';
import '../models/mobile_money_model.dart';
import '../services/payment_api_service.dart';
import '../services/otp_service.dart';

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

// ── Implementation ─────────────────────────────────────────────────────────

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentApiService _api;
  final OtpService _otpService;

  PaymentRepositoryImpl(this._api, this._otpService);

  @override
  Future<Either<Failure, List<PaymentMethodModel>>> fetchPaymentMethods() =>
      _run(() => _api.fetchPaymentMethods());

  @override
  Future<Either<Failure, PaymentMethodModel>> addMobileMoney(
    MobileMoneyModel model,
  ) =>
      _run(() => _api.addMobileMoney(model));

  @override
  Future<Either<Failure, PaymentMethodModel>> addVisaCard({
    required String rawCardNumber,
    required String cardholderName,
    required String expiry,
    required String cvv,
  }) =>
      _run(
        () => _api.addVisaCard(
          rawCardNumber: rawCardNumber,
          cardholderName: cardholderName,
          expiry: expiry,
          cvv: cvv,
        ),
      );

  @override
  Future<Either<Failure, void>> deletePaymentMethod(String id) =>
      _run(() => _api.deletePaymentMethod(id));

  @override
  Future<Either<Failure, void>> setDefaultPaymentMethod(String id) =>
      _run(() => _api.setDefaultPaymentMethod(id));

  @override
  Future<Either<Failure, void>> toggleEnabled(
    String id, {
    required bool enabled,
  }) =>
      _run(() => _api.toggleEnabled(id, enabled: enabled));

  @override
  Future<Either<Failure, void>> sendOtp(String paymentMethodId) =>
      _run(() => _otpService.sendOtp(paymentMethodId));

  @override
  Future<Either<Failure, String>> verifyOtp(
    String paymentMethodId,
    String otp,
  ) =>
      _run(() => _otpService.verifyOtp(paymentMethodId, otp));

  // ── Helper ───────────────────────────────────────────────────────────────

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
