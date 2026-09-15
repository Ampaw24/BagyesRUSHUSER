import 'package:bagyesrushappusernew/core/utils/json_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';

/// Payload of the `order.status` realtime event.
///
/// [status] is kept as the raw backend string rather than parsed into the
/// `OrderStatus` enum — that enum and its parser live in the consumer-orders
/// feature (`src/`), and this core-layer file has no dependency on `src/`.
/// Parsing happens at the `OrdersViewModel` call site, reusing the same
/// parser the REST path already uses.
class OrderStatusEvent {
  const OrderStatusEvent({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.statusLabel,
    required this.isActive,
    this.estimatedDeliveryAt,
  });

  final String orderId;
  final String orderNumber;
  final String status;
  final String statusLabel;
  final bool isActive;
  final DateTime? estimatedDeliveryAt;

  factory OrderStatusEvent.fromJson(DataMap json) => OrderStatusEvent(
        orderId: JsonUtils.asString(json['order_id']),
        orderNumber: JsonUtils.asString(json['order_number']),
        status: JsonUtils.asString(json['status']),
        statusLabel: JsonUtils.asString(json['status_label']),
        isActive: JsonUtils.asBool(json['is_active'], true),
        estimatedDeliveryAt: JsonUtils.asDateTime(json['estimated_delivery_at']),
      );
}

/// Payload of the `rider.location` realtime event.
///
/// This event lands on two different channel types — `private-order.{id}`
/// and `private-admin.riders` — feeding one shared stream on
/// `RealtimeService`. [sourceOrderId] is stamped by `RealtimeService` from
/// which channel the event arrived on (the order id via an order channel,
/// `null` via the admin-riders feed) so listeners can tell them apart.
class RiderLocationEvent {
  const RiderLocationEvent({
    required this.riderId,
    required this.userId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
    this.vehicleType,
    this.plateNumber,
    this.heading,
    this.speedKph,
    this.accuracyM,
    this.isOnline = true,
    this.activeOrderIds = const [],
    this.recordedAt,
    this.sourceOrderId,
  });

  final String riderId;
  final String userId;
  final String name;
  final String? photoUrl;
  final String? vehicleType;
  final String? plateNumber;
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speedKph;
  final double? accuracyM;
  final bool isOnline;
  final List<String> activeOrderIds;
  final DateTime? recordedAt;
  final String? sourceOrderId;

  factory RiderLocationEvent.fromJson(DataMap json) => RiderLocationEvent(
        riderId: JsonUtils.asString(json['rider_id']),
        userId: JsonUtils.asString(json['user_id']),
        name: JsonUtils.asString(json['name']),
        photoUrl: JsonUtils.asStringOrNull(json['photo_url']),
        vehicleType: JsonUtils.asStringOrNull(json['vehicle_type']),
        plateNumber: JsonUtils.asStringOrNull(json['plate_number']),
        latitude: JsonUtils.asDouble(json['latitude']),
        longitude: JsonUtils.asDouble(json['longitude']),
        heading: json['heading'] == null ? null : JsonUtils.asDouble(json['heading']),
        speedKph: json['speed_kph'] == null ? null : JsonUtils.asDouble(json['speed_kph']),
        accuracyM: json['accuracy_m'] == null ? null : JsonUtils.asDouble(json['accuracy_m']),
        isOnline: JsonUtils.asBool(json['is_online'], true),
        activeOrderIds: JsonUtils.asStringList(json['active_order_ids']),
        recordedAt: JsonUtils.asDateTime(json['recorded_at']),
      );

  RiderLocationEvent copyWith({String? sourceOrderId}) => RiderLocationEvent(
        riderId: riderId,
        userId: userId,
        name: name,
        photoUrl: photoUrl,
        vehicleType: vehicleType,
        plateNumber: plateNumber,
        latitude: latitude,
        longitude: longitude,
        heading: heading,
        speedKph: speedKph,
        accuracyM: accuracyM,
        isOnline: isOnline,
        activeOrderIds: activeOrderIds,
        recordedAt: recordedAt,
        sourceOrderId: sourceOrderId ?? this.sourceOrderId,
      );
}
