import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/core/utils/json_utils.dart';

/// `GET /customer/delivery-quote` → `data`. [id] is the `delivery_quote_id`
/// for checkout; the fee itself is never sent back — the server reads it
/// off the stored quote row.
class DeliveryQuote extends Equatable {
  const DeliveryQuote({
    required this.id,
    required this.fee,
    this.currency = 'GHS',
    this.distanceKm,
    this.etaMinutes,
    this.expiresAt,
  });

  final int id;
  final double fee;
  final String currency;
  final double? distanceKm;
  final int? etaMinutes;
  final DateTime? expiresAt;

  factory DeliveryQuote.fromJson(Map<String, dynamic> json) => DeliveryQuote(
        id: JsonUtils.asInt(json['id']),
        fee: JsonUtils.asDouble(json['fee']),
        currency: JsonUtils.asString(json['currency'], 'GHS'),
        distanceKm: JsonUtils.firstDoubleOrNull(json, const ['distance_km']),
        etaMinutes: json['eta_minutes'] == null
            ? null
            : JsonUtils.asInt(json['eta_minutes']),
        expiresAt: JsonUtils.asDateTime(json['expires_at']),
      );

  @override
  List<Object?> get props =>
      [id, fee, currency, distanceKm, etaMinutes, expiresAt];
}
