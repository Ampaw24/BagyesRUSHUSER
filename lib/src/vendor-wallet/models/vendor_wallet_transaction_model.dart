import 'package:equatable/equatable.dart';
import 'package:bagyesrushappusernew/core/utils/json_utils.dart';

enum VendorWalletTransactionType {
  credit,
  debit;

  static VendorWalletTransactionType fromApiValue(String? value) =>
      switch (value) {
        'debit' => VendorWalletTransactionType.debit,
        _ => VendorWalletTransactionType.credit,
      };
}

enum VendorWalletTransactionStatus {
  pending,
  success,
  failed;

  static VendorWalletTransactionStatus fromApiValue(String? value) =>
      switch (value) {
        'success' => VendorWalletTransactionStatus.success,
        'failed' => VendorWalletTransactionStatus.failed,
        _ => VendorWalletTransactionStatus.pending,
      };
}

/// A single entry from `GET /vendor/me/wallet/transactions`.
class VendorWalletTransactionModel extends Equatable {
  const VendorWalletTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    this.reference,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final VendorWalletTransactionType type;
  final double amount;
  final String? reference;
  final String description;
  final VendorWalletTransactionStatus status;
  final DateTime createdAt;

  bool get isCredit => type == VendorWalletTransactionType.credit;

  factory VendorWalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return VendorWalletTransactionModel(
      id: JsonUtils.asString(json['id']),
      type: VendorWalletTransactionType.fromApiValue(
        json['type']?.toString(),
      ),
      amount: JsonUtils.asDouble(json['amount']),
      reference: JsonUtils.asStringOrNull(json['reference']),
      description: JsonUtils.asString(json['description']),
      status: VendorWalletTransactionStatus.fromApiValue(
        json['status']?.toString(),
      ),
      createdAt: JsonUtils.asDateTime(json['created_at']) ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props =>
      [id, type, amount, reference, description, status, createdAt];
}

/// Paginated result of `GET /vendor/me/wallet/transactions`.
class VendorWalletTransactionListResult extends Equatable {
  const VendorWalletTransactionListResult({
    required this.transactions,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final List<VendorWalletTransactionModel> transactions;
  final int page;
  final int totalPages;
  final int total;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [transactions, page, totalPages, total];
}
