import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/service_locator.dart';
import '../models/payment_method_model.dart';
import '../models/mobile_money_model.dart';
import '../repositories/payment_repository.dart';
import '../viewmodels/payment_methods_viewmodel.dart';
import '../viewmodels/add_payment_method_viewmodel.dart';
import '../viewmodels/otp_verification_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository provider
// ─────────────────────────────────────────────────────────────────────────────

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return sl<PaymentRepository>();
});

// ─────────────────────────────────────────────────────────────────────────────
// Payment Methods List Notifier
// ─────────────────────────────────────────────────────────────────────────────

class PaymentMethodsNotifier extends Notifier<PaymentMethodsState> {
  late final PaymentRepository _repo;

  @override
  PaymentMethodsState build() {
    _repo = sl<PaymentRepository>();
    return const PaymentMethodsState();
  }

  // ── Load ────────────────────────────────────────────────────────────────

  Future<void> load() async {
    state = state.copyWith(status: PaymentMethodsStatus.loading, clearError: true);
    final result = await _repo.fetchPaymentMethods();
    result.fold(
      (failure) => state = state.copyWith(
        status: PaymentMethodsStatus.error,
        errorMessage: failure.message,
      ),
      (methods) => state = state.copyWith(
        status: PaymentMethodsStatus.loaded,
        paymentMethods: methods,
      ),
    );
  }

  // ── Delete ──────────────────────────────────────────────────────────────

  Future<void> delete(String id) async {
    state = state.copyWith(processingId: id);
    final result = await _repo.deletePaymentMethod(id);
    result.fold(
      (failure) => state = state.copyWith(
        errorMessage: failure.message,
        clearProcessingId: true,
      ),
      (_) {
        final updated = state.paymentMethods.where((m) => m.id != id).toList();
        state = state.copyWith(
          paymentMethods: updated,
          clearProcessingId: true,
          clearError: true,
        );
      },
    );
  }

  // ── Set default ─────────────────────────────────────────────────────────

  Future<void> setDefault(String id) async {
    state = state.copyWith(processingId: id);
    final result = await _repo.setDefaultPaymentMethod(id);
    result.fold(
      (failure) => state = state.copyWith(
        errorMessage: failure.message,
        clearProcessingId: true,
      ),
      (_) {
        final updated = state.paymentMethods.map((m) {
          return m.copyWith(isDefault: m.id == id);
        }).toList();
        state = state.copyWith(
          paymentMethods: updated,
          clearProcessingId: true,
          clearError: true,
        );
      },
    );
  }

  // ── Toggle enabled ───────────────────────────────────────────────────────

  Future<void> toggleEnabled(String id) async {
    final method = state.paymentMethods.firstWhere((m) => m.id == id);
    final newEnabled = !method.isEnabled;

    // Optimistic update
    state = state.copyWith(
      processingId: id,
      paymentMethods: state.paymentMethods.map((m) {
        return m.id == id ? m.copyWith(isEnabled: newEnabled) : m;
      }).toList(),
    );

    final result = await _repo.toggleEnabled(id, enabled: newEnabled);
    result.fold(
      (failure) {
        // Revert on failure
        state = state.copyWith(
          errorMessage: failure.message,
          clearProcessingId: true,
          paymentMethods: state.paymentMethods.map((m) {
            return m.id == id ? m.copyWith(isEnabled: !newEnabled) : m;
          }).toList(),
        );
      },
      (_) => state = state.copyWith(clearProcessingId: true, clearError: true),
    );
  }

  // ── Add from pending (after OTP verified) ──────────────────────────────

  void addVerifiedMethod(PaymentMethodModel method) {
    state = state.copyWith(
      paymentMethods: [method, ...state.paymentMethods],
    );
  }
}

