import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/core/utils/json_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';

/// A saved delivery address (`GET /customer/addresses`). Its [id] is the
/// `customer_address_id` sent to the delivery quote and to order placement.
class CustomerAddress extends Equatable {
  const CustomerAddress({
    required this.id,
    required this.address,
    this.label,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  final int id;
  final String address;
  final String? label;
  final double? latitude;
  final double? longitude;

  /// The cart's embedded delivery quote is priced against this address.
  final bool isDefault;

  factory CustomerAddress.fromJson(DataMap json) => CustomerAddress(
        id: JsonUtils.asInt(json['id']),
        address: JsonUtils.asString(
          json['address'] ?? json['address_line'] ?? json['formatted_address'],
        ),
        label: JsonUtils.asStringOrNull(json['label']),
        latitude: JsonUtils.firstDoubleOrNull(json, const ['latitude', 'lat']),
        longitude: JsonUtils.firstDoubleOrNull(json, const ['longitude', 'lng']),
        isDefault: JsonUtils.asBool(json['is_default']),
      );

  @override
  List<Object?> get props => [id, address, label, latitude, longitude, isDefault];
}
