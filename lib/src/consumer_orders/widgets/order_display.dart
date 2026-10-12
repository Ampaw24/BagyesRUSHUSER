import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';

/// Colour an order's status is shown in across the order lists.
extension OrderStatusColor on OrderStatus {
  Color get color => switch (this) {
    OrderStatus.delivered => AppColors.success,
    OrderStatus.cancelled || OrderStatus.rejected => AppColors.error,
    OrderStatus.refunded => AppColors.warning,
    OrderStatus.onTheWay || OrderStatus.pickedUp => AppColors.info,
    _ => AppColors.accent,
  };
}

/// The text the order lists print for an order.
extension OrderListText on ConsumerOrder {
  /// The vendor's name; a parcel has none, so "Parcel delivery · Send".
  String get listTitle {
    if (!isParcel) return restaurantName;
    return 'Parcel delivery · ${isReceiveParcel ? 'Receive' : 'Send'}';
  }

  /// Item count for food; for a parcel, where it went (or how many stops).
  /// Empty when a parcel has no destination to show.
  String get listDetail {
    if (!isParcel) return '$totalItems item${totalItems > 1 ? 's' : ''}';
    if (stops.length > 1) return '${stops.length} drop-offs';
    final destination =
        (stops.isEmpty ? deliveryAddress : stops.first.address).trim();
    return destination.isEmpty ? '' : 'To $destination';
  }
}
