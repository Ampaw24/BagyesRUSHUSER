import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/utils/lat_lng_tween.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/rider_location.dart';

/// Live rider position on Google's standard map style (street names and
/// points of interest stay readable), animating the marker between fixes
/// (rather than snapping) and rotating it using [RiderLocation.heading].
/// Gaps between updates can be a few seconds — a fix is only sent once the
/// rider has actually moved.
class TrackingLiveMap extends StatefulWidget {
  const TrackingLiveMap({super.key, required this.riderLocation});

  final RiderLocation riderLocation;

  @override
  State<TrackingLiveMap> createState() => _TrackingLiveMapState();
}

class _TrackingLiveMapState extends State<TrackingLiveMap>
    with SingleTickerProviderStateMixin {
  static const _moveDuration = Duration(milliseconds: 1500);

  /// Logical-pixel size of the rider marker; matches the parcel rider map.
  static const _markerSize = 30.0;

  final Completer<GoogleMapController> _controller = Completer();
  BitmapDescriptor? _markerIcon;

  late AnimationController _animationController;
  late LatLng _displayedPosition;
  late double _displayedRotation;
  LatLngTween? _positionTween;
  Tween<double>? _rotationTween;

  @override
  void initState() {
    super.initState();
    _displayedPosition = LatLng(
      widget.riderLocation.latitude,
      widget.riderLocation.longitude,
    );
    _displayedRotation = widget.riderLocation.heading ?? 0;
    _animationController = AnimationController(
      vsync: this,
      duration: _moveDuration,
    )..addListener(_onAnimationTick);
    BitmapDescriptor.asset(
      const ImageConfiguration(),
      'assets/delivery_marker.png',
      width: _markerSize,
      height: _markerSize,
    ).then((icon) {
      if (mounted) setState(() => _markerIcon = icon);
    });
  }

  @override
  void didUpdateWidget(covariant TrackingLiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.riderLocation;
    final previous = oldWidget.riderLocation;
    if (next.latitude == previous.latitude &&
        next.longitude == previous.longitude) {
      return;
    }
    _positionTween = LatLngTween(
      begin: _displayedPosition,
      end: LatLng(next.latitude, next.longitude),
    );
    _rotationTween = Tween<double>(
      begin: _displayedRotation,
      end: next.heading ?? _displayedRotation,
    );
    _animationController
      ..reset()
      ..forward();
  }

  void _onAnimationTick() {
    final positionTween = _positionTween;
    final rotationTween = _rotationTween;
    if (positionTween == null || rotationTween == null) return;
    final t = _animationController.value;
    setState(() {
      _displayedPosition = positionTween.transform(t);
      _displayedRotation = rotationTween.transform(t);
    });
    _controller.future.then((controller) {
      if (mounted) {
        controller.animateCamera(CameraUpdate.newLatLng(_displayedPosition));
      }
    });
  }

  @override
  void dispose() {
    _animationController
      ..removeListener(_onAnimationTick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final radius = BorderRadius.circular(w * 0.05);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: w * 0.52,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _displayedPosition,
                  zoom: 16,
                ),
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                markers: {
                  Marker(
                    markerId: const MarkerId('rider'),
                    position: _displayedPosition,
                    rotation: _displayedRotation,
                    anchor: const Offset(0.5, 0.5),
                    flat: true,
                    icon: _markerIcon ?? BitmapDescriptor.defaultMarker,
                  ),
                },
                onMapCreated: (controller) {
                  if (!_controller.isCompleted) _controller.complete(controller);
                },
              ),
              Positioned(
                top: w * 0.03,
                left: w * 0.03,
                child: const _LiveChip(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Live tracking" pill with a pulsing dot, floated over the map.
class _LiveChip extends StatefulWidget {
  const _LiveChip();

  @override
  State<_LiveChip> createState() => _LiveChipState();
}

class _LiveChipState extends State<_LiveChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.3,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final dot = w * 0.022;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: w * 0.015),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.12),
            blurRadius: w * 0.025,
            offset: Offset(0, w * 0.006),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _pulse,
            child: Container(
              width: dot,
              height: dot,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: w * 0.015),
          Text(
            'Live tracking',
            style: TextStyle(
              fontSize: w * 0.029,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
