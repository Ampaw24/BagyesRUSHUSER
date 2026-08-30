import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../constant/config.dart';
import '../../core/enums/map_style_type.dart';
import '../../core/services/map_style_service.dart';
import '../../core/utils/app_logger.dart';

enum Trip { PICKUP, DROPOFF, WAIT }

class RouteMap extends StatefulWidget {
  final double sourceLat, sourceLang, destinationLat, destinationLang;
  const RouteMap({
    super.key,
    required this.sourceLat,
    required this.sourceLang,
    required this.destinationLat,
    required this.destinationLang,
  });
  @override
  _RouteMapState createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  static const double _initialZoom = 13;
  late LatLng sourceLocatioon;
  late LatLng destLocatioon;

  final Completer<GoogleMapController> _controller = Completer();
  // this set will hold my markers
  final Set<Marker> _markers = {};
  // this will hold the generated polylines
  final Set<Polyline> _polylines = {};
  // this will hold each polyline coordinate as Lat and Lng pairs
  List<LatLng> polylineCoordinates = [];
  // this is the key object - the PolylinePoints
  // which generates every polyline between start and finish
  late PolylinePoints polylinePoints;
  String googleAPIKey = Config.mapsApiKey;
  // for my custom icons
  BitmapDescriptor? sourceIcon;
  BitmapDescriptor? destinationIcon;
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    sourceLocatioon = LatLng(widget.sourceLat, widget.sourceLang);
    destLocatioon = LatLng(widget.destinationLat, widget.destinationLang);
    polylinePoints = PolylinePoints();
    setSourceAndDestinationIcons();
    MapStyleService.load(MapStyleType.silver)
        .then((s) { if (mounted) setState(() => _mapStyle = s); });
  }

  void setSourceAndDestinationIcons() async {
    sourceIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(devicePixelRatio: 2.5),
      'assets/pickup-marker.png',
    );
    destinationIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(devicePixelRatio: 2.5),
      'assets/delivery_marker.png',
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Placeholder camera for the first frame — onMapCreated immediately
    // fits both pickup and dropoff into view, so bearing/tilt/zoom here
    // only matter for the brief moment before that runs.
    CameraPosition initialLocation = CameraPosition(
      zoom: _initialZoom,
      target: sourceLocatioon,
    );
    return GoogleMap(
      myLocationEnabled: true,
      compassEnabled: true,
      tiltGesturesEnabled: false,
      markers: _markers,
      polylines: _polylines,
      mapType: MapType.normal,
      style: _mapStyle,
      initialCameraPosition: initialLocation,
      onMapCreated: onMapCreated,
    );
  }

  void onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
    setMapPins();
    _fitToRoute([sourceLocatioon, destLocatioon]);
    setPolylines();
  }

  LatLngBounds _boundsFor(List<LatLng> points) {
    var minLat = points.first.latitude, maxLat = points.first.latitude;
    var minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Fits the camera to [points] with padding. Deferred to the next frame —
  /// `newLatLngBounds` needs the map already laid out with a non-zero size,
  /// which isn't guaranteed yet inside `onMapCreated`.
  void _fitToRoute(List<LatLng> points) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final controller = await _controller.future;
      if (!mounted) return;
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(_boundsFor(points), 80),
      );
    });
  }

  void setMapPins() {
    setState(() {
      // source pin
      _markers.add(
        Marker(
          markerId: MarkerId('sourcePin'),
          position: sourceLocatioon,
          icon: sourceIcon ?? BitmapDescriptor.defaultMarker,
        ),
      );
      // destination pin
      _markers.add(
        Marker(
          markerId: MarkerId('destPin'),
          position: destLocatioon,
          icon: destinationIcon ?? BitmapDescriptor.defaultMarker,
        ),
      );
    });
  }

  Future<void> setPolylines() async {
    PolylineResult result;
    try {
      result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: googleAPIKey,
        request: PolylineRequest(
          origin: PointLatLng(
            sourceLocatioon.latitude,
            sourceLocatioon.longitude,
          ),
          destination: PointLatLng(
            destLocatioon.latitude,
            destLocatioon.longitude,
          ),
          mode: TravelMode.driving,
        ),
      );
    } catch (e, s) {
      // Leave the map showing just the pickup/dropoff pins rather than
      // letting a Directions API failure surface as an unhandled error.
      appLogger.e('[RouteMap] Failed to fetch route', error: e, stackTrace: s);
      return;
    }

    if (result.points.isEmpty) {
      appLogger.w(
        '[RouteMap] No route points returned — status: ${result.status}, '
        'error: ${result.errorMessage ?? 'none'}',
      );
      return;
    }

    // loop through all PointLatLng points and convert them
    // to a list of LatLng, required by the Polyline
    for (var point in result.points) {
      polylineCoordinates.add(LatLng(point.latitude, point.longitude));
    }

    if (!mounted) return;
    setState(() {
      // create a Polyline instance
      // with an id, an RGB color and the list of LatLng pairs
      Polyline polyline = Polyline(
        polylineId: PolylineId("poly"),
        width: 4,
        color: Colors.black,
        points: polylineCoordinates,
      );

      // add the constructed polyline as a set of points
      // to the polyline set, which will eventually
      // end up showing up on the map
      _polylines.add(polyline);
    });

    // The actual road route can bow outside the straight-line box between
    // pickup and dropoff (a detour, a route around water, etc.) — re-fit
    // using every point on it so the whole path stays on screen.
    _fitToRoute(polylineCoordinates);
  }
}

