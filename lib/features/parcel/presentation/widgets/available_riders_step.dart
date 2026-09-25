import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import '../../../../core/enums/map_style_type.dart';
import '../../../../core/services/map_style_service.dart';
import 'package:bagyesrushappusernew/src/parcel/model/delivery_stop.dart';
import 'package:bagyesrushappusernew/src/parcel/model/rider_model.dart';
import 'rider_card.dart';

/// Shows the rider the backend matched to this delivery — there is no list
/// to pick from; the backend assigns the nearest available rider and
/// prices the quote around them, mirroring how Uber/Bolt match a driver.
///
/// A live map sits above the summary: pickup + stop pins with a dashed
/// preview route, and a pulsing "searching" ring around the pickup point
/// while the backend is still matching — there's no rider GPS fix to show
/// yet at this stage, only once an order exists does [RealtimeService]
/// start streaming a real position.
class AvailableRidersStep extends StatefulWidget {
  final RiderModel? rider;
  final double distanceKm;
  final int? etaMinutes;
  final double? quotedPrice;
  final String? quoteCurrency;
  final bool isFetchingQuote;
  final String? quoteError;
  final VoidCallback onRetry;
  final LatLng? pickupLatLng;
  final List<DeliveryStop> deliveryStops;

  const AvailableRidersStep({
    super.key,
    required this.rider,
    required this.distanceKm,
    required this.etaMinutes,
    required this.quotedPrice,
    required this.quoteCurrency,
    required this.isFetchingQuote,
    required this.quoteError,
    required this.onRetry,
    required this.pickupLatLng,
    required this.deliveryStops,
  });

  @override
  State<AvailableRidersStep> createState() => _AvailableRidersStepState();
}

