import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/core/utils/json_utils.dart';

enum CustomerWithdrawalStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,

  /// A status this app version doesn't know. Treated as final — never
  /// offered a Cancel button.
  unknown;

  static CustomerWithdrawalStatus fromApiValue(String? value) =>
      switch (value?.toLowerCase()) {
        'pending' => pending,
        'processing' => processing,
        'completed' || 'success' || 'successful' || 'paid' => completed,
        'failed' => failed,
        'cancelled' || 'canceled' => cancelled,
        _ => unknown,
      };

  String get label => switch (this) {
    pending => 'Pending',
    processing => 'Processing',
    completed => 'Completed',
    failed => 'Failed',
    cancelled => 'Cancelled',
    unknown => 'Unknown',
  };
}

/// A withdrawal request from `GET/POST /customer/withdrawals`.
class CustomerWithdrawalModel extends Equatable {
  const CustomerWithdrawalModel({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    this.statusLabel,
    this.reference,
    this.createdAt,
    this.processedAt,
  });

  final String id;
  final double amount;
  final String currency;
  final CustomerWithdrawalStatus status;

  /// The server's own wording, shown for statuses this app doesn't know.
  final String? statusLabel;
  final String? reference;
  final DateTime? createdAt;
  final DateTime? processedAt;

  /// Only a pending request can be cancelled
  /// (`PATCH /customer/withdrawals/:id/cancel`).
  bool get isCancellable => status == CustomerWithdrawalStatus.pending;

  String get displayStatus =>
      status == CustomerWithdrawalStatus.unknown &&
              (statusLabel?.isNotEmpty ?? false)
          ? statusLabel!
          : status.label;

  CustomerWithdrawalModel copyWith({CustomerWithdrawalStatus? status}) =>
      CustomerWithdrawalModel(
        id: id,
        amount: amount,
        currency: currency,
        status: status ?? this.status,
        statusLabel: statusLabel,
        reference: reference,
        createdAt: createdAt,
        processedAt: processedAt,
      );

  /// Null when the payload has no id — e.g. an action endpoint answering
  /// with just a message.
  static CustomerWithdrawalModel? tryFromJson(Map<String, dynamic> json) {
    final id = JsonUtils.asString(json['id']);
    if (id.isEmpty) return null;
    return CustomerWithdrawalModel(
      id: id,
      amount: JsonUtils.asDouble(json['amount']),
      currency: JsonUtils.asString(json['currency'], 'GHS'),
      status: CustomerWithdrawalStatus.fromApiValue(json['status']?.toString()),
      statusLabel: JsonUtils.asStringOrNull(json['status_label']),
      reference: JsonUtils.asStringOrNull(json['reference']),
      createdAt: JsonUtils.asDateTime(json['created_at']),
      processedAt: JsonUtils.asDateTime(json['processed_at']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    amount,
    currency,
    status,
    statusLabel,
    reference,
    createdAt,
    processedAt,
  ];
}

/// One page of `GET /customer/withdrawals`.
class CustomerWithdrawalPage extends Equatable {
  const CustomerWithdrawalPage({
    required this.withdrawals,
    required this.page,
    required this.totalPages,
  });

  final List<CustomerWithdrawalModel> withdrawals;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [withdrawals, page, totalPages];
}
