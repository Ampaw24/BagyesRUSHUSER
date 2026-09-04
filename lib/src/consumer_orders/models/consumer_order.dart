/// Consumer-side order domain entity.
library;

import 'package:bagyesrushappusernew/src/restaurant/models/addon.dart';

enum OrderStatus {
  pending,
  accepted,
  preparing,
  readyForPickup,
  pickedUp,
  onTheWay,
  delivered,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Order Placed';
      case OrderStatus.accepted:
        return 'Order Accepted';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.onTheWay:
        return 'On the Way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive =>
      this != OrderStatus.delivered && this != OrderStatus.cancelled;
}

/// Maps the backend's status string to [OrderStatus]. Falls back to
/// [OrderStatus.pending] for unrecognized values rather than throwing —
/// verify these against a real `GET customer/orders` response and adjust
/// if the backend uses different string values.
OrderStatus _orderStatusFromString(String value) {
  switch (value) {
    case 'pending':
    case 'pending_payment':
      return OrderStatus.pending;
    case 'accepted':
      return OrderStatus.accepted;
    case 'preparing':
      return OrderStatus.preparing;
    case 'ready':
    case 'ready_for_pickup':
      return OrderStatus.readyForPickup;
    case 'picked_up':
      return OrderStatus.pickedUp;
    case 'out_for_delivery':
    case 'on_the_way':
      return OrderStatus.onTheWay;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
    case 'canceled':
    case 'rejected':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.pending;
  }
}

enum PaymentStatus { pending, paid, failed }

PaymentStatus _paymentStatusFromString(String? value) {
  switch (value) {
    case 'paid':
    case 'success':
    case 'successful':
      return PaymentStatus.paid;
    case 'failed':
    case 'failure':
      return PaymentStatus.failed;
    default:
      return PaymentStatus.pending;
  }
}

class OrderItem {
  final String menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;

  /// Snapshot of selected addons at order time.
  final List<SelectedAddon> addons;

  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.addons = const [],
  });

  double get addonsUnitTotal =>
      addons.fold(0.0, (sum, a) => sum + a.additionalPrice);

  double get lineTotal => (unitPrice + addonsUnitTotal) * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        menuItemId: json['menu_item_id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
        addons: ((json['options'] ?? json['addons']) as List<dynamic>?)
                ?.map((a) => SelectedAddon.fromJson(a as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'menu_item_id': menuItemId,
        'name': name,
        'quantity': quantity,
        'unit_price': unitPrice,
        'addons': addons.map((a) => a.toJson()).toList(),
      };
}

class ConsumerOrder {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String restaurantImageUrl;
  final List<OrderItem> items;
  final OrderStatus status;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double discount;
  final double total;
  final String deliveryAddress;
  final String? deliveryInstructions;
  final DateTime placedAt;
  final DateTime? estimatedDelivery;
  final String? driverName;
  final String? driverPhone;
  final String paymentMethod;
  final PaymentStatus paymentStatus;
  final int? estimatedPrepMinutes;

  const ConsumerOrder({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantImageUrl,
    required this.items,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.discount,
    required this.total,
    required this.deliveryAddress,
    required this.placedAt,
    required this.paymentMethod,
    this.paymentStatus = PaymentStatus.pending,
    this.deliveryInstructions,
    this.estimatedDelivery,
    this.estimatedPrepMinutes,
    this.driverName,
    this.driverPhone,
  });

  int get totalItems => items.fold(0, (sum, e) => sum + e.quantity);

  /// Applies the lightweight fields returned by the tracking endpoint
  /// (`GET customer/orders/:id/track`) on top of a fully-loaded order,
  /// preserving items/totals/address that the track response doesn't
  /// include.
  ConsumerOrder copyWith({
    String? id,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    int? estimatedPrepMinutes,
    DateTime? estimatedDelivery,
    String? driverName,
    String? driverPhone,
  }) {
    return ConsumerOrder(
      id: id ?? this.id,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      restaurantImageUrl: restaurantImageUrl,
      items: items,
      status: status ?? this.status,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      discount: discount,
      total: total,
      deliveryAddress: deliveryAddress,
      deliveryInstructions: deliveryInstructions,
      placedAt: placedAt,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      estimatedPrepMinutes: estimatedPrepMinutes ?? this.estimatedPrepMinutes,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
    );
  }

  factory ConsumerOrder.fromJson(Map<String, dynamic> json) {
    final vendor = json['vendor'] as Map<String, dynamic>?;
    final delivery = json['delivery'] as Map<String, dynamic>?;
    final payment = json['payment'] as Map<String, dynamic>?;
    final totals = json['totals'] as Map<String, dynamic>?;
    final rider = json['rider'] as Map<String, dynamic>?;

    return ConsumerOrder(
      id: json['id'].toString(),
      restaurantId:
          (vendor?['id'] ?? json['vendor_id'] ?? json['restaurant_id'])?.toString() ?? '',
      restaurantName: vendor?['name'] as String? ??
          json['vendor_name'] as String? ??
          json['restaurant_name'] as String? ??
          '',
      restaurantImageUrl: vendor?['logo_url'] as String? ??
          json['vendor_image'] as String? ??
          json['restaurant_image_url'] as String? ??
          '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      status: _orderStatusFromString(json['status'] as String? ?? ''),
      subtotal: (totals?['subtotal'] as num?)?.toDouble() ??
          (json['subtotal'] as num?)?.toDouble() ??
          0,
      deliveryFee: (totals?['delivery_fee'] as num?)?.toDouble() ??
          (json['delivery_fee'] as num?)?.toDouble() ??
          0,
      serviceFee: (totals?['service_fee'] as num?)?.toDouble() ??
          (json['service_fee'] as num?)?.toDouble() ??
          0,
      discount: (totals?['discount'] as num?)?.toDouble() ??
          (json['discount'] as num?)?.toDouble() ??
          0,
      total: (totals?['total'] as num?)?.toDouble() ?? (json['total'] as num?)?.toDouble() ?? 0,
      deliveryAddress:
          delivery?['address'] as String? ?? json['delivery_address'] as String? ?? '',
      deliveryInstructions:
          delivery?['instructions'] as String? ?? json['delivery_instructions'] as String?,
      placedAt: DateTime.tryParse(
              json['created_at'] as String? ?? json['placed_at'] as String? ?? '') ??
          DateTime.now(),
      estimatedDelivery: DateTime.tryParse(
          (json['estimated_delivery_at'] ?? json['estimated_delivery']) as String? ?? ''),
      estimatedPrepMinutes:
          (json['estimated_prep_minutes'] as num?)?.toInt(),
      driverName: rider?['name'] as String? ?? json['driver_name'] as String?,
      driverPhone: rider?['phone'] as String? ?? json['driver_phone'] as String?,
      paymentMethod: payment?['method'] as String? ?? json['payment_method'] as String? ?? '',
      paymentStatus: _paymentStatusFromString(
          payment?['status'] as String? ?? json['payment_status'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vendor_id': restaurantId,
        'items': items.map((i) => i.toJson()).toList(),
        'status': status.name,
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'service_fee': serviceFee,
        'discount': discount,
        'total': total,
        'delivery_address': deliveryAddress,
        'delivery_instructions': deliveryInstructions,
        'payment_method': paymentMethod,
        'payment_status': paymentStatus.name,
      };
}
