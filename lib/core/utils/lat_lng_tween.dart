import 'package:flutter/animation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Linearly interpolates between two [LatLng] points.
///
/// `google_maps_flutter` ships no animatable `LatLng`, so a marker moved by
/// simply re-setting its `position` jumps between fixes. Drive this with an
/// `AnimationController` to animate a marker smoothly between two readings
/// instead — see `_RiderMapSection` in `order_tracking_view.dart`.
class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng super.begin, required LatLng super.end});

  @override
  LatLng lerp(double t) => LatLng(
        lerpDouble(begin!.latitude, end!.latitude, t),
        lerpDouble(begin!.longitude, end!.longitude, t),
      );

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
