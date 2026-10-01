import 'package:bagyesrushappusernew/core/utils/json_utils.dart';
import 'package:bagyesrushappusernew/core/utils/money_format.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/cart/models/cart_item_model.dart';

/// `wallet` block of the cart: [payable] is the figure on the checkout
/// button when the wallet is used — never `total − balance`.
class CartWallet {
  const CartWallet({this.available, this.applied, this.payable});

  final double? available;
  final double? applied;
  final double? payable;

  factory CartWallet.fromJson(DataMap json) => CartWallet(
        available: JsonUtils.firstDoubleOrNull(json, const ['available']),
        applied: JsonUtils.firstDoubleOrNull(json, const ['applied']),
        payable: JsonUtils.firstDoubleOrNull(json, const ['payable']),
      );
}

/// `promo` block — re-judged by the backend on every cart read. A code that
/// went stale comes back with `applied: false` and the reason in [error].
class CartPromo {
  const CartPromo({
    required this.code,
    this.applied = false,
    this.discount,
    this.appliesTo,
    this.error,
  });

  final String code;
  final bool applied;
  final double? discount;

  /// `food` | `delivery`. A free-delivery waiver lives inside the discount,
  /// never as a reduced delivery fee.
  final String? appliesTo;
  final String? error;

  static CartPromo? fromJson(dynamic json) {
    if (json is! DataMap) return null;
    final code = JsonUtils.asStringOrNull(json['code']);
    if (code == null || code.isEmpty) return null;
    return CartPromo(
      code: code,
      applied: JsonUtils.asBool(json['applied']),
      discount: JsonUtils.firstDoubleOrNull(json, const ['discount']),
      appliesTo: JsonUtils.asStringOrNull(json['applies_to']),
      error: JsonUtils.asStringOrNull(json['error']),
    );
  }
}

/// A customer's cart for a single vendor (`GET customer/carts/:vendorId`).
/// Every money figure is the backend's — null while unknown (no address to
/// quote against yet, or mid optimistic edit), never summed locally.
class CartModel {
  final String vendorId;
  final String vendorName;
  final String vendorImageUrl;
  final bool? vendorIsOpenNow;
  final double? minOrder;
  final List<CartItemModel> items;

  final double? subtotal;
  final double? discount;
  final double? deliveryFee;
  final double? serviceFee;
  final double? total;
  final String currency;

  final CartWallet? wallet;
  final CartPromo? promo;

  /// Embedded quote for the customer's default address.
  final int? deliveryQuoteId;
  final int? deliveryEtaMinutes;

  /// Why there is no quote ("too far", typically).
  final String? deliveryError;

  final bool meetsMinimumOrder;

  /// False when an item went unavailable or the basket is under the vendor's
  /// minimum — checkout must be disabled with the reason shown.
  final bool canCheckout;

  const CartModel({
    required this.vendorId,
    this.vendorName = '',
    this.vendorImageUrl = '',
    this.vendorIsOpenNow,
    this.minOrder,
    this.items = const [],
    this.subtotal,
    this.discount,
    this.deliveryFee,
    this.serviceFee,
    this.total,
    this.currency = 'GHS',
    this.wallet,
    this.promo,
    this.deliveryQuoteId,
    this.deliveryEtaMinutes,
    this.deliveryError,
    this.meetsMinimumOrder = true,
    this.canCheckout = true,
  });

  factory CartModel.empty(String vendorId) => CartModel(vendorId: vendorId);

  /// An items edit invalidates every backend figure until the server
  /// reconciles; [clearPromo] drops the promo for an optimistic remove.
  CartModel _copy({List<CartItemModel>? items, bool clearPromo = false}) {
    final keepTotals = items == null && !clearPromo;
    return CartModel(
      vendorId: vendorId,
      vendorName: vendorName,
      vendorImageUrl: vendorImageUrl,
      vendorIsOpenNow: vendorIsOpenNow,
      minOrder: minOrder,
      items: items ?? this.items,
      subtotal: items == null ? subtotal : null,
      discount: keepTotals ? discount : null,
      deliveryFee: deliveryFee,
      serviceFee: keepTotals ? serviceFee : null,
      total: keepTotals ? total : null,
      currency: currency,
      wallet: keepTotals ? wallet : null,
      promo: clearPromo ? null : promo,
      deliveryQuoteId: deliveryQuoteId,
      deliveryEtaMinutes: deliveryEtaMinutes,
      deliveryError: deliveryError,
      meetsMinimumOrder: meetsMinimumOrder,
      canCheckout: canCheckout,
    );
  }

