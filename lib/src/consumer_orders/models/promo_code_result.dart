import 'package:equatable/equatable.dart';

/// The backend-authoritative result of validating a promo code at checkout
/// (`POST /customer/promo-codes/validate`). `discount` and, when present,
/// every value under `totals` are whatever the backend computed — the client
/// only ever displays these, never derives them itself.
///
/// Only the request contract is documented for this endpoint; the
/// success-response shape isn't, so [fromJson] parses tolerantly (same
/// approach as [DeliveryQuote]/[ParcelQuote]): it prefers a nested `totals`
/// object and falls back to flatter top-level fields if the real response
/// differs.
class PromoCodeResult extends Equatable {
  const PromoCodeResult({
    required this.code,
    this.description,
    required this.discount,
    this.subtotal,
    this.deliveryFee,
    this.serviceFee,
    this.total,
    this.currency = 'GHS',
  });

  final String code;
  final String? description;
  final double discount;

  /// Full backend-recomputed totals, when the response includes them.
  /// Null fields fall back to the checkout screen's existing values.
  final double? subtotal;
  final double? deliveryFee;
  final double? serviceFee;
  final double? total;
  final String currency;

  factory PromoCodeResult.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>? ?? const {};
    final rawDiscount =
        json['discount'] ?? json['discount_amount'] ?? totals['discount'];
    return PromoCodeResult(
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString(),
      discount: (rawDiscount as num?)?.toDouble() ?? 0.0,
      subtotal: (totals['subtotal'] as num?)?.toDouble(),
      deliveryFee: (totals['delivery_fee'] as num?)?.toDouble(),
      serviceFee: (totals['service_fee'] as num?)?.toDouble(),
      total: (totals['total'] as num?)?.toDouble(),
      currency: totals['currency']?.toString() ??
          json['currency']?.toString() ??
          'GHS',
    );
  }

  @override
  List<Object?> get props => [
        code,
        description,
        discount,
        subtotal,
        deliveryFee,
        serviceFee,
        total,
        currency,
      ];
}
