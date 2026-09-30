/// Consumer-side order domain entity.
library;

import 'package:bagyesrushappusernew/core/utils/json_utils.dart';
import 'package:bagyesrushappusernew/core/utils/money_format.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/rider_location.dart';
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
///
/// Public (not file-private) so `OrdersViewModel` can reuse the exact same
/// parser for the `order.status` realtime event's status string, keeping
/// REST-driven and socket-driven status parsing consistent.
OrderStatus orderStatusFromString(String value) {
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

/// The payment status an order payload actually reports, or null when it
/// carries none — unlike [ConsumerOrder.fromJson], which defaults a missing
/// status to `pending`.
PaymentStatus? paymentStatusFromJson(Map<String, dynamic> json) {
  final payment = json['payment'];
  final raw = (payment is Map ? payment['status'] : null) ?? json['payment_status'];
  return raw == null ? null : _paymentStatusFromString(raw.toString());
}

/// Merges a freshly read payment status onto the known one. A missing value
/// keeps the current status, and a confirmed payment never regresses to
/// `pending` — a lagging read must not bring back "Pay Now".
PaymentStatus mergePaymentStatus(PaymentStatus current, PaymentStatus? incoming) {
  if (incoming == null) return current;
  if (current == PaymentStatus.paid && incoming == PaymentStatus.pending) {
    return current;
  }
  return incoming;
}

const _lineTotalKeys = ['line_total', 'total_price', 'total'];

class OrderItem {
  final String menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;

  /// Snapshot of selected addons at order time.
  final List<SelectedAddon> addons;

  /// Backend-computed line total (item + addons × quantity). Null when the
  /// response omits it — never derived client-side.
  final double? lineTotal;

  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.addons = const [],
    this.lineTotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        menuItemId: json['menu_item_id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
        lineTotal: JsonUtils.firstDoubleOrNull(json, _lineTotalKeys),
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
        'line_total': lineTotal,
        'addons': addons.map((a) => a.toJson()).toList(),
      };
}

/// Receive-parcel collection block: the code the pickup contact gives the
/// rider. Read from the track payload (`collection`) or the parcel payload
/// (`pickup`); null when the order has no collection step.
class OrderCollection {
  final String? code;
  final String? contactName;
  final String? contactPhone;
  final DateTime? verifiedAt;
  final DateTime? failedAt;
  final String? failureReason;

  const OrderCollection({
    this.code,
    this.contactName,
    this.contactPhone,
    this.verifiedAt,
    this.failedAt,
    this.failureReason,
  });

  bool get isVerified => verifiedAt != null;
  bool get hasFailed => failedAt != null;

  static OrderCollection? fromOrderJson(Map<String, dynamic> json) {
    final collection = json['collection'] as Map<String, dynamic>?;
    final pickup = json['pickup'] as Map<String, dynamic>?;
    String? str(Object? v) => v?.toString();
    DateTime? date(Object? v) => v == null ? null : DateTime.tryParse(v.toString());

    final code = str(collection?['pin'] ?? collection?['code'] ?? pickup?['code']);
    final failedAt = date(
        collection?['failed_at'] ?? pickup?['collection_failed_at']);
    if ((code == null || code.isEmpty) && failedAt == null) return null;

    return OrderCollection(
      code: code,
      contactName: str(collection?['contact_name'] ??
          pickup?['contact_name'] ??
          json['pickup_contact_name']),
      contactPhone: str(collection?['contact_phone'] ??
          pickup?['contact_phone'] ??
          json['pickup_contact_phone']),
      verifiedAt: date(collection?['verified_at'] ?? pickup?['code_verified_at']),
      failedAt: failedAt,
      failureReason: str(collection?['failure_reason'] ??
          pickup?['collection_failure_reason']),
    );
  }
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

  /// Rider profile extras — the same fields the parcel quote's `rider`
  /// carries (`photo_url`, `vehicle_type_label`, `rating`, `review_count`,
  /// `deliveries_completed`) plus `plate_number` from the realtime
  /// `rider.location` event. Each is null until the backend sends it.
  final String? driverPhotoUrl;
  final String? driverVehicleType;
  final String? driverPlateNumber;
  final double? driverRating;
  final int? driverReviewCount;
  final int? driverDeliveriesCompleted;
  final String paymentMethod;
  final PaymentStatus paymentStatus;

  /// `payment.requires_payment` — false for cash or a fully wallet-paid
  /// order. Null when the payload omits it.
  final bool? requiresPayment;
  final int? estimatedPrepMinutes;

  /// Handed to the courier at drop-off to confirm the right person is
  /// receiving the order. Generated once by the backend at order creation;
  /// [copyWith] only fills it in when a slimmer cached copy lacked it.
  final String? deliveryPin;

  /// `send` | `receive` for parcel orders, null for food orders.
  final String? parcelDirection;

  /// Receive parcels only — see [OrderCollection].
  final OrderCollection? collection;

  /// When the rider's wait period at the drop-off location expires. Comes
  /// from the tracking endpoint / realtime updates, so it's part of
  /// [copyWith] like the other live tracking fields below.
  final DateTime? waitExpiresAt;

  /// Live straight-line distance, in metres, between the rider and the
  /// delivery address. Comes from the tracking endpoint / realtime updates.
  final double? arrivalDistanceMetres;

  /// Live rider position — only ever set from a realtime `rider.location`
  /// event, never from `fromJson`; not part of any REST payload.
  final RiderLocation? riderLocation;

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
    this.requiresPayment,
    this.deliveryInstructions,
    this.estimatedDelivery,
    this.estimatedPrepMinutes,
    this.driverName,
    this.driverPhone,
    this.driverPhotoUrl,
    this.driverVehicleType,
    this.driverPlateNumber,
    this.driverRating,
    this.driverReviewCount,
    this.driverDeliveriesCompleted,
    this.riderLocation,
    this.deliveryPin,
    this.parcelDirection,
    this.collection,
    this.waitExpiresAt,
    this.arrivalDistanceMetres,
  });

  bool get isReceiveParcel => parcelDirection == 'receive';

  /// Show "Pay Now". A mobile-money `pending` is not a failure — it stays
  /// payable until the gateway settles it.
  bool get needsPayment =>
      status != OrderStatus.cancelled &&
      paymentStatus != PaymentStatus.paid &&
      (requiresPayment ?? true);

  int get totalItems => items.fold(0, (sum, e) => sum + e.quantity);

  /// Applies the lightweight fields returned by the tracking endpoint
  /// (`GET customer/orders/:id/track`) on top of a fully-loaded order,
  /// preserving items/totals/address that the track response doesn't
  /// include. Also used to merge in a realtime `order.status`/`rider.location`
  /// event — never passes `riderLocation:` itself, so a REST-driven refresh
  /// never wipes out a rider position a socket event just set.
  ConsumerOrder copyWith({
    String? id,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    bool? requiresPayment,
    int? estimatedPrepMinutes,
    DateTime? estimatedDelivery,
    String? driverName,
    String? driverPhone,
    String? driverPhotoUrl,
    String? driverVehicleType,
    String? driverPlateNumber,
    double? driverRating,
    int? driverReviewCount,
    int? driverDeliveriesCompleted,
    RiderLocation? riderLocation,
    DateTime? waitExpiresAt,
    double? arrivalDistanceMetres,
    String? deliveryPin,
    String? parcelDirection,
    OrderCollection? collection,
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
      requiresPayment: requiresPayment ?? this.requiresPayment,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      estimatedPrepMinutes: estimatedPrepMinutes ?? this.estimatedPrepMinutes,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverPhotoUrl: driverPhotoUrl ?? this.driverPhotoUrl,
      driverVehicleType: driverVehicleType ?? this.driverVehicleType,
      driverPlateNumber: driverPlateNumber ?? this.driverPlateNumber,
      driverRating: driverRating ?? this.driverRating,
      driverReviewCount: driverReviewCount ?? this.driverReviewCount,
      driverDeliveriesCompleted:
          driverDeliveriesCompleted ?? this.driverDeliveriesCompleted,
      riderLocation: riderLocation ?? this.riderLocation,
      deliveryPin: this.deliveryPin ?? deliveryPin,
      parcelDirection: parcelDirection ?? this.parcelDirection,
      collection: collection ?? this.collection,
      waitExpiresAt: waitExpiresAt ?? this.waitExpiresAt,
      arrivalDistanceMetres: arrivalDistanceMetres ?? this.arrivalDistanceMetres,
    );
  }

  factory ConsumerOrder.fromJson(Map<String, dynamic> json) {
    final vendor = json['vendor'] as Map<String, dynamic>?;
    final delivery = json['delivery'] as Map<String, dynamic>?;
    final payment = json['payment'] as Map<String, dynamic>?;
    final totals = json['totals'] as Map<String, dynamic>?;
    final rider = json['rider'] as Map<String, dynamic>?;
    final stops = json['stops'] as List<dynamic>?;
    final firstStop = stops != null && stops.isNotEmpty && stops.first is Map
        ? stops.first as Map<String, dynamic>
        : null;

    final order = ConsumerOrder(
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
      status: orderStatusFromString(json['status'] as String? ?? ''),
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
      driverPhotoUrl: JsonUtils.asStringOrNull(rider?['photo_url']),
      driverVehicleType: JsonUtils.asStringOrNull(
        rider?['vehicle_type_label'] ?? rider?['vehicle_type'],
      ),
      driverPlateNumber: JsonUtils.asStringOrNull(rider?['plate_number']),
      driverRating: JsonUtils.firstDoubleOrNull(rider, const ['rating']),
      driverReviewCount: rider?['review_count'] == null
          ? null
          : JsonUtils.asInt(rider!['review_count']),
      driverDeliveriesCompleted: rider?['deliveries_completed'] == null
          ? null
          : JsonUtils.asInt(rider!['deliveries_completed']),
      paymentMethod: payment?['method'] as String? ?? json['payment_method'] as String? ?? '',
      paymentStatus: _paymentStatusFromString(
          payment?['status'] as String? ?? json['payment_status'] as String?),
      requiresPayment: payment?['requires_payment'] == null
          ? null
          : JsonUtils.asBool(payment!['requires_payment']),
      deliveryPin: (delivery?['pin'] ??
              json['delivery_pin'] ??
              firstStop?['delivery_pin'])
          ?.toString(),
      parcelDirection: json['type'] == 'parcel' || json['direction'] != null
          ? (json['direction']?.toString() ?? 'send')
          : null,
      collection: OrderCollection.fromOrderJson(json),
      waitExpiresAt: DateTime.tryParse(
          (json['wait_expires_at'] ?? delivery?['wait_expires_at']) as String? ?? ''),
      arrivalDistanceMetres:
          (json['arrival_distance_metres'] as num?)?.toDouble() ??
              (rider?['arrival_distance_metres'] as num?)?.toDouble(),
    );
    if (totals != null) {
      assert(debugCheckTotalsIdentity(
        subtotal: order.subtotal,
        discount: order.discount,
        deliveryFee: order.deliveryFee,
        serviceFee: order.serviceFee,
        total: order.total,
      ));
    }
    return order;
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
        'delivery_pin': deliveryPin,
        'wait_expires_at': waitExpiresAt?.toIso8601String(),
        'arrival_distance_metres': arrivalDistanceMetres,
      };
}
