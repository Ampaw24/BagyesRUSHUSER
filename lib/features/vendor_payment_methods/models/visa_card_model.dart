import 'package:equatable/equatable.dart';

/// Detected card brand from the card number prefix.
enum CardBrand {
  visa,
  mastercard,
  other;

  String get displayName => switch (this) {
        CardBrand.visa => 'Visa',
        CardBrand.mastercard => 'Mastercard',
        CardBrand.other => 'Card',
      };

  static CardBrand fromNumber(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('4')) return CardBrand.visa;
    final prefix2 = digits.length >= 2 ? int.tryParse(digits.substring(0, 2)) : null;
    if (prefix2 != null && prefix2 >= 51 && prefix2 <= 55) return CardBrand.mastercard;
    final prefix4 = digits.length >= 4 ? int.tryParse(digits.substring(0, 4)) : null;
    if (prefix4 != null && prefix4 >= 2221 && prefix4 <= 2720) {
      return CardBrand.mastercard;
    }
    return CardBrand.other;
  }

  static CardBrand fromString(String value) => switch (value) {
        'visa' => CardBrand.visa,
        'mastercard' => CardBrand.mastercard,
        _ => CardBrand.other,
      };
}

/// Tokenized, PCI-safe card data stored for a payment method.
/// Full card number and CVV are NEVER stored — only last4 + token.
class VisaCardModel extends Equatable {
  final String cardLast4;
  final String cardholderName;

  /// Two-digit month, e.g. "12".
  final String expiryMonth;

  /// Two-digit year, e.g. "27".
  final String expiryYear;
  final CardBrand brand;

  /// Tokenized card reference returned by the payment gateway.
  final String? tokenizedCardId;

  const VisaCardModel({
    required this.cardLast4,
    required this.cardholderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.brand,
    this.tokenizedCardId,
  });

  /// Masked for display: •••• •••• •••• 4242
  String get maskedNumber => '•••• •••• •••• $cardLast4';

  String get expiryFormatted => '$expiryMonth/$expiryYear';

  VisaCardModel copyWith({
    String? cardLast4,
    String? cardholderName,
    String? expiryMonth,
    String? expiryYear,
    CardBrand? brand,
    String? tokenizedCardId,
  }) {
    return VisaCardModel(
      cardLast4: cardLast4 ?? this.cardLast4,
      cardholderName: cardholderName ?? this.cardholderName,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      brand: brand ?? this.brand,
      tokenizedCardId: tokenizedCardId ?? this.tokenizedCardId,
    );
  }

  factory VisaCardModel.fromJson(Map<String, dynamic> json) {
    return VisaCardModel(
      cardLast4: json['card_last4'] as String? ?? '0000',
      cardholderName: json['cardholder_name'] as String? ?? '',
      expiryMonth: json['expiry_month'] as String? ?? '01',
      expiryYear: json['expiry_year'] as String? ?? '00',
      brand: CardBrand.fromString(json['brand'] as String? ?? 'visa'),
      tokenizedCardId: json['tokenized_card_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'card_last4': cardLast4,
        'cardholder_name': cardholderName,
        'expiry_month': expiryMonth,
        'expiry_year': expiryYear,
        'brand': brand.name,
        'tokenized_card_id': tokenizedCardId,
      };

  @override
  List<Object?> get props => [
        cardLast4,
        cardholderName,
        expiryMonth,
        expiryYear,
        brand,
        tokenizedCardId,
      ];
}
