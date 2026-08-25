import 'package:equatable/equatable.dart';

/// Result of `POST /payments/verify`.
class PaymentVerificationResult extends Equatable {
  const PaymentVerificationResult({
    required this.reference,
    required this.amount,
    required this.status,
    this.paidAt,
  });

  final String reference;
  final double amount;
  final String status;
  final DateTime? paidAt;

  bool get isSuccessful => status == 'success';

  PaymentVerificationResult copyWith({
    String? reference,
    double? amount,
    String? status,
    DateTime? paidAt,
  }) {
    return PaymentVerificationResult(
      reference: reference ?? this.reference,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  factory PaymentVerificationResult.fromJson(Map<String, dynamic> json) {
    return PaymentVerificationResult(
      reference: json['reference']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? 'pending',
      paidAt: DateTime.tryParse(json['paidAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'reference': reference,
        'amount': amount,
        'status': status,
        'paidAt': paidAt?.toIso8601String(),
      };

  @override
  String toString() => '$reference, $amount, $status, $paidAt, ';

  @override
  List<Object?> get props => [reference, amount, status, paidAt];
}
