import 'package:equatable/equatable.dart';
import '../../../core/utils/json_utils.dart';

/// Aggregate order counts/revenue from `GET vendor/me/orders/stats`.
///
/// The backend doesn't document a response shape beyond "aggregate order
/// statistics" — verify these keys against a real response and adjust if
/// the backend uses different field names.
class VendorOrderStats extends Equatable {
  final int totalOrders;
  final int pendingOrders;
  final int acceptedOrders;
  final int preparingOrders;
  final int readyOrders;
  final int outForDeliveryOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final int rejectedOrders;
  final double totalRevenue;

  const VendorOrderStats({
    this.totalOrders = 0,
    this.pendingOrders = 0,
    this.acceptedOrders = 0,
    this.preparingOrders = 0,
    this.readyOrders = 0,
    this.outForDeliveryOrders = 0,
    this.deliveredOrders = 0,
    this.cancelledOrders = 0,
    this.rejectedOrders = 0,
    this.totalRevenue = 0.0,
  });

  factory VendorOrderStats.fromJson(Map<String, dynamic> json) {
    return VendorOrderStats(
      totalOrders: JsonUtils.asInt(json['total_orders']),
      pendingOrders: JsonUtils.asInt(json['pending_orders']),
      acceptedOrders: JsonUtils.asInt(json['accepted_orders']),
      preparingOrders: JsonUtils.asInt(json['preparing_orders']),
      readyOrders: JsonUtils.asInt(json['ready_orders']),
      outForDeliveryOrders: JsonUtils.asInt(json['out_for_delivery_orders']),
      deliveredOrders: JsonUtils.asInt(json['delivered_orders']),
      cancelledOrders: JsonUtils.asInt(json['cancelled_orders']),
      rejectedOrders: JsonUtils.asInt(json['rejected_orders']),
      totalRevenue: JsonUtils.asDouble(json['total_revenue']),
    );
  }

  @override
  List<Object?> get props => [
        totalOrders,
        pendingOrders,
        acceptedOrders,
        preparingOrders,
        readyOrders,
        outForDeliveryOrders,
        deliveredOrders,
        cancelledOrders,
        rejectedOrders,
        totalRevenue,
      ];
}
