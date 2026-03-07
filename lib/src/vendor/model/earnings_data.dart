import 'package:equatable/equatable.dart';

// ─── Daily Revenue (chart data) ─────────────────────────────────────────

class DailyRevenue extends Equatable {
  final String label;
  final double amount;
  final int orderCount;

  const DailyRevenue({
    required this.label,
    required this.amount,
    this.orderCount = 0,
  });

  @override
  List<Object?> get props => [label, amount, orderCount];
}

// ─── Transaction ────────────────────────────────────────────────────────

class Transaction extends Equatable {
  final String id;
  final String orderId;
  final String amount;
  final String date;
  final String type; // 'credit' | 'debit'
  final String customerName;
  final String status; // 'completed' | 'pending' | 'failed'
  final String paymentMethod; // 'mobile_money' | 'card' | 'cash' | 'platform_fee'

  const Transaction({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.date,
    required this.type,
    this.customerName = '',
    this.status = 'completed',
    this.paymentMethod = 'mobile_money',
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      date: json['date'] as String? ?? '',
      type: json['type'] as String? ?? 'credit',
      customerName: json['customer_name'] as String? ?? '',
      status: json['status'] as String? ?? 'completed',
      paymentMethod: json['payment_method'] as String? ?? 'mobile_money',
    );
  }

  @override
  List<Object?> get props =>
      [id, orderId, amount, date, type, customerName, status, paymentMethod];
}

// ─── Top Selling Item ───────────────────────────────────────────────────

class TopSellingItem extends Equatable {
  final String name;
  final int orderCount;
  final String revenue;
  final String category;

  const TopSellingItem({
    required this.name,
    required this.orderCount,
    required this.revenue,
    this.category = '',
  });

  @override
  List<Object?> get props => [name, orderCount, revenue, category];
}

// ─── Payout Record ──────────────────────────────────────────────────────

class PayoutRecord extends Equatable {
  final String id;
  final String amount;
  final String date;
  final String status; // 'completed' | 'pending' | 'processing'
  final String method; // 'Mobile Money' | 'Bank Transfer'
  final String reference;

  const PayoutRecord({
    required this.id,
    required this.amount,
    required this.date,
    required this.status,
    this.method = 'Mobile Money',
    this.reference = '',
  });

  @override
  List<Object?> get props => [id, amount, date, status, method, reference];
}

// ─── Earnings Data (aggregate) ──────────────────────────────────────────

class EarningsData extends Equatable {
  final String totalRevenue;
  final String todayRevenue;
  final String weekRevenue;
  final String monthRevenue;
  final String pendingPayout;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final String avgOrderValue;
  final double completionRate;
  final double revenueGrowth;
  final List<DailyRevenue> chartData;
  final List<Transaction> transactions;
  final List<PayoutRecord> payouts;
  final List<TopSellingItem> topItems;

  const EarningsData({
    this.totalRevenue = 'GH₵ 0.00',
    this.todayRevenue = 'GH₵ 0.00',
    this.weekRevenue = 'GH₵ 0.00',
    this.monthRevenue = 'GH₵ 0.00',
    this.pendingPayout = 'GH₵ 0.00',
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
    this.avgOrderValue = 'GH₵ 0.00',
    this.completionRate = 0.0,
    this.revenueGrowth = 0.0,
    this.chartData = const [],
    this.transactions = const [],
    this.payouts = const [],
    this.topItems = const [],
  });

  factory EarningsData.fromJson(Map<String, dynamic> json) {
    return EarningsData(
      totalRevenue: json['total_revenue'] as String? ?? 'GH₵ 0.00',
      todayRevenue: json['today_revenue'] as String? ?? 'GH₵ 0.00',
      weekRevenue: json['week_revenue'] as String? ?? 'GH₵ 0.00',
      monthRevenue: json['month_revenue'] as String? ?? 'GH₵ 0.00',
      pendingPayout: json['pending_payout'] as String? ?? 'GH₵ 0.00',
      totalOrders: json['total_orders'] as int? ?? 0,
      completedOrders: json['completed_orders'] as int? ?? 0,
      cancelledOrders: json['cancelled_orders'] as int? ?? 0,
      avgOrderValue: json['avg_order_value'] as String? ?? 'GH₵ 0.00',
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      revenueGrowth: (json['revenue_growth'] as num?)?.toDouble() ?? 0.0,
      chartData: (json['chart_data'] as List<dynamic>?)
              ?.map((e) => DailyRevenue(
                    label: e['label'] as String? ?? '',
                    amount: (e['amount'] as num?)?.toDouble() ?? 0.0,
                    orderCount: e['order_count'] as int? ?? 0,
                  ))
              .toList() ??
          [],
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((e) => Transaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        totalRevenue, todayRevenue, weekRevenue, monthRevenue,
        pendingPayout, totalOrders, completedOrders, cancelledOrders,
        avgOrderValue, completionRate, revenueGrowth,
        chartData, transactions, payouts, topItems,
      ];
}
