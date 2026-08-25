import 'package:equatable/equatable.dart';

/// Result of `GET /payments/wallet`.
class PaymentWallet extends Equatable {
  const PaymentWallet({required this.balance, this.currency = 'GHS'});

  final double balance;
  final String currency;

  String get formattedBalance => '$currency ${balance.toStringAsFixed(2)}';

  PaymentWallet copyWith({double? balance, String? currency}) {
    return PaymentWallet(
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
    );
  }

  factory PaymentWallet.fromJson(Map<String, dynamic> json) {
    return PaymentWallet(
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'GHS',
    );
  }

  Map<String, dynamic> toJson() => {
        'balance': balance,
        'currency': currency,
      };

  @override
  String toString() => '$balance, $currency, ';

  @override
  List<Object?> get props => [balance, currency];
}
