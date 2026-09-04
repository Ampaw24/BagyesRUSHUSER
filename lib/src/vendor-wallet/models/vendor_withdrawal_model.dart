import 'package:equatable/equatable.dart';
import 'package:bagyesrushappusernew/core/utils/json_utils.dart';

enum VendorWithdrawalStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled;

  static VendorWithdrawalStatus fromApiValue(String? value) => switch (value) {
    'processing' => VendorWithdrawalStatus.processing,
    'completed' => VendorWithdrawalStatus.completed,
    'failed' => VendorWithdrawalStatus.failed,
    'cancelled' => VendorWithdrawalStatus.cancelled,
    _ => VendorWithdrawalStatus.pending,
  };
}

/// A withdrawal request from `GET/POST /vendor/me/withdrawals`.
class VendorWithdrawalModel extends Equatable {
  const VendorWithdrawalModel({
    required this.id,
    required this.amount,
    required this.status,
    this.reference,
    required this.createdAt,
    this.processedAt,
  });

  final String id;
  final double amount;
  final VendorWithdrawalStatus status;
  final String? reference;
  final DateTime createdAt;
  final DateTime? processedAt;

  /// Only pending withdrawals can be cancelled via
  /// `PATCH /vendor/me/withdrawals/:id/cancel`.
  bool get isCancellable => status == VendorWithdrawalStatus.pending;

  factory VendorWithdrawalModel.fromJson(Map<String, dynamic> json) {
    return VendorWithdrawalModel(
      id: JsonUtils.asString(json['id']),
      amount: JsonUtils.asDouble(json['amount']),
      status: VendorWithdrawalStatus.fromApiValue(json['status']?.toString()),
      reference: JsonUtils.asStringOrNull(json['reference']),
      createdAt: JsonUtils.asDateTime(json['created_at']) ?? DateTime.now(),
      processedAt: JsonUtils.asDateTime(json['processed_at']),
    );
  }

  @override
  List<Object?> get props =>
      [id, amount, status, reference, createdAt, processedAt];
}

/// Paginated result of `GET /vendor/me/withdrawals`.
class VendorWithdrawalListResult extends Equatable {
  const VendorWithdrawalListResult({
    required this.withdrawals,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final List<VendorWithdrawalModel> withdrawals;
  final int page;
  final int totalPages;
  final int total;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [withdrawals, page, totalPages, total];
}
