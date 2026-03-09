import 'package:equatable/equatable.dart';
import '../models/mobile_money_model.dart';
import '../models/visa_card_model.dart';
import '../utils/card_utils.dart';

// ── Status ─────────────────────────────────────────────────────────────────

enum AddPaymentMethodStatus { idle, loading, success, error }

// ── Mobile Money State ─────────────────────────────────────────────────────

class AddMobileMoneyState extends Equatable {
  final MobileMoneyProvider? provider;
  final String phoneNumber;
  final String accountName;
  final AddPaymentMethodStatus status;
  final String? errorMessage;

  /// ID of the newly created (pending) payment method — needed for OTP step.
  final String? pendingMethodId;

  const AddMobileMoneyState({
    this.provider,
    this.phoneNumber = '',
    this.accountName = '',
    this.status = AddPaymentMethodStatus.idle,
    this.errorMessage,
    this.pendingMethodId,
  });

  // ── Field-level validation ─────────────────────────────────────────────

  String? get phoneError {
    if (phoneNumber.isEmpty) return null;
    if (!PhoneUtils.isValidGhanaPhone(phoneNumber)) {
      return 'Enter a valid Ghanaian phone number';
    }
    if (provider != null) {
      final e164 = PhoneUtils.toE164(phoneNumber);
      final digits = e164.replaceAll(RegExp(r'\D'), '');
      final localPrefix = '0${digits.substring(3, 5)}';
      final compatible = provider!.dialPrefixes
          .any((p) => localPrefix.startsWith(p.substring(0, 3)));
      if (!compatible) {
        return 'Phone not compatible with ${provider!.displayName}';
      }
    }
    return null;
  }

  String? get accountNameError {
    if (accountName.isEmpty) return null;
    if (accountName.trim().length < 3) return 'Enter full account name';
    return null;
  }

  bool get isValid =>
      provider != null &&
      PhoneUtils.isValidGhanaPhone(phoneNumber) &&
      accountName.trim().length >= 3 &&
      phoneError == null;

  AddMobileMoneyState copyWith({
    MobileMoneyProvider? provider,
    String? phoneNumber,
    String? accountName,
    AddPaymentMethodStatus? status,
    String? errorMessage,
    String? pendingMethodId,
    bool clearError = false,
  }) {
    return AddMobileMoneyState(
      provider: provider ?? this.provider,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      accountName: accountName ?? this.accountName,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pendingMethodId: pendingMethodId ?? this.pendingMethodId,
    );
  }

  @override
  List<Object?> get props =>
      [provider, phoneNumber, accountName, status, errorMessage, pendingMethodId];
}

// ── Visa Card State ────────────────────────────────────────────────────────

class AddVisaCardState extends Equatable {
  /// Raw digits only (no spaces), max 16 chars.
  final String cardNumber;
  final String cardholderName;

  /// "MM/YY" formatted string.
  final String expiry;

  final String cvv;

  /// Whether the card widget is flipped to show CVV side.
  final bool isFlipped;
  final AddPaymentMethodStatus status;
  final String? errorMessage;
  final String? pendingMethodId;

  const AddVisaCardState({
    this.cardNumber = '',
    this.cardholderName = '',
    this.expiry = '',
    this.cvv = '',
    this.isFlipped = false,
    this.status = AddPaymentMethodStatus.idle,
    this.errorMessage,
    this.pendingMethodId,
  });

  // ── Derived ────────────────────────────────────────────────────────────

  CardBrand get detectedBrand => CardBrand.fromNumber(cardNumber);

  /// Formatted for preview "4242 4242 4242 4242".
  String get formattedCardNumber => CardUtils.formatCardNumber(cardNumber);

  // ── Validation ─────────────────────────────────────────────────────────

  String? get cardNumberError {
    if (cardNumber.isEmpty) return null;
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 16) return 'Enter full 16-digit card number';
    if (!CardUtils.isValidLuhn(digits)) return 'Invalid card number';
    return null;
  }

  String? get expiryError {
    if (expiry.isEmpty) return null;
    if (!CardUtils.isValidExpiry(expiry)) return 'Invalid or expired date';
    return null;
  }

  String? get cvvError {
    if (cvv.isEmpty) return null;
    if (!CardUtils.isValidCvv(cvv)) return 'CVV must be 3–4 digits';
    return null;
  }

  String? get cardholderError {
    if (cardholderName.isEmpty) return null;
    if (cardholderName.trim().length < 3) return 'Enter cardholder name';
    return null;
  }

  bool get isValid {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    return digits.length == 16 &&
        CardUtils.isValidLuhn(digits) &&
        CardUtils.isValidExpiry(expiry) &&
        CardUtils.isValidCvv(cvv) &&
        cardholderName.trim().length >= 3;
  }

  AddVisaCardState copyWith({
    String? cardNumber,
    String? cardholderName,
    String? expiry,
    String? cvv,
    bool? isFlipped,
    AddPaymentMethodStatus? status,
    String? errorMessage,
    String? pendingMethodId,
    bool clearError = false,
  }) {
    return AddVisaCardState(
      cardNumber: cardNumber ?? this.cardNumber,
      cardholderName: cardholderName ?? this.cardholderName,
      expiry: expiry ?? this.expiry,
      cvv: cvv ?? this.cvv,
      isFlipped: isFlipped ?? this.isFlipped,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pendingMethodId: pendingMethodId ?? this.pendingMethodId,
    );
  }

  @override
  List<Object?> get props => [
        cardNumber,
        cardholderName,
        expiry,
        cvv,
        isFlipped,
        status,
        errorMessage,
        pendingMethodId,
      ];
}
