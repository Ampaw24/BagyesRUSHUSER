import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../constant/app_theme.dart';

enum OrderStatus {
  pending('New', AppColors.primary),
  accepted('Accepted', AppColors.info),
  preparing('Preparing', AppColors.accent),
  ready('Ready', AppColors.warning),
  outForDelivery('Out for Delivery', AppColors.secondary),
  delivered('Delivered', AppColors.success),
  rejected('Rejected', AppColors.error),
  cancelled('Cancelled', AppColors.error);

  final String label;
  final Color color;
  const OrderStatus(this.label, this.color);

  /// Maps the backend's status string (snake_case action/state names, e.g.
  /// `out_for_delivery`) to this enum. Falls back to [pending] for unknown
  /// values rather than throwing, since the UI should never crash on an
  /// unrecognized status — verify these mappings against a real
  /// `GET vendor/me/orders` response and adjust if the backend uses
  /// different string values.
  static OrderStatus fromString(String value) {
    switch (value) {
      case 'pending':
      case 'new':
        return OrderStatus.pending;
      case 'accepted':
      case 'accept':
        return OrderStatus.accepted;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'out_for_delivery':
      case 'outForDelivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'rejected':
      case 'reject':
        return OrderStatus.rejected;
      case 'cancelled':
      case 'canceled':
      case 'cancel':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

enum OrderType { delivery, pickup, dineIn }

class OrderItem extends Equatable {
  final String name;
  final int quantity;
  final String price;
  final String? note;

  const OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.note,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      price: json['price'] as String? ?? '',
      note: json['note'] as String?,
    );
  }

  @override
  List<Object?> get props => [name, quantity, price, note];
}

class VendorOrder extends Equatable {
  final String id;
  final String items;
  final String amount;
  final String timeAgo;
  final OrderStatus status;
  final String customerName;
  final String? customerPhone;
  final String? customerNote;
  final OrderType orderType;
  final List<OrderItem> itemList;
  final DateTime? createdAt;

  const VendorOrder({
    required this.id,
    required this.items,
    required this.amount,
    required this.timeAgo,
    required this.status,
    this.customerName = '',
    this.customerPhone,
    this.customerNote,
    this.orderType = OrderType.delivery,
    this.itemList = const [],
    this.createdAt,
  });

  factory VendorOrder.fromJson(Map<String, dynamic> json) {
    return VendorOrder(
      id: json['id'] as String? ?? '',
      items: json['items'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      timeAgo: json['time_ago'] as String? ?? '',
      status: OrderStatus.fromString(json['status'] as String? ?? ''),
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String?,
      customerNote: json['customer_note'] as String?,
      orderType: _parseOrderType(json['order_type'] as String?),
      itemList: (json['item_list'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  static OrderType _parseOrderType(String? value) {
    switch (value) {
      case 'pickup':
        return OrderType.pickup;
      case 'dine_in':
        return OrderType.dineIn;
      default:
        return OrderType.delivery;
    }
  }

  @override
  List<Object?> get props => [
        id,
        items,
        amount,
        timeAgo,
        status,
        customerName,
        customerPhone,
        customerNote,
        orderType,
        itemList,
        createdAt,
      ];
}