class _AvailableRidersStepState extends State<AvailableRidersStep>
    with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _mapController = Completer();
  String? _mapStyle;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _stopIcon;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.isFetchingQuote) _pulseController.repeat();

    MapStyleService.load(MapStyleType.silver).then((s) {
      if (mounted) setState(() => _mapStyle = s);
    });
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    final pickup = await BitmapDescriptor.asset(
      const ImageConfiguration(devicePixelRatio: 2.5),
      'assets/pickup-marker.png',
    );
    final stop = await BitmapDescriptor.asset(
      const ImageConfiguration(devicePixelRatio: 2.5),
      'assets/delivery_marker.png',
    );
    if (!mounted) return;
    setState(() {
      _pickupIcon = pickup;
      _stopIcon = stop;
    });
  }

  @override
  void didUpdateWidget(AvailableRidersStep old) {
    super.didUpdateWidget(old);
    if (widget.isFetchingQuote && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (!widget.isFetchingQuote && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<LatLng> get _routePoints => [
        if (widget.pickupLatLng != null) widget.pickupLatLng!,
        ...widget.deliveryStops
            .where((s) => s.latLng != null)
            .map((s) => s.latLng!),
      ];

  void _fitToRoute() {
    final points = _routePoints;
    if (points.length < 2) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final controller = await _mapController.future;
      if (!mounted) return;
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(_boundsFor(points), 72),
      );
    });
  }

  LatLngBounds _boundsFor(List<LatLng> points) {
    var minLat = points.first.latitude, maxLat = points.first.latitude;
    var minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Two rings expanding outward with a half-cycle phase offset, fading as
  /// they grow — a "searching nearby" radar effect around the pickup pin.
  Set<Circle> _pulseCircles(LatLng center, double t) {
    if (!widget.isFetchingQuote) return const {};
    Circle ring(String id, double phase) {
      final v = (t + phase) % 1.0;
      return Circle(
        circleId: CircleId(id),
        center: center,
        radius: 60 + v * 500,
        fillColor: AppColors.primary.withValues(alpha: (1 - v) * 0.14),
        strokeColor: AppColors.primary.withValues(alpha: (1 - v) * 0.35),
        strokeWidth: 1,
      );
    }

    return {ring('pulse_a', 0.0), ring('pulse_b', 0.5)};
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;

    return Column(
      children: [
        SizedBox(height: h * 0.3, child: _buildMap(w)),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.04, w * 0.05, w * 0.04),
            children: [
              Text(
                'Your Rider',
                style: TextStyle(
                  fontSize: w * 0.055,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: w * 0.025),

              _TripSummaryCard(
                distanceKm: widget.distanceKm,
                etaMinutes: widget.etaMinutes,
                quotedPrice: widget.quotedPrice,
                quoteCurrency: widget.quoteCurrency,
                isFetchingQuote: widget.isFetchingQuote,
                w: w,
              ),

              SizedBox(height: w * 0.06),

              _buildRiderSection(w),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMap(double w) {
    final pickup = widget.pickupLatLng;
    if (pickup == null) {
      return Container(color: AppColors.surfaceVariant);
    }

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('pickup'),
        position: pickup,
        icon: _pickupIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      for (final stop in widget.deliveryStops.where((s) => s.latLng != null))
        Marker(
          markerId: MarkerId('stop_${stop.id}'),
          position: stop.latLng!,
          icon: _stopIcon ?? BitmapDescriptor.defaultMarker,
        ),
    };

    final routePoints = _routePoints;
    final polylines = <Polyline>{
      if (routePoints.length > 1)
        Polyline(
          polylineId: const PolylineId('preview_route'),
          points: routePoints,
          color: AppColors.primary.withValues(alpha: 0.55),
          width: 3,
          patterns: [PatternItem.dash(16), PatternItem.gap(10)],
        ),
    };

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) => GoogleMap(
        initialCameraPosition: CameraPosition(target: pickup, zoom: 14),
        style: _mapStyle,
        markers: markers,
        polylines: polylines,
        circles: _pulseCircles(pickup, _pulseController.value),
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        onMapCreated: (controller) {
          if (!_mapController.isCompleted) _mapController.complete(controller);
          _fitToRoute();
        },
      ),
    );
  }

  Widget _buildRiderSection(double w) {
    if (widget.isFetchingQuote) {
      return _StatusMessage(
        icon: null,
        showSpinner: true,
        title: 'Finding a rider near you…',
        subtitle: 'This usually takes a few seconds.',
        w: w,
      );
    }

    if (widget.quoteError != null) {
      return _StatusMessage(
        icon: HugeIcons.strokeRoundedAlert01,
        iconColor: AppColors.error,
        title: 'Couldn\'t reach the server',
        subtitle: widget.quoteError!,
        onRetry: widget.onRetry,
        w: w,
      );
    }

    if (widget.rider == null) {
      return _StatusMessage(
        icon: HugeIcons.strokeRoundedDeliveryTruck01,
        iconColor: AppColors.textSecondary,
        title: 'No riders available nearby',
        subtitle: 'Please try again in a moment.',
        onRetry: widget.onRetry,
        w: w,
      );
    }

    return AssignedRiderCard(rider: widget.rider!);
  }
}

// ── Trip summary card ─────────────────────────────────────────────────────

class _TripSummaryCard extends StatelessWidget {
  final double distanceKm;
  final int? etaMinutes;
  final double? quotedPrice;
  final String? quoteCurrency;
  final bool isFetchingQuote;
  final double w;

  const _TripSummaryCard({
    required this.distanceKm,
    required this.etaMinutes,
    required this.quotedPrice,
    required this.quoteCurrency,
    required this.isFetchingQuote,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(w * 0.045),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(w * 0.04),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatItem(
            icon: HugeIcons.strokeRoundedMapsLocation01,
            value: '${distanceKm.toStringAsFixed(1)} km',
            label: 'Distance',
            w: w,
          ),
          _divider(w: w),
          _StatItem(
            icon: HugeIcons.strokeRoundedMoneyBag01,
            value: isFetchingQuote || quotedPrice == null
                ? '—'
                : '${quoteCurrency ?? 'GHS'} ${quotedPrice!.toStringAsFixed(0)}',
            label: 'Est. Cost',
            w: w,
          ),
          _divider(w: w),
          _StatItem(
            icon: HugeIcons.strokeRoundedClock01,
            value: isFetchingQuote || etaMinutes == null
                ? '—'
                : '$etaMinutes min',
            label: 'ETA',
            w: w,
          ),
        ],
      ),
    );
  }

  Widget _divider({required double w}) => Container(
        width: 1,
        height: w * 0.1,
        color: Colors.white.withValues(alpha: 0.25),
        margin: EdgeInsets.symmetric(horizontal: w * 0.02),
      );
}

class _StatItem extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String value;
  final String label;
  final double w;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HugeIcon(icon: icon, color: Colors.white, size: w * 0.05),
          SizedBox(height: w * 0.015),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: w * 0.033,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: w * 0.005),
          Text(
            label,
            style: TextStyle(
              fontSize: w * 0.027,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status message (loading / error / empty) ─────────────────────────────

class _StatusMessage extends StatelessWidget {
  final List<List<dynamic>>? icon;
  final Color? iconColor;
  final bool showSpinner;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;
  final double w;

  const _StatusMessage({
    required this.icon,
    this.iconColor,
    this.showSpinner = false,
    required this.title,
    required this.subtitle,
    this.onRetry,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.1),
      child: Column(
        children: [
          if (showSpinner)
            SizedBox(
              width: w * 0.09,
              height: w * 0.09,
              child: const CircularProgressIndicator(strokeWidth: 2.4),
            )
          else if (icon != null)
            HugeIcon(icon: icon!, color: iconColor ?? AppColors.textSecondary, size: w * 0.1),
          SizedBox(height: w * 0.04),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: w * 0.04,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.015),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: w * 0.032, color: AppColors.textSecondary),
          ),
          if (onRetry != null) ...[
            SizedBox(height: w * 0.04),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: w * 0.03),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: w * 0.035,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
