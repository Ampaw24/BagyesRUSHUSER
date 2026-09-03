import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/cart/models/cart_item_model.dart';

/// A customer's cart for a single vendor — the backend scopes one cart per
/// vendor (`GET customer/carts/:vendorId`), so adding an item from a
/// different vendor requires clearing this one first.
class CartModel {
  final String vendorId;
  final String vendorName;
  final String vendorImageUrl;
  final List<CartItemModel> items;
  final double? deliveryFee;
  final double? serviceFee;

  const CartModel({
    required this.vendorId,
    this.vendorName = '',
    this.vendorImageUrl = '',
    this.items = const [],
    this.deliveryFee,
    this.serviceFee,
  });

  factory CartModel.empty(String vendorId) => CartModel(vendorId: vendorId);

  CartModel copyWith({List<CartItemModel>? items}) => CartModel(
        vendorId: vendorId,
        vendorName: vendorName,
        vendorImageUrl: vendorImageUrl,
        items: items ?? this.items,
        deliveryFee: deliveryFee,
        serviceFee: serviceFee,
      );

  bool get isEmpty => items.isEmpty;
  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => items.fold(0.0, (sum, i) => sum + i.lineTotal);
  double get total => subtotal + (deliveryFee ?? 0) + (serviceFee ?? 0);

  factory CartModel.fromJson(DataMap json) {
    final vendor = json['vendor'] as DataMap?;
    final totals = json['totals'] as DataMap?;
    return CartModel(
      vendorId: (json['vendor_id'] ?? vendor?['id'])?.toString() ?? '',
      vendorName:
          vendor?['name'] as String? ?? json['vendor_name'] as String? ?? '',
      vendorImageUrl: vendor?['logo_url'] as String? ??
          vendor?['image_url'] as String? ??
          json['vendor_image_url'] as String? ??
          '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => CartItemModel.fromJson(e as DataMap))
          .toList(),
      deliveryFee: (totals?['delivery_fee'] as num?)?.toDouble() ??
          (vendor?['delivery_fee'] as num?)?.toDouble() ??
          (json['delivery_fee'] as num?)?.toDouble(),
      serviceFee: (totals?['service_fee'] as num?)?.toDouble() ??
          (vendor?['service_fee'] as num?)?.toDouble() ??
          (json['service_fee'] as num?)?.toDouble(),
    );
  }
}
