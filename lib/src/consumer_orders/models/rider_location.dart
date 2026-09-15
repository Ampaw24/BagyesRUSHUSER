import 'package:bagyesrushappusernew/core/services/realtime_events.dart';

/// The trimmed, UI-facing projection of a `rider.location` realtime event
/// that lives on [ConsumerOrder] — just what the tracking map needs for
/// marker position/rotation/animation and staleness checks. Deliberately
/// excludes [RiderLocationEvent]'s admin-oriented fields (accuracy, online
/// flag, rider name/photo/vehicle) — `ConsumerOrder` already carries
/// driver name/phone separately.
class RiderLocation {
  const RiderLocation({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speedKph,
    this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final double? heading;
  final double? speedKph;
  final DateTime? recordedAt;

  factory RiderLocation.fromEvent(RiderLocationEvent event) => RiderLocation(
        latitude: event.latitude,
        longitude: event.longitude,
        heading: event.heading,
        speedKph: event.speedKph,
        recordedAt: event.recordedAt,
      );
}
