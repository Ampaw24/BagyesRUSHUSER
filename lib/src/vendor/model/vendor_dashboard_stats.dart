import 'package:equatable/equatable.dart';
import '../../../core/utils/json_utils.dart';

/// Order/revenue counts for a single reporting window (`today`,
/// `last_7_days`, `last_30_days`, `all_time`) under `GET vendor/me/dashboard`.
class VendorDashboardPeriodStats extends Equatable {
  final int orders;
  final int delivered;
  final int cancelled;
  final double revenue;
  final double commission;
  final double averageOrderValue;

  const VendorDashboardPeriodStats({
    this.orders = 0,
    this.delivered = 0,
    this.cancelled = 0,
    this.revenue = 0,
    this.commission = 0,
    this.averageOrderValue = 0,
  });

  factory VendorDashboardPeriodStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const VendorDashboardPeriodStats();
    return VendorDashboardPeriodStats(
      orders: JsonUtils.asInt(json['orders']),
      delivered: JsonUtils.asInt(json['delivered']),
      cancelled: JsonUtils.asInt(json['cancelled']),
      revenue: JsonUtils.asDouble(json['revenue']),
      commission: JsonUtils.asDouble(json['commission']),
      averageOrderValue: JsonUtils.asDouble(json['average_order_value']),
    );
  }

  @override
  List<Object?> get props =>
      [orders, delivered, cancelled, revenue, commission, averageOrderValue];
}

/// Live order counts by kitchen stage, under `queue`.
class VendorDashboardQueue extends Equatable {
  final int awaitingResponse;
  final int inKitchen;
  final int ready;
  final int outForDelivery;

  const VendorDashboardQueue({
    this.awaitingResponse = 0,
    this.inKitchen = 0,
    this.ready = 0,
    this.outForDelivery = 0,
  });

  factory VendorDashboardQueue.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const VendorDashboardQueue();
    return VendorDashboardQueue(
      awaitingResponse: JsonUtils.asInt(json['awaiting_response']),
      inKitchen: JsonUtils.asInt(json['in_kitchen']),
      ready: JsonUtils.asInt(json['ready']),
      outForDelivery: JsonUtils.asInt(json['out_for_delivery']),
    );
  }

  int get totalActive => awaitingResponse + inKitchen + ready + outForDelivery;

  @override
  List<Object?> get props =>
      [awaitingResponse, inKitchen, ready, outForDelivery];
}

/// Rating summary, under `reputation`.
class VendorDashboardReputation extends Equatable {
  final double rating;
  final int reviewCount;

  const VendorDashboardReputation({this.rating = 0, this.reviewCount = 0});

  factory VendorDashboardReputation.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const VendorDashboardReputation();
    return VendorDashboardReputation(
      rating: JsonUtils.asDouble(json['rating']),
      reviewCount: JsonUtils.asInt(json['review_count']),
    );
  }

  @override
  List<Object?> get props => [rating, reviewCount];
}

/// Menu health summary, under `menu`.
class VendorDashboardMenuSummary extends Equatable {
  final int totalItems;
  final int unavailableItems;

  const VendorDashboardMenuSummary({
    this.totalItems = 0,
    this.unavailableItems = 0,
  });

  factory VendorDashboardMenuSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const VendorDashboardMenuSummary();
    return VendorDashboardMenuSummary(
      totalItems: JsonUtils.asInt(json['total_items']),
      unavailableItems: JsonUtils.asInt(json['unavailable_items']),
    );
  }

  @override
  List<Object?> get props => [totalItems, unavailableItems];
}

/// One entry of `top_items` — shape unconfirmed since the sample response
/// had an empty list; adjust field names once a populated response is seen.
class VendorDashboardTopItem extends Equatable {
  final String name;
  final int orderCount;
  final double revenue;

  const VendorDashboardTopItem({
    this.name = '',
    this.orderCount = 0,
    this.revenue = 0,
  });

  factory VendorDashboardTopItem.fromJson(Map<String, dynamic> json) {
    return VendorDashboardTopItem(
      name: json['name'] as String? ?? '',
      orderCount: JsonUtils.asInt(json['order_count'] ?? json['orders']),
      revenue: JsonUtils.asDouble(json['revenue']),
    );
  }

  @override
  List<Object?> get props => [name, orderCount, revenue];
}

/// Aggregate dashboard summary from `GET vendor/me/dashboard`.
class VendorDashboardStats extends Equatable {
  final VendorDashboardPeriodStats today;
  final VendorDashboardPeriodStats last7Days;
  final VendorDashboardPeriodStats last30Days;
  final VendorDashboardPeriodStats allTime;
  final VendorDashboardQueue queue;
  final VendorDashboardReputation reputation;
  final VendorDashboardMenuSummary menu;
  final List<VendorDashboardTopItem> topItems;

  const VendorDashboardStats({
    this.today = const VendorDashboardPeriodStats(),
    this.last7Days = const VendorDashboardPeriodStats(),
    this.last30Days = const VendorDashboardPeriodStats(),
    this.allTime = const VendorDashboardPeriodStats(),
    this.queue = const VendorDashboardQueue(),
    this.reputation = const VendorDashboardReputation(),
    this.menu = const VendorDashboardMenuSummary(),
    this.topItems = const [],
  });

  factory VendorDashboardStats.fromJson(Map<String, dynamic> json) {
    return VendorDashboardStats(
      today: VendorDashboardPeriodStats.fromJson(
        json['today'] as Map<String, dynamic>?,
      ),
      last7Days: VendorDashboardPeriodStats.fromJson(
        json['last_7_days'] as Map<String, dynamic>?,
      ),
      last30Days: VendorDashboardPeriodStats.fromJson(
        json['last_30_days'] as Map<String, dynamic>?,
      ),
      allTime: VendorDashboardPeriodStats.fromJson(
        json['all_time'] as Map<String, dynamic>?,
      ),
      queue: VendorDashboardQueue.fromJson(
        json['queue'] as Map<String, dynamic>?,
      ),
      reputation: VendorDashboardReputation.fromJson(
        json['reputation'] as Map<String, dynamic>?,
      ),
      menu: VendorDashboardMenuSummary.fromJson(
        json['menu'] as Map<String, dynamic>?,
      ),
      topItems: (json['top_items'] as List<dynamic>?)
              ?.map(
                (e) => VendorDashboardTopItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [
        today,
        last7Days,
        last30Days,
        allTime,
        queue,
        reputation,
        menu,
        topItems,
      ];
}
