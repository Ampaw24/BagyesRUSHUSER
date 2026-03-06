import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String id;
  final String orderId;
  final String amount;
  final String date;
  final String type; // 'credit' | 'debit'

  const Transaction({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.date,
    required this.type,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      date: json['date'] as String? ?? '',
      type: json['type'] as String? ?? 'credit',
    );
  }

  @override
  List<Object?> get props => [id, orderId, amount, date, type];
}

class EarningsData extends Equatable {
  final String totalRevenue;
  final String todayRevenue;
  final String pendingPayout;
  final int totalOrders;
  final List<Transaction> transactions;

  const EarningsData({
    this.totalRevenue = 'GH₵ 0',
    this.todayRevenue = 'GH₵ 0',
    this.pendingPayout = 'GH₵ 0',
    this.totalOrders = 0,
    this.transactions = const [],
  });

  factory EarningsData.fromJson(Map<String, dynamic> json) {
    return EarningsData(
      totalRevenue: json['total_revenue'] as String? ?? 'GH₵ 0',
      todayRevenue: json['today_revenue'] as String? ?? 'GH₵ 0',
      pendingPayout: json['pending_payout'] as String? ?? 'GH₵ 0',
      totalOrders: json['total_orders'] as int? ?? 0,
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((e) => Transaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props =>
      [totalRevenue, todayRevenue, pendingPayout, totalOrders, transactions];
}
