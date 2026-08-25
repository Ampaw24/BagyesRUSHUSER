import 'package:equatable/equatable.dart';

enum PaymentTransactionType {
  credit,
  debit;

  static PaymentTransactionType fromApiValue(String? value) => switch (value) {
        'debit' => PaymentTransactionType.debit,
        _ => PaymentTransactionType.credit,
      };
}

enum PaymentTransactionStatus {
  pending,
  success,
  failed;

  static PaymentTransactionStatus fromApiValue(String? value) => switch (value) {
        'success' => PaymentTransactionStatus.success,
        'failed' => PaymentTransactionStatus.failed,
        _ => PaymentTransactionStatus.pending,
      };
}

/// Mirrors the `transactions` table (`wallet_id, type, amount, reference,
/// description, status, created_at`) returned by `GET /payments/history`.
class PaymentTransaction extends Equatable {
  const PaymentTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    this.reference,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String walletId;
  final PaymentTransactionType type;
  final double amount;
  final String? reference;
  final String description;
  final PaymentTransactionStatus status;
  final DateTime createdAt;

  bool get isCredit => type == PaymentTransactionType.credit;

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id']?.toString() ?? '',
      walletId: json['walletId']?.toString() ?? '',
      type: PaymentTransactionType.fromApiValue(json['type']?.toString()),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      reference: json['reference']?.toString(),
      description: json['description']?.toString() ?? '',
      status: PaymentTransactionStatus.fromApiValue(json['status']?.toString()),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  @override
  String toString() =>
      '$id, $walletId, $type, $amount, $reference, $description, $status, $createdAt, ';

  @override
  List<Object?> get props =>
      [id, walletId, type, amount, reference, description, status, createdAt];
}

/// Paginated result of `GET /payments/history`.
class PaymentHistoryResult extends Equatable {
  const PaymentHistoryResult({
    required this.transactions,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final List<PaymentTransaction> transactions;
  final int page;
  final int totalPages;
  final int total;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [transactions, page, totalPages, total];
}
