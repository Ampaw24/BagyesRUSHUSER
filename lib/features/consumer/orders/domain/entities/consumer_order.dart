/// Consumer-side order domain entity.
library;

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

class OrderItem {
  final String menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  double get lineTotal => unitPrice * quantity;
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
    this.deliveryInstructions,
    this.estimatedDelivery,
    this.driverName,
    this.driverPhone,
  });

  int get totalItems => items.fold(0, (sum, e) => sum + e.quantity);
}
