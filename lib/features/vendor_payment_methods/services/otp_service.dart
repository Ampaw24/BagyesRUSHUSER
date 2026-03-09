import 'payment_api_service.dart';

/// ── DUMMY IMPLEMENTATION ─────────────────────────────────────────────────
/// Accepts any 6-digit code as valid so you can test the full OTP flow
/// without a live backend. Swap the bodies for real Dio calls when the API
/// is ready.
///
/// Tip: enter any 6-digit number to verify. Entering "000000" simulates
/// an incorrect-OTP error so you can also test the error state.
class OtpService {
  final PaymentApiService _apiService;

  OtpService(this._apiService);

  // ── Send OTP ─────────────────────────────────────────────────────────

  Future<void> sendOtp(String paymentMethodId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // In production: POST /vendor/payment-methods/send-otp
    // For now just succeed silently — the countdown UI will start.
  }

  // ── Verify OTP ────────────────────────────────────────────────────────

  /// Returns a dummy token on success.
  /// Use "000000" to simulate a wrong-OTP error for testing.
  Future<String> verifyOtp(String paymentMethodId, String otp) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (otp == '000000') {
      throw Exception('Incorrect OTP. Please try again.');
    }

    // Mark the payment method as verified in the dummy store
    _apiService.markVerified(paymentMethodId);

    return 'tok_verified_${paymentMethodId}_${DateTime.now().millisecondsSinceEpoch}';
  }
}
