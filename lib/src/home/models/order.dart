import 'package:equatable/equatable.dart';

class Order extends Equatable {
  const Order({
    required this.id,
    required this.userId,
    required this.vendorId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String vendorId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String deliveryAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Order copyWith({
    String? id,
    String? userId,
    String? vendorId,
    List<OrderItem>? items,
    double? totalAmount,
    String? status,
    String? deliveryAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vendorId: vendorId ?? this.vendorId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return Order(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['user_id'] ?? '',
      vendorId: json['vendor_id'] ?? '',
      items: rawItems
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? '',
      deliveryAddress: json['delivery_address'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'user_id': userId,
        'vendor_id': vendorId,
        'items': items.map((e) => e.toJson()).toList(),
        'total_amount': totalAmount,
        'status': status,
        'delivery_address': deliveryAddress,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  @override
  String toString() => '$id, $userId, $vendorId, $status, $totalAmount';

  @override
  List<Object?> get props => [
        id,
        userId,
        vendorId,
        items,
        totalAmount,
        status,
        deliveryAddress,
        createdAt,
        updatedAt,
      ];
}

class OrderItem extends Equatable {
  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;

  double get subtotal => unitPrice * quantity;

  OrderItem copyWith({
    String? menuItemId,
    String? name,
    int? quantity,
    double? unitPrice,
  }) {
    return OrderItem(
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menu_item_id'] ?? '',
      name: json['name'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'menu_item_id': menuItemId,
        'name': name,
        'quantity': quantity,
        'unit_price': unitPrice,
      };

  @override
  String toString() => '$menuItemId, $name, x$quantity, $unitPrice';

  @override
  List<Object?> get props => [menuItemId, name, quantity, unitPrice];
}