final paymentMethodsProvider =
    NotifierProvider<PaymentMethodsNotifier, PaymentMethodsState>(
  PaymentMethodsNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Add Mobile Money Notifier
// ─────────────────────────────────────────────────────────────────────────────

class AddMobileMoneyNotifier extends Notifier<AddMobileMoneyState> {
  late final PaymentRepository _repo;

  @override
  AddMobileMoneyState build() {
    _repo = sl<PaymentRepository>();
    return const AddMobileMoneyState();
  }

  void setProvider(MobileMoneyProvider provider) {
    state = state.copyWith(provider: provider, clearError: true);
  }

  void setPhone(String phone) {
    state = state.copyWith(phoneNumber: phone, clearError: true);
  }

  void setAccountName(String name) {
    state = state.copyWith(accountName: name, clearError: true);
  }

  Future<void> submit() async {
    if (!state.isValid) return;
    state = state.copyWith(status: AddPaymentMethodStatus.loading, clearError: true);

    final model = MobileMoneyModel(
      provider: state.provider!,
      phoneNumber: state.phoneNumber,
      accountName: state.accountName,
    );

    final result = await _repo.addMobileMoney(model);
    result.fold(
      (failure) => state = state.copyWith(
        status: AddPaymentMethodStatus.error,
        errorMessage: failure.message,
      ),
      (method) => state = state.copyWith(
        status: AddPaymentMethodStatus.success,
        pendingMethodId: method.id,
      ),
    );
  }

  void reset() => state = const AddMobileMoneyState();
}

final addMobileMoneyProvider =
    NotifierProvider<AddMobileMoneyNotifier, AddMobileMoneyState>(
  AddMobileMoneyNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Add Visa Card Notifier
// ─────────────────────────────────────────────────────────────────────────────

class AddVisaCardNotifier extends Notifier<AddVisaCardState> {
  late final PaymentRepository _repo;

  @override
  AddVisaCardState build() {
    _repo = sl<PaymentRepository>();
    return const AddVisaCardState();
  }

  void setCardNumber(String raw) {
    state = state.copyWith(cardNumber: raw, clearError: true);
  }

  void setCardholderName(String name) {
    state = state.copyWith(cardholderName: name, clearError: true);
  }

  void setExpiry(String expiry) {
    state = state.copyWith(expiry: expiry, clearError: true);
  }

  void setCvv(String cvv) {
    state = state.copyWith(cvv: cvv, clearError: true);
  }

  void setFlipped(bool flipped) {
    state = state.copyWith(isFlipped: flipped);
  }

  Future<void> submit() async {
    if (!state.isValid) return;
    state = state.copyWith(status: AddPaymentMethodStatus.loading, clearError: true);

    final result = await _repo.addVisaCard(
      rawCardNumber: state.cardNumber,
      cardholderName: state.cardholderName,
      expiry: state.expiry,
      cvv: state.cvv,
    );
    result.fold(
      (failure) => state = state.copyWith(
        status: AddPaymentMethodStatus.error,
        errorMessage: failure.message,
      ),
      (method) => state = state.copyWith(
        status: AddPaymentMethodStatus.success,
        pendingMethodId: method.id,
      ),
    );
  }

  void reset() => state = const AddVisaCardState();
}

final addVisaCardProvider =
    NotifierProvider<AddVisaCardNotifier, AddVisaCardState>(
  AddVisaCardNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// OTP Verification Notifier
// ─────────────────────────────────────────────────────────────────────────────

class OtpVerificationNotifier extends Notifier<OtpVerificationState> {
  late final PaymentRepository _repo;
  Timer? _countdownTimer;

  @override
  OtpVerificationState build() {
    _repo = sl<PaymentRepository>();
    ref.onDispose(() => _countdownTimer?.cancel());
    return const OtpVerificationState();
  }

  // ── Countdown ────────────────────────────────────────────────────────────

  void startCountdown() {
    _countdownTimer?.cancel();
    state = state.copyWith(countdown: 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countdown <= 0) {
        timer.cancel();
        return;
      }
      state = state.copyWith(countdown: state.countdown - 1);
    });
  }

  // ── Digit input ──────────────────────────────────────────────────────────

  void setDigit(int index, String digit) {
    state = state.withDigit(index, digit).copyWith(clearError: true);
  }

  void clearDigit(int index) {
    state = state.withDigit(index, '').copyWith(clearError: true);
  }

  void setOtpFromPaste(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 6) return;
    final list = digits.split('').take(6).toList();
    state = state.copyWith(digits: list, clearError: true);
  }

  // ── Verify ───────────────────────────────────────────────────────────────

  Future<bool> verify(String paymentMethodId) async {
    if (!state.isComplete) return false;
    state = state.copyWith(
      status: OtpVerificationStatus.verifying,
      clearError: true,
    );

    final result = await _repo.verifyOtp(paymentMethodId, state.otp);
    return result.fold(
      (failure) {
        state = state.copyWith(
          status: OtpVerificationStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(status: OtpVerificationStatus.success);
        _countdownTimer?.cancel();
        return true;
      },
    );
  }

  // ── Resend ───────────────────────────────────────────────────────────────

  Future<void> resend(String paymentMethodId) async {
    if (!state.canResend) return;
    state = state.copyWith(
      status: OtpVerificationStatus.resending,
      clearError: true,
    ).cleared();

    final result = await _repo.sendOtp(paymentMethodId);
    result.fold(
      (failure) => state = state.copyWith(
        status: OtpVerificationStatus.error,
        errorMessage: failure.message,
      ),
      (_) {
        state = state.copyWith(status: OtpVerificationStatus.idle);
        startCountdown();
      },
    );
  }

  void reset() {
    _countdownTimer?.cancel();
    state = const OtpVerificationState();
  }
}

final otpVerificationProvider =
    NotifierProvider<OtpVerificationNotifier, OtpVerificationState>(
  OtpVerificationNotifier.new,
);
