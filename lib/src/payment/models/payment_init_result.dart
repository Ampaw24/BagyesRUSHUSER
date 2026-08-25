import 'package:equatable/equatable.dart';

/// Result of `POST /payments/initialize` or `POST /payments/wallet/topup` —
/// both return the same Paystack charge envelope.
class PaymentInitResult extends Equatable {
  const PaymentInitResult({
    required this.reference,
    this.paymentUrl,
    this.ussdCode,
    required this.status,
  });

  final String reference;
  final String? paymentUrl;
  final String? ussdCode;
  final String status;

  PaymentInitResult copyWith({
    String? reference,
    String? paymentUrl,
    String? ussdCode,
    String? status,
  }) {
    return PaymentInitResult(
      reference: reference ?? this.reference,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      ussdCode: ussdCode ?? this.ussdCode,
      status: status ?? this.status,
    );
  }

  factory PaymentInitResult.fromJson(Map<String, dynamic> json) {
    return PaymentInitResult(
      reference: json['reference']?.toString() ?? '',
      paymentUrl: json['paymentUrl']?.toString(),
      ussdCode: json['ussdCode']?.toString(),
      status: json['status']?.toString() ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() => {
        'reference': reference,
        'paymentUrl': paymentUrl,
        'ussdCode': ussdCode,
        'status': status,
      };

  @override
  String toString() => '$reference, $paymentUrl, $ussdCode, $status, ';

  @override
  List<Object?> get props => [reference, paymentUrl, ussdCode, status];
}
