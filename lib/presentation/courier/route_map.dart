import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../constant/config.dart';
import '../../core/enums/map_style_type.dart';
import '../../core/services/map_style_service.dart';

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
  double cameraZoom = 13;
  double cameraTilt = 30;
  double cameraBearing = 10;
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
    CameraPosition initialLocation = CameraPosition(
      zoom: cameraZoom,
      bearing: cameraBearing,
      tilt: cameraTilt,
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
    setPolylines();
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
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
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
    if (result.points.isNotEmpty) {
      // loop through all PointLatLng points and convert them
      // to a list of LatLng, required by the Polyline
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }

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
  }
}

