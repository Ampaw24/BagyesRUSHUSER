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

/// A selected addon/option on an order line item (e.g. "Extra Toppings:
/// Plantain, +GH₵2.00").
class OrderItemAddon extends Equatable {
  final String groupName;
  final String name;
  final double additionalPrice;

  const OrderItemAddon({
    required this.groupName,
    required this.name,
    this.additionalPrice = 0,
  });

  factory OrderItemAddon.fromJson(Map<String, dynamic> json) {
    return OrderItemAddon(
      groupName: json['group_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      additionalPrice: (json['additional_price'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [groupName, name, additionalPrice];
}

class OrderItem extends Equatable {
  final String name;
  final int quantity;
  final String price;
  final String? note;
  final List<OrderItemAddon> addons;

  const OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.note,
    this.addons = const [],
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final quantity = (json['quantity'] as num?)?.toInt() ?? 1;
    final lineTotal =
        (json['line_total'] as num?)?.toDouble() ??
        ((json['unit_price'] as num?)?.toDouble() ?? 0) * quantity;
    return OrderItem(
      name: json['name'] as String? ?? '',
      quantity: quantity,
      price: 'GH₵ ${lineTotal.toStringAsFixed(2)}',
      note: json['notes'] as String? ?? json['note'] as String?,
      addons:
          (json['options'] as List<dynamic>?)
              ?.map((e) => OrderItemAddon.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [name, quantity, price, note, addons];
}

/// One step in an order's status history, as returned by the backend's
/// `timeline` array. The array always lists the full happy-path sequence
/// (pending → accepted → preparing → ready → out_for_delivery → delivered)
/// regardless of the order's actual outcome — steps not yet reached (or
/// skipped, e.g. because the order was cancelled) come back with `at: null`.
class OrderTimelineEvent extends Equatable {
  final OrderStatus status;
  final String label;
  final DateTime? at;

  const OrderTimelineEvent({
    required this.status,
    required this.label,
    this.at,
  });

  bool get isReached => at != null;

  factory OrderTimelineEvent.fromJson(Map<String, dynamic> json) {
    return OrderTimelineEvent(
      status: OrderStatus.fromString(json['status'] as String? ?? ''),
      label: json['label'] as String? ?? '',
      at: json['at'] != null ? DateTime.tryParse(json['at'] as String) : null,
    );
  }

  @override
  List<Object?> get props => [status, label, at];
}

class VendorOrder extends Equatable {
  final String id;
  final String orderNumber;
  final String items;
  final String amount;
  final String timeAgo;
  final OrderStatus status;
  final String customerName;
  final String? customerPhone;
  final String? customerNote;
  final String? driverName;
  final String? driverPhone;
  final OrderType orderType;
  final List<OrderItem> itemList;
  final DateTime? createdAt;
  final String deliveryAddress;
  final String paymentMethodLabel;
  final bool isPaid;
  final bool collectOnDelivery;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double serviceFee;
  final double total;
  final double payoutAmount;
  final int? estimatedPrepMinutes;
  final DateTime? estimatedDeliveryAt;
  final double? deliveryDistanceKm;
  final bool canCancel;
  final bool canSelfDeliver;
  final List<OrderTimelineEvent> timeline;

  const VendorOrder({
    required this.id,
    this.orderNumber = '',
    required this.items,
    required this.amount,
    required this.timeAgo,
    required this.status,
    this.customerName = '',
    this.customerPhone,
    this.customerNote,
    this.driverName,
    this.driverPhone,
    this.orderType = OrderType.delivery,
    this.itemList = const [],
    this.createdAt,
    this.deliveryAddress = '',
    this.paymentMethodLabel = '',
    this.isPaid = false,
    this.collectOnDelivery = false,
    this.subtotal = 0,
    this.discount = 0,
    this.deliveryFee = 0,
    this.serviceFee = 0,
    this.total = 0,
    this.payoutAmount = 0,
    this.estimatedPrepMinutes,
    this.estimatedDeliveryAt,
    this.deliveryDistanceKm,
    this.canCancel = false,
    this.canSelfDeliver = false,
    this.timeline = const [],
  });

  factory VendorOrder.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final delivery = json['delivery'] as Map<String, dynamic>?;
    final rider = json['rider'] as Map<String, dynamic>?;
    final payment = json['payment'] as Map<String, dynamic>?;
    final totals = json['totals'] as Map<String, dynamic>?;

    final itemList =
        (json['items'] as List<dynamic>?)
            ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    final total =
        (totals?['total'] as num?)?.toDouble() ??
        (json['amount'] as num?)?.toDouble() ??
        0;
    final createdAt = json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String)
        : null;

    return VendorOrder(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number'] as String? ?? '',
      items: itemList.map((i) => '${i.quantity}x ${i.name}').join(', '),
      amount: 'GH₵ ${total.toStringAsFixed(2)}',
      timeAgo: _timeAgo(createdAt),
      status: OrderStatus.fromString(json['status'] as String? ?? ''),
      customerName:
          customer?['name'] as String? ??
          json['customer_name'] as String? ??
          '',
      customerPhone:
          customer?['phone'] as String? ?? json['customer_phone'] as String?,
      customerNote:
          json['notes'] as String? ?? delivery?['instructions'] as String?,
      driverName: rider?['name'] as String? ?? json['driver_name'] as String?,
      driverPhone:
          rider?['phone'] as String? ?? json['driver_phone'] as String?,
      orderType: _parseOrderType(json['order_type'] as String?),
      itemList: itemList,
      createdAt: createdAt,
      deliveryAddress: delivery?['address'] as String? ?? '',
      paymentMethodLabel:
          payment?['method_label'] as String? ??
          payment?['method'] as String? ??
          '',
      isPaid: payment?['is_paid'] as bool? ?? false,
      collectOnDelivery: payment?['collect_on_delivery'] as bool? ?? false,
      subtotal: (totals?['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (totals?['discount'] as num?)?.toDouble() ?? 0,
      deliveryFee: (totals?['delivery_fee'] as num?)?.toDouble() ?? 0,
      serviceFee: (totals?['service_fee'] as num?)?.toDouble() ?? 0,
      total: total,
      payoutAmount: (json['payout_amount'] as num?)?.toDouble() ?? 0,
      estimatedPrepMinutes: (json['estimated_prep_minutes'] as num?)?.toInt(),
      estimatedDeliveryAt: json['estimated_delivery_at'] != null
          ? DateTime.tryParse(json['estimated_delivery_at'] as String)
          : null,
      deliveryDistanceKm: (json['delivery_distance_km'] as num?)?.toDouble(),
      canCancel: json['can_cancel'] as bool? ?? false,
      canSelfDeliver: json['can_self_deliver'] as bool? ?? false,
      timeline:
          (json['timeline'] as List<dynamic>?)
              ?.map(
                (e) => OrderTimelineEvent.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
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

  static String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    items,
    amount,
    timeAgo,
    status,
    customerName,
    customerPhone,
    customerNote,
    driverName,
    driverPhone,
    orderType,
    itemList,
    createdAt,
    deliveryAddress,
    paymentMethodLabel,
    isPaid,
    collectOnDelivery,
    subtotal,
    discount,
    deliveryFee,
    serviceFee,
    total,
    payoutAmount,
    estimatedPrepMinutes,
    estimatedDeliveryAt,
    deliveryDistanceKm,
    canCancel,
    canSelfDeliver,
    timeline,
  ];
}
