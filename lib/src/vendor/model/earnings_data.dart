import 'package:equatable/equatable.dart';

// ─── Top Selling Item ───────────────────────────────────────────────────

class TopSellingItem extends Equatable {
  final String name;
  final int orderCount;
  final String revenue;

  const TopSellingItem({
    required this.name,
    required this.orderCount,
    required this.revenue,
  });

  @override
  List<Object?> get props => [name, orderCount, revenue];
}

// ─── Earnings Data (aggregate) ──────────────────────────────────────────
//
// Derived entirely from `GET /vendor/me/dashboard` (`VendorDashboardStats`)
// — there's no separate earnings endpoint. Anything that endpoint doesn't
// report (transactions, payout history, a revenue trend chart,
// period-over-period growth) simply isn't modeled here.

class EarningsData extends Equatable {
  final String totalRevenue;
  final String todayRevenue;
  final String weekRevenue;
  final String monthRevenue;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final String avgOrderValue;
  final double completionRate;
  final String commission;
  final String netEarnings;
  final List<TopSellingItem> topItems;

  const EarningsData({
    this.totalRevenue = 'GH₵ 0.00',
    this.todayRevenue = 'GH₵ 0.00',
    this.weekRevenue = 'GH₵ 0.00',
    this.monthRevenue = 'GH₵ 0.00',
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
    this.avgOrderValue = 'GH₵ 0.00',
    this.completionRate = 0.0,
    this.commission = 'GH₵ 0.00',
    this.netEarnings = 'GH₵ 0.00',
    this.topItems = const [],
  });

  @override
  List<Object?> get props => [
        totalRevenue,
        todayRevenue,
        weekRevenue,
        monthRevenue,
        totalOrders,
        completedOrders,
        cancelledOrders,
        avgOrderValue,
        completionRate,
        commission,
        netEarnings,
        topItems,
      ];
}
