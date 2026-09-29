import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/core/utils/typedefs.dart';

/// A GPS / map-picked drop-off that is not saved as a [CustomerAddress].
/// Sent to the delivery quote and order placement in place of
/// `customer_address_id`.
class DeliveryLocation extends Equatable {
  const DeliveryLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final double latitude;
  final double longitude;

  /// [address] is the reverse-geocoded place name for the coordinates.
  DataMap toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'delivery_address': address,
      };

  @override
  List<Object?> get props => [address, latitude, longitude];
}
