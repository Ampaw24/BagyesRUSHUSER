import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import '../../../../constant/config.dart';
import '../../../../core/enums/map_style_type.dart';
import '../../../../core/services/map_style_service.dart';
import '../../../../core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/src/parcel/model/delivery_stop.dart';
import 'package:bagyesrushappusernew/src/parcel/model/rider_model.dart';
import 'rider_card.dart';

/// Shows the rider the backend matched to this delivery — there is no list
/// to pick from; the backend assigns the nearest available rider and
/// prices the quote around them, mirroring how Uber/Bolt match a driver.
///
/// A live map sits above the summary: pickup + stop pins connected by a
/// dashed route that draws itself in on arrival. The route follows actual
/// roads (fetched from the Directions API via [PolylinePoints], same as
/// [RouteMap]) instead of a straight line between pickup and each stop,
/// falling back to the straight line if that request fails. A pulsing
/// "searching" ring shows around the pickup point while the backend is
/// still matching — there's no rider GPS fix to show yet at this stage,
/// only once an order exists does [RealtimeService] start streaming a
/// real position.
class AvailableRidersStep extends StatefulWidget {
  final RiderModel? rider;
  final double distanceKm;
  final int? etaMinutes;
  final double? quotedPrice;
  final String? quoteCurrency;
  final bool isFetchingQuote;
  final String? quoteError;
  final String? noRidersMessage;
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
    required this.noRidersMessage,
    required this.onRetry,
    required this.pickupLatLng,
    required this.deliveryStops,
  });

  @override
  State<AvailableRidersStep> createState() => _AvailableRidersStepState();
}

