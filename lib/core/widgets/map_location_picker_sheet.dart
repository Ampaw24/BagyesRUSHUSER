import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../constant/app_theme.dart';
import '../../core/utils/app_logger.dart';
import '../enums/map_style_type.dart';
import '../services/map_style_service.dart';
import '../services/places_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry point
// ─────────────────────────────────────────────────────────────────────────────

/// Full-screen interactive map picker.
///
/// The user can:
///   • drag the map to reposition the pin
///   • type in the search bar to get autocomplete suggestions (with geocoding fallback)
///   • tap a suggestion to animate the map + pin to that location
///   • tap "My Location" to jump to their GPS position
///   • press "Confirm Location" to return the selected (LatLng, address)
class MapLocationPickerSheet extends StatefulWidget {
  final String title;
  final LatLng? initialPosition;
  final void Function(LatLng latLng, String address) onConfirm;

  const MapLocationPickerSheet({
    super.key,
    required this.title,
    required this.onConfirm,
    this.initialPosition,
  });

  @override
  State<MapLocationPickerSheet> createState() => _MapLocationPickerSheetState();
}

class _MapLocationPickerSheetState extends State<MapLocationPickerSheet>
    with SingleTickerProviderStateMixin {
  // ── Constants ──────────────────────────────────────────────────────────────
  static const _accraFallback = LatLng(5.6037, -0.1870);
  static const _defaultZoom = 15.0;

  // ── Map controller ─────────────────────────────────────────────────────────
  final Completer<GoogleMapController> _mapController = Completer();

  // ── State ──────────────────────────────────────────────────────────────────
  late LatLng _center;
  String _address = '';
  bool _isReverseGeocoding = false;
  bool _isLocating = false;
  bool _isCameraMoving = false;
  String? _mapStyle;

  // ── Pin animation ──────────────────────────────────────────────────────────
  late final AnimationController _pinAnim;
  late final Animation<double> _elevation;

  // ── Autocomplete ───────────────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  List<PlacePrediction> _predictions = [];
  bool _showPredictions = false;
  bool _isSearching = false;
  Timer? _debounce;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _pinAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 500),
    );
    _elevation = CurvedAnimation(
      parent: _pinAnim,
      curve: Curves.easeOut,
      reverseCurve: Curves.elasticOut,
    );

    _center = widget.initialPosition ?? _accraFallback;
    if (widget.initialPosition != null) {
      _reverseGeocode(_center);
    }
    _searchCtrl.addListener(_onSearchChanged);
    MapStyleService.load(MapStyleType.silver).then((s) {
      if (mounted) setState(() => _mapStyle = s);
    });
  }

  @override
  void dispose() {
    _pinAnim.dispose();
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Address reverse-geocoding ──────────────────────────────────────────────

  Future<void> _reverseGeocode(LatLng position) async {
    setState(() => _isReverseGeocoding = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;
      final place = placemarks.isNotEmpty ? placemarks.first : null;
      setState(() {
        _address = place != null
            ? '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'
                .replaceAll(RegExp(r'^,\s*|,\s*$'), '')
                .replaceAll(RegExp(r',\s*,'), ',')
            : '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _address =
              '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
        });
      }
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  // ── Camera events ──────────────────────────────────────────────────────────

  void _onCameraMove(CameraPosition position) {
    _center = position.target;
    if (!_isCameraMoving) {
      setState(() => _isCameraMoving = true);
      HapticFeedback.lightImpact();
      _pinAnim.forward();
    }
  }

  void _onCameraIdle() {
    setState(() => _isCameraMoving = false);
    HapticFeedback.mediumImpact();
    _pinAnim.reverse();
    _reverseGeocode(_center);
  }

  // ── GPS ────────────────────────────────────────────────────────────────────

  Future<void> _goToMyLocation() async {
    setState(() => _isLocating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      appLogger.i(
        '[Location] Map picker GPS — '
        'lat: ${position.latitude}, lng: ${position.longitude}, '
        'accuracy: ${position.accuracy.toStringAsFixed(1)} m',
      );
      final latLng = LatLng(position.latitude, position.longitude);
      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, _defaultZoom),
      );
    } on LocationServiceDisabledException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location services disabled. Enable GPS and try again.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not get your location. Try dragging the map.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // ── Autocomplete ───────────────────────────────────────────────────────────

  void _onSearchChanged() {
    _debounce?.cancel();
    final text = _searchCtrl.text.trim();

    if (text.isEmpty) {
      setState(() {
        _predictions = [];
        _showPredictions = false;
        _isSearching = false;
      });
      return;
    }

    // Show loading state immediately so user knows something is happening.
    setState(() {
      _isSearching = true;
      _showPredictions = true;
      _predictions = [];
    });

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      // 1. Try Google Places autocomplete first.
      var results = await PlacesService.autocomplete(
        text,
        locationBias: _center,
      );

      // 2. Fallback: if Places API returned nothing (key missing / quota),
      //    try native geocoding so the feature works without a Places key.
      if (results.isEmpty) {
        try {
          final locations = await locationFromAddress(text);
          results = locations.take(5).map((loc) {
            return PlacePrediction(
              placeId: '${loc.latitude},${loc.longitude}',
              description: text,
            );
          }).toList();
        } catch (_) {
          // Geocoding also failed — results stays empty.
        }
      }

      if (mounted) {
        setState(() {
          _predictions = results;
          _isSearching = false;
          // Keep dropdown open to show results or "no results" message.
          _showPredictions = true;
        });
      }
    });
  }

  Future<void> _selectPrediction(PlacePrediction prediction) async {
    _searchFocus.unfocus();
    setState(() {
      _showPredictions = false;
      _searchCtrl.text = '';
      _address = prediction.description;
    });

    LatLng? latLng;

    // 1. Try Google Places details first.
    if (!prediction.placeId.contains(',')) {
      latLng = await PlacesService.fetchPlaceLatLng(prediction.placeId);
    }

    // 2. Fallback: placeId is a "lat,lng" string (set by geocoding fallback above).
    if (latLng == null && prediction.placeId.contains(',')) {
      try {
        final parts = prediction.placeId.split(',');
        latLng = LatLng(double.parse(parts[0]), double.parse(parts[1]));
      } catch (_) {}
    }

    // 3. Last resort: geocode the description text.
    if (latLng == null) {
      try {
        final locations = await locationFromAddress(prediction.description);
        if (locations.isNotEmpty) {
          latLng = LatLng(locations.first.latitude, locations.first.longitude);
        }
      } catch (_) {}
    }

    if (latLng == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not locate that place. Try another.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    // Move the map — _onCameraIdle will update _center and reverse-geocode.
    _center = latLng;
    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, _defaultZoom),
    );
  }

  // ── Confirm ────────────────────────────────────────────────────────────────

  void _confirm() {
    if (_address.isEmpty) return;
    Navigator.of(context).pop();
    widget.onConfirm(_center, _address);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return PopScope(
      canPop: false,
      child: Container(
        height: screenHeight * 0.93,
        decoration: const BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHandle(),
            _buildHeader(context),
            _buildSearchBar(),
            if (_showPredictions) _buildPredictionsList(),
            Expanded(child: _buildMap()),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
          fontFamily: 'Mukta',
        ),
        decoration: InputDecoration(
          hintText: 'Search streets, areas, landmarks…',
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textHint),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {
                      _predictions = [];
                      _showPredictions = false;
                      _isSearching = false;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceVariant,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionsList() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: AppColors.scaffold,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _isSearching
            // Loading state
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Searching…',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : _predictions.isEmpty
                // No results state
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 18, color: AppColors.textHint),
                        SizedBox(width: 10),
                        Text(
                          'No places found. Try a different search.',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  )
                // Results list
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: _predictions.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (_, i) {
                      final p = _predictions[i];
                      return InkWell(
                        onTap: () => _selectPrediction(p),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  p.description,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.textPrimary,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildMap() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // ── Map ──────────────────────────────────────────────────────────────
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: _defaultZoom,
          ),
          style: _mapStyle,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onMapCreated: (controller) => _mapController.complete(controller),
          onCameraMove: _onCameraMove,
          onCameraIdle: _onCameraIdle,
          onTap: (_) {
            _searchFocus.unfocus();
            setState(() => _showPredictions = false);
          },
        ),

        // ── Animated map pin ─────────────────────────────────────────────────
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _elevation,
            builder: (_, __) {
              final t = _elevation.value;
              final liftY = t * -16.0;
              final scale = 1.0 + t * 0.12;
              final groundScaleX = 1.0 - t * 0.6;
              final groundOpacity = (0.22 - t * 0.12).clamp(0.0, 1.0);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Pin ────────────────────────────────────────────────────
                  Transform.translate(
                    offset: Offset(0, liftY),
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.bottomCenter,
                      child: CustomPaint(
                        size: const Size(
                          _MapPinPainter.pinWidth,
                          _MapPinPainter.pinHeight,
                        ),
                        painter: _MapPinPainter(
                          color: AppColors.primary,
                          elevation: t,
                        ),
                      ),
                    ),
                  ),

                  // ── Ground shadow ──────────────────────────────────────────
                  Transform.scale(
                    scaleX: groundScaleX,
                    child: Container(
                      width: 16,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: groundOpacity),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // ── GPS FAB ───────────────────────────────────────────────────────────
        Positioned(
          right: 14,
          bottom: 14,
          child: FloatingActionButton.small(
            heroTag: 'map_gps_fab',
            backgroundColor: AppColors.scaffold,
            elevation: 4,
            onPressed: _isLocating ? null : _goToMyLocation,
            child: _isLocating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.my_location_rounded,
                    color: AppColors.primary, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final hasAddress = _address.isNotEmpty;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.scaffold,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address preview
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: AppColors.success, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _isReverseGeocoding
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.textHint),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Detecting address…',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textHint),
                          ),
                        ],
                      )
                    : Text(
                        hasAddress
                            ? _address
                            : 'Move the map to pick a location',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: hasAddress
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (hasAddress && !_isReverseGeocoding) ? _confirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Confirm Location',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map pin painter — 3-D glossy sphere + thin needle
// ─────────────────────────────────────────────────────────────────────────────

/// Draws a 3-D glossy sphere on a thin needle — inspired by the classic
/// Google-style notification pin.
///
/// Visual layers (bottom → top):
///   1. Outer glow / halo  — soft coloured bloom, intensifies when lifted
///   2. Sphere drop shadow — shifts down as the pin lifts
///   3. Sphere fill        — radial gradient (bright top-left → dark bottom-right)
///   4. Soft gloss halo    — large diffuse white oval (depth illusion)
///   5. Specular highlight — small bright white oval (sharp light reflection)
///   6. White centre dot   — the "marker" inside the sphere
///   7. Thin needle        — dark-tinted colour, with a metallic left-edge shine
class _MapPinPainter extends CustomPainter {
  final Color color;
  final double elevation;

  const _MapPinPainter({required this.color, required this.elevation});

  // Only the canvas size is declared here — everything inside paint() is
  // derived from size.width / size.height so it scales to any dimension.
  static const double pinWidth  = 46.0;
  static const double pinHeight = 66.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w  = size.width;
    final h  = size.height;
    final cx = w / 2;

    // Sphere occupies ~37% of the width as its radius.
    final r  = w * 0.37;
    // Centre y: leave ~8% of height as breathing room for the halo at the top.
    final cy = r + h * 0.08;

    // ── 1. Outer glow / halo ──────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      r + w * 0.10,
      Paint()
        ..color = color.withValues(alpha: 0.12 + elevation * 0.06)
        ..maskFilter = MaskFilter.blur(
            BlurStyle.normal, w * 0.20 + elevation * w * 0.09),
    );

    // ── 2. Sphere drop shadow ─────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx + w * 0.04, cy + h * 0.06 + elevation * h * 0.08),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22 + elevation * 0.08)
        ..maskFilter = MaskFilter.blur(
            BlurStyle.normal, w * 0.14 + elevation * w * 0.11),
    );

    // ── 3. Sphere — radial gradient (light source: top-left) ─────────────────
    final sphereRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.40, -0.45),
          radius: 1.0,
          colors: [
            Color.lerp(color, Colors.white, 0.32)!,
            color,
            Color.lerp(color, Colors.black, 0.28)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(sphereRect),
    );

    // ── 4. Soft gloss halo ────────────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - r * 0.24, cy - r * 0.32),
        width:  r * 1.00,
        height: r * 0.58,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.11),
    );

    // ── 5. Specular highlight ─────────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - r * 0.28, cy - r * 0.40),
        width:  r * 0.40,
        height: r * 0.22,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.52),
    );

    // ── 6. White centre dot ───────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy + r * 0.06),
      r * 0.20,
      Paint()..color = Colors.white.withValues(alpha: 0.88),
    );

    // ── 7. Thin needle ────────────────────────────────────────────────────────
    final baseY      = cy + r - h * 0.015;
    final halfW      = w * 0.065;
    final tipY       = h;
    final needleColor = Color.lerp(color, Colors.black, 0.32)!;

    // Needle shadow
    canvas.drawPath(
      (Path()
        ..moveTo(cx - halfW, baseY)
        ..lineTo(cx + halfW, baseY)
        ..lineTo(cx, tipY)
        ..close())
          .shift(Offset(w * 0.035, h * 0.038)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.07),
    );

    // Needle fill
    canvas.drawPath(
      Path()
        ..moveTo(cx - halfW, baseY)
        ..lineTo(cx + halfW, baseY)
        ..lineTo(cx, tipY)
        ..close(),
      Paint()..color = needleColor,
    );

    // Needle left-edge metallic shine
    canvas.drawPath(
      Path()
        ..moveTo(cx - halfW + w * 0.02, baseY)
        ..lineTo(cx - w * 0.02, baseY + h * 0.08)
        ..lineTo(cx - w * 0.02, tipY - h * 0.03)
        ..lineTo(cx - halfW + w * 0.02, baseY)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(_MapPinPainter old) =>
      old.color != color || old.elevation != elevation;
}