  CartModel copyWith({List<CartItemModel>? items}) => _copy(items: items);

  CartModel withoutPromo() => _copy(clearPromo: true);

  bool get isEmpty => items.isEmpty;
  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);

  /// A code is stored and currently discounting.
  bool get hasPromo => promo?.applied ?? false;
  String? get promoCode => promo?.code;
  String? get promoError => promo?.applied == false ? promo?.error : null;

  /// The one client-side money figure: [total] is priced for the default
  /// address only, so another address's total is estimated from the
  /// backend identity (see [debugCheckTotalsIdentity]) and its quoted
  /// [deliveryFee]. The backend still prices the order on creation.
  double? estimatedTotalWith(double deliveryFee) {
    if (subtotal == null) return null;
    final estimate =
        subtotal! - (discount ?? 0) + deliveryFee + (serviceFee ?? 0);
    return (estimate * 100).round() / 100;
  }

  /// User-facing reason for [canCheckout] being false.
  String? get checkoutBlockedReason {
    if (canCheckout) return null;
    if (vendorIsOpenNow == false) return '$vendorName is closed right now';
    if (items.any((i) => !i.isAvailable)) {
      return 'Some items are no longer available — remove them to continue';
    }
    if (!meetsMinimumOrder) {
      return minOrder == null
          ? "Your basket is under this vendor's minimum order"
          : 'Minimum order is ${formatMoney(minOrder, currency: currency)}';
    }
    return "This cart can't be checked out right now";
  }

  factory CartModel.fromJson(DataMap json) {
    final vendor = json['vendor'] as DataMap?;
    final totals = json['totals'] as DataMap?;
    final delivery = json['delivery'] as DataMap?;
    double? total(String key) => JsonUtils.firstDoubleOrNull(totals, [key]);

    final cart = CartModel(
      vendorId: (json['vendor_id'] ?? vendor?['id'])?.toString() ?? '',
      vendorName: JsonUtils.asString(vendor?['name'] ?? json['vendor_name']),
      vendorImageUrl: JsonUtils.asString(
        vendor?['logo_url'] ?? vendor?['image_url'] ?? json['vendor_image_url'],
      ),
      vendorIsOpenNow: vendor?['is_open_now'] == null
          ? null
          : JsonUtils.asBool(vendor!['is_open_now']),
      minOrder: JsonUtils.firstDoubleOrNull(vendor, const ['min_order']),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => CartItemModel.fromJson(e as DataMap))
          .toList(),
      subtotal: total('subtotal'),
      discount: total('discount'),
      deliveryFee: total('delivery_fee'),
      serviceFee: total('service_fee'),
      total: total('total'),
      currency: JsonUtils.asString(totals?['currency'], 'GHS'),
      wallet: json['wallet'] is DataMap
          ? CartWallet.fromJson(json['wallet'] as DataMap)
          : null,
      promo: CartPromo.fromJson(json['promo']),
      deliveryQuoteId: delivery?['quote_id'] == null
          ? null
          : JsonUtils.asInt(delivery!['quote_id']),
      deliveryEtaMinutes: delivery?['eta_minutes'] == null
          ? null
          : JsonUtils.asInt(delivery!['eta_minutes']),
      deliveryError: JsonUtils.asStringOrNull(json['delivery_error']),
      meetsMinimumOrder: JsonUtils.asBool(json['meets_minimum_order'], true),
      canCheckout: JsonUtils.asBool(json['can_checkout'], true),
    );
    assert(debugCheckTotalsIdentity(
      subtotal: cart.subtotal,
      discount: cart.discount,
      deliveryFee: cart.deliveryFee,
      serviceFee: cart.serviceFee,
      total: cart.total,
    ));
    return cart;
  }
}