class _AvailableRidersStepState extends State<AvailableRidersStep>
    with TickerProviderStateMixin {
  final Completer<GoogleMapController> _mapController = Completer();
  String? _mapStyle;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _stopIcon;
  late final AnimationController _pulseController;

  /// Draws the route on from pickup to the last stop over
  /// [_routeDrawDuration] instead of popping in fully formed.
  late final AnimationController _routeDrawController;
  late final Animation<double> _routeDrawCurve;
  static const _routeDrawDuration = Duration(milliseconds: 900);
  List<LatLng> _lastAnimatedRoute = const [];

  // Real road-following path from the Directions API (pickup → each stop,
  // in order), same approach as RouteMap. Empty until it resolves, so the
  // straight-line fallback shows immediately and gets replaced once ready.
  final PolylinePoints _polylinePoints = PolylinePoints();
  List<LatLng> _roadRoute = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.isFetchingQuote) _pulseController.repeat();

    _routeDrawController = AnimationController(
      vsync: this,
      duration: _routeDrawDuration,
    );
    _routeDrawCurve = CurvedAnimation(
      parent: _routeDrawController,
      curve: Curves.easeOutCubic,
    );
    _lastAnimatedRoute = _routePoints;
    _fetchRoadRoute(_lastAnimatedRoute);

    MapStyleService.load(MapStyleType.silver).then((s) {
      if (mounted) setState(() => _mapStyle = s);
    });
    _loadIcons();
  }

  // Standard Google Maps pin size — explicit width/height render the
  // 100x100 source assets at a fixed logical size regardless of device
  // pixel ratio, instead of the ~40dp they scaled to before, which made
  // them dominate a tightly-zoomed map.
  static const _markerSize = 30.0;

  Future<void> _loadIcons() async {
    final pickup = await BitmapDescriptor.asset(
      const ImageConfiguration(),
      'assets/pickup-marker.png',
      width: _markerSize,
      height: _markerSize,
    );
    final stop = await BitmapDescriptor.asset(
      const ImageConfiguration(),
      'assets/delivery_marker.png',
      width: _markerSize,
      height: _markerSize,
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

    final route = _routePoints;
    if (!_sameRoute(route, _lastAnimatedRoute)) {
      _lastAnimatedRoute = route;
      _roadRoute = []; // stale — fall back to the straight line until refetched
      _routeDrawController.forward(from: 0);
      _fetchRoadRoute(route);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _routeDrawController.dispose();
    super.dispose();
  }

  bool _sameRoute(List<LatLng> a, List<LatLng> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  List<LatLng> get _routePoints => [
        if (widget.pickupLatLng != null) widget.pickupLatLng!,
        ...widget.deliveryStops
            .where((s) => s.latLng != null)
            .map((s) => s.latLng!),
      ];

  /// The road route once it's loaded, else the straight pickup→stop line.
  List<LatLng> get _displayRoute =>
      _roadRoute.isNotEmpty ? _roadRoute : _routePoints;

  /// Fetches the real driving route through [stops] (pickup → each delivery
  /// stop, in order) from the Directions API and swaps it in for the
  /// straight-line preview. Mirrors [RouteMap.setPolylines] — on failure or
  /// an empty result it just logs and leaves the straight-line fallback in
  /// place rather than surfacing an error on this pre-booking screen.
  Future<void> _fetchRoadRoute(List<LatLng> stops) async {
    if (stops.length < 2) return;

    PolylineResult result;
    try {
      result = await _polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: Config.mapsApiKey,
        request: PolylineRequest(
          origin: PointLatLng(stops.first.latitude, stops.first.longitude),
          destination: PointLatLng(stops.last.latitude, stops.last.longitude),
          mode: TravelMode.driving,
          wayPoints: [
            for (final p in stops.sublist(1, stops.length - 1))
              PolylineWayPoint(location: '${p.latitude},${p.longitude}'),
          ],
        ),
      );
    } catch (e, s) {
      appLogger.e(
        '[AvailableRidersStep] Failed to fetch route',
        error: e,
        stackTrace: s,
      );
      return;
    }

    if (!mounted) return;

    if (result.points.isEmpty) {
      appLogger.w(
        '[AvailableRidersStep] No route points — status: ${result.status}, '
        'error: ${result.errorMessage ?? 'none'}',
      );
      return;
    }

    setState(() {
      _roadRoute =
          result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    });

    // The actual road route can bow outside the straight-line box between
    // stops (a detour, a one-way street, etc.) — re-fit using every point
    // on it plus the exact pickup/stop coordinates (the Directions API
    // snaps waypoints to the nearest road, which can drift a few metres
    // from the marker) so every pin stays on screen too, then replay the
    // draw-on reveal now that the real shape is in.
    _fitToRoute([..._roadRoute, ...stops]);
    _routeDrawController.forward(from: 0);
  }

  /// Straight-line distance in an equirectangular approximation — accurate
  /// enough over a delivery-radius span to pace the draw-on animation at a
  /// visually constant speed across segments of different lengths.
  double _approxDistance(LatLng a, LatLng b) {
    final latDelta = a.latitude - b.latitude;
    final lngDelta =
        (a.longitude - b.longitude) * math.cos(a.latitude * math.pi / 180);
    return math.sqrt(latDelta * latDelta + lngDelta * lngDelta);
  }

  LatLng _lerpLatLng(LatLng a, LatLng b, double t) => LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );

  /// Returns the prefix of [route] reached after travelling fraction [t] of
  /// its total length, with the cut point interpolated so the line's tip
  /// moves smoothly rather than jumping stop-to-stop.
  List<LatLng> _routeUpTo(List<LatLng> route, double t) {
    if (route.length < 2 || t >= 1.0) return route;
    if (t <= 0.0) return [route.first];

    final segmentLengths = <double>[
      for (var i = 0; i < route.length - 1; i++)
        _approxDistance(route[i], route[i + 1]),
    ];
    final total = segmentLengths.fold<double>(0, (sum, d) => sum + d);
    if (total == 0) return route;

    final target = total * t;
    var covered = 0.0;
    final result = <LatLng>[route.first];
    for (var i = 0; i < segmentLengths.length; i++) {
      final segLen = segmentLengths[i];
      if (covered + segLen >= target) {
        final segT = segLen == 0 ? 0.0 : (target - covered) / segLen;
        result.add(_lerpLatLng(route[i], route[i + 1], segT));
        return result;
      }
      covered += segLen;
      result.add(route[i + 1]);
    }
    return route;
  }

  void _fitToRoute(List<LatLng> points) {
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

    // Guarantee a minimum span so stops only a few hundred metres apart
    // (e.g. a 0.5km hop) don't force the camera so tight that the pin
    // icons dominate the map and the route between them gets lost.
    const minSpanDegrees = 0.01; // ~1.1km of latitude
    if (maxLat - minLat < minSpanDegrees) {
      final pad = (minSpanDegrees - (maxLat - minLat)) / 2;
      minLat -= pad;
      maxLat += pad;
    }
    if (maxLng - minLng < minSpanDegrees) {
      final pad = (minSpanDegrees - (maxLng - minLng)) / 2;
      minLng -= pad;
      maxLng += pad;
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

    // Full-bleed map with the trip/rider details floating over its bottom
    // edge as a rounded sheet — mirrors Uber/Bolt's driver-match screen
    // instead of splitting the screen into a small map + a large static
    // panel, which left almost no map visible.
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelHeight = constraints.maxHeight * 0.476;
        return Stack(
          children: [
            Positioned.fill(child: _buildMap(w, bottomInset: panelHeight)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: panelHeight),
                child: _buildInfoPanel(w),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoPanel(double w) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.scaffold,
        borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: w * 0.05,
            offset: Offset(0, -w * 0.015),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.06)),
        child: ListView(
          padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.05),
          children: [
            Center(
              child: Container(
                width: w * 0.1,
                height: w * 0.01,
                margin: EdgeInsets.only(bottom: w * 0.03),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(w * 0.01),
                ),
              ),
            ),
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
    );
  }

  Widget _buildMap(double w, {required double bottomInset}) {
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

    final routePoints = _displayRoute;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _routeDrawController]),
      builder: (context, _) {
        final drawnRoute = _routeUpTo(routePoints, _routeDrawCurve.value);
        final isDrawing = _routeDrawController.value < 1.0;

        final polylines = <Polyline>{
          if (drawnRoute.length > 1)
            Polyline(
              polylineId: const PolylineId('preview_route'),
              points: drawnRoute,
              color: AppColors.primary.withValues(alpha: 0.55),
              width: 3,
              patterns: [PatternItem.dash(16), PatternItem.gap(10)],
            ),
        };

        final circles = {
          ..._pulseCircles(pickup, _pulseController.value),
          // A small "comet head" at the growing tip while the route draws.
          if (isDrawing && drawnRoute.isNotEmpty)
            Circle(
              circleId: const CircleId('route_tip'),
              center: drawnRoute.last,
              radius: 16,
              fillColor: AppColors.primary,
              strokeColor: Colors.white,
              strokeWidth: 2,
            ),
        };

        return GoogleMap(
          initialCameraPosition: CameraPosition(target: pickup, zoom: 14),
          style: _mapStyle,
          markers: markers,
          polylines: polylines,
          circles: circles,
          // Tells the native map that the floating rider panel obscures the
          // bottom `bottomInset` px, so camera fits (and any built-in
          // controls) are computed against the actually-visible area above
          // it instead of centering the route behind the panel.
          padding: EdgeInsets.only(bottom: bottomInset),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            if (!_mapController.isCompleted) {
              _mapController.complete(controller);
            }
            _fitToRoute(_displayRoute);
            _routeDrawController.forward(from: 0);
          },
        );
      },
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
      return NoRiderAvailableCard(
        message: widget.noRidersMessage ?? 'Please try again in a moment.',
        onRetry: widget.onRetry,
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
