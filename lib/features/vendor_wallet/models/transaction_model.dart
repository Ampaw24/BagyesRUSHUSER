import 'package:equatable/equatable.dart';

enum TransactionType {
  credit,     // earnings from orders
  withdrawal, // funds sent to payment method
  refund,     // returned funds
}

enum TransactionStatus {
  completed,
  pending,
  processing,
  failed,
}

class TransactionModel extends Equatable {
  final String id;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final double? fee;                // withdrawal fee, if applicable
  final String description;
  final String? referenceId;
  final String? paymentMethodLabel; // e.g. "MTN MoMo •• 567"
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.description,
    required this.createdAt,
    this.fee,
    this.referenceId,
    this.paymentMethodLabel,
  });

  bool get isCredit => type == TransactionType.credit || type == TransactionType.refund;
  bool get isDebit  => type == TransactionType.withdrawal;

  String get typeLabel => switch (type) {
        TransactionType.credit     => 'Order Earning',
        TransactionType.withdrawal => 'Withdrawal',
        TransactionType.refund     => 'Refund',
      };

  String get statusLabel => switch (status) {
        TransactionStatus.completed  => 'Completed',
        TransactionStatus.pending    => 'Pending',
        TransactionStatus.processing => 'Processing',
        TransactionStatus.failed     => 'Failed',
      };

  String formattedAmount(String currency) {
    final sign = isCredit ? '+' : '-';
    return '$sign $currency ${amount.toStringAsFixed(2)}';
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final typeStr   = json['type']   as String? ?? 'credit';
    final statusStr = json['status'] as String? ?? 'completed';
    return TransactionModel(
      id: json['id'] as String,
      type: switch (typeStr) {
        'withdrawal' => TransactionType.withdrawal,
        'refund'     => TransactionType.refund,
        _            => TransactionType.credit,
      },
      status: switch (statusStr) {
        'pending'    => TransactionStatus.pending,
        'processing' => TransactionStatus.processing,
        'failed'     => TransactionStatus.failed,
        _            => TransactionStatus.completed,
      },
      amount: (json['amount'] as num).toDouble(),
      fee: (json['fee'] as num?)?.toDouble(),
      description: json['description'] as String,
      referenceId: json['reference_id'] as String?,
      paymentMethodLabel: json['payment_method_label'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [id, type, status, amount, fee, description, referenceId, createdAt];
}
