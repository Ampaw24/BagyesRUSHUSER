import 'package:equatable/equatable.dart';

/// A single payment/wallet transaction entry returned by
/// `GET /customer/transactions` — a Paystack charge tied to a food order.
class TransactionModel extends Equatable {
  const TransactionModel({
    required this.id,
    required this.reference,
    required this.provider,
    required this.method,
    required this.methodLabel,
    required this.status,
    required this.statusLabel,
    required this.amount,
    required this.currency,
    required this.isCredit,
    required this.paidAt,
    required this.createdAt,
    required this.order,
  });

  final int id;
  final String reference;
  final String provider;
  final String method;
  final String methodLabel;
  final String status;
  final String statusLabel;
  final num amount;
  final String currency;
  final bool isCredit;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final TransactionOrder? order;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: (json["id"] as num?)?.toInt() ?? 0,
      reference: json["reference"]?.toString() ?? "",
      provider: json["provider"]?.toString() ?? "",
      method: json["method"]?.toString() ?? "",
      methodLabel: json["method_label"]?.toString() ?? "",
      status: json["status"]?.toString() ?? "",
      statusLabel: json["status_label"]?.toString() ?? "",
      amount: json["amount"] ?? 0,
      currency: json["currency"]?.toString() ?? "",
      isCredit: json["is_credit"] ?? false,
      paidAt: DateTime.tryParse(json["paid_at"]?.toString() ?? ""),
      createdAt: DateTime.tryParse(json["created_at"]?.toString() ?? ""),
      order: json["order"] == null
          ? null
          : TransactionOrder.fromJson(json["order"]),
    );
  }

  @override
  List<Object?> get props => [
    id,
    reference,
    provider,
    method,
    methodLabel,
    status,
    statusLabel,
    amount,
    currency,
    isCredit,
    paidAt,
    createdAt,
    order,
  ];
}

class TransactionOrder extends Equatable {
  const TransactionOrder({
    required this.id,
    required this.orderNumber,
    required this.type,
    required this.status,
    required this.statusLabel,
    required this.total,
    required this.refundedAt,
    required this.vendor,
  });

  final int id;
  final String orderNumber;
  final String type;
  final String status;
  final String statusLabel;
  final num total;
  final DateTime? refundedAt;
  final TransactionVendor? vendor;

  factory TransactionOrder.fromJson(Map<String, dynamic> json) {
    return TransactionOrder(
      id: (json["id"] as num?)?.toInt() ?? 0,
      orderNumber: json["order_number"]?.toString() ?? "",
      type: json["type"]?.toString() ?? "",
      status: json["status"]?.toString() ?? "",
      statusLabel: json["status_label"]?.toString() ?? "",
      total: json["total"] ?? 0,
      refundedAt: DateTime.tryParse(json["refunded_at"]?.toString() ?? ""),
      vendor: json["vendor"] == null
          ? null
          : TransactionVendor.fromJson(json["vendor"]),
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    type,
    status,
    statusLabel,
    total,
    refundedAt,
    vendor,
  ];
}

class TransactionVendor extends Equatable {
  const TransactionVendor({required this.id, required this.name, required this.logoUrl});

  final int id;
  final String name;
  final String? logoUrl;

  factory TransactionVendor.fromJson(Map<String, dynamic> json) {
    return TransactionVendor(
      id: (json["id"] as num?)?.toInt() ?? 0,
      name: json["name"]?.toString() ?? "",
      logoUrl: json["logo_url"]?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, name, logoUrl];
}

/// Pagination metadata for `GET /customer/transactions`.
class TransactionMeta extends Equatable {
  const TransactionMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
    required this.hasMore,
  });

  final int page;
  final int limit;
  final int total;
  final int pages;
  final bool hasMore;

  factory TransactionMeta.fromJson(Map<String, dynamic> json) {
    final page = ((json["page"] ?? json["current_page"]) as num?)?.toInt() ?? 1;
    final limit = ((json["limit"] ?? json["per_page"]) as num?)?.toInt() ?? 20;
    final total = (json["total"] as num?)?.toInt() ?? 0;
    final pages = ((json["pages"] ?? json["last_page"]) as num?)?.toInt() ?? 1;
    final hasMore = json["hasMore"] ?? json["has_more"];
    return TransactionMeta(
      page: page,
      limit: limit,
      total: total,
      pages: pages,
      hasMore: hasMore is bool ? hasMore : page < pages,
    );
  }

  @override
  List<Object?> get props => [page, limit, total, pages, hasMore];
}

/// Paginated result of `GET /customer/transactions`.
class TransactionListResult extends Equatable {
  const TransactionListResult({required this.transactions, required this.meta});

  final List<TransactionModel> transactions;
  final TransactionMeta meta;

  @override
  List<Object?> get props => [transactions, meta];
}
