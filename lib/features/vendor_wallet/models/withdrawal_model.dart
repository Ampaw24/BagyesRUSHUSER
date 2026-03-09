import 'package:equatable/equatable.dart';
import 'transaction_model.dart';

/// Minimum withdrawal amount in GH₵.
const double kMinWithdrawal = 10.0;

/// Fee rate (1.5 %).
const double kWithdrawalFeeRate = 0.015;

/// Flat fee cap so large withdrawals aren't penalised too heavily.
const double kWithdrawalFeeCap = 50.0;

class WithdrawalModel extends Equatable {
  final String id;
  final double amount;
  final double fee;
  final double netAmount;       // amount - fee received by vendor
  final String paymentMethodId;
  final String paymentMethodLabel;
  final TransactionStatus status;
  final DateTime createdAt;
  final String? referenceCode;

  const WithdrawalModel({
    required this.id,
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.paymentMethodId,
    required this.paymentMethodLabel,
    required this.status,
    required this.createdAt,
    this.referenceCode,
  });

  // ── Fee helpers ──────────────────────────────────────────────────────────

  static double calculateFee(double amount) {
    final fee = amount * kWithdrawalFeeRate;
    return fee > kWithdrawalFeeCap ? kWithdrawalFeeCap : fee;
  }

  static double calculateNet(double amount) => amount - calculateFee(amount);

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'pending';
    return WithdrawalModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      fee: (json['fee'] as num).toDouble(),
      netAmount: (json['net_amount'] as num).toDouble(),
      paymentMethodId: json['payment_method_id'] as String,
      paymentMethodLabel: json['payment_method_label'] as String,
      status: switch (statusStr) {
        'processing' => TransactionStatus.processing,
        'completed'  => TransactionStatus.completed,
        'failed'     => TransactionStatus.failed,
        _            => TransactionStatus.pending,
      },
      createdAt: DateTime.parse(json['created_at'] as String),
      referenceCode: json['reference_code'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [id, amount, fee, netAmount, paymentMethodId, status, createdAt];
}
