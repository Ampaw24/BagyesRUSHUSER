import 'package:equatable/equatable.dart';

// ── Status ─────────────────────────────────────────────────────────────────

enum OtpVerificationStatus { idle, verifying, success, error, resending }

// ── State ──────────────────────────────────────────────────────────────────

class OtpVerificationState extends Equatable {
  /// Each element is one digit (empty string = not yet filled).
  final List<String> digits;
  final OtpVerificationStatus status;
  final String? errorMessage;

  /// Countdown in seconds before resend is allowed.
  final int countdown;

  const OtpVerificationState({
    this.digits = const ['', '', '', '', '', ''],
    this.status = OtpVerificationStatus.idle,
    this.errorMessage,
    this.countdown = 60,
  });

  // ── Derived ────────────────────────────────────────────────────────────

  String get otp => digits.join();
  bool get isComplete => digits.every((d) => d.isNotEmpty);
  bool get canResend => countdown == 0;
  bool get isLoading =>
      status == OtpVerificationStatus.verifying ||
      status == OtpVerificationStatus.resending;

  OtpVerificationState copyWith({
    List<String>? digits,
    OtpVerificationStatus? status,
    String? errorMessage,
    int? countdown,
    bool clearError = false,
  }) {
    return OtpVerificationState(
      digits: digits ?? this.digits,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      countdown: countdown ?? this.countdown,
    );
  }

  OtpVerificationState withDigit(int index, String digit) {
    final updated = List<String>.from(digits);
    updated[index] = digit;
    return copyWith(digits: updated);
  }

  OtpVerificationState cleared() {
    return copyWith(
      digits: ['', '', '', '', '', ''],
      clearError: true,
    );
  }

  @override
  List<Object?> get props => [digits, status, errorMessage, countdown];
}
