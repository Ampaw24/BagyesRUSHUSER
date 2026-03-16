import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import '../../../../constant/key.dart';

class LocationPickerStep extends StatefulWidget {
  final String title;
  final String subtitle;
  final LatLng? selectedLatLng;
  final String selectedAddress;
  final void Function(LatLng latLng, String address) onLocationSelected;

  static const _fallbackPosition = LatLng(5.6037, -0.1870); // Accra, Ghana

  const LocationPickerStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selectedLatLng,
    required this.selectedAddress,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerStep> createState() => _LocationPickerStepState();
}

class _LocationPickerStepState extends State<LocationPickerStep> {
  final Completer<GoogleMapController> _mapController = Completer();
  bool _isLocating = false;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;

    return Column(
      children: [
        // ── Map preview ──────────────────────────────────────────────────────
        SizedBox(
          height: h * 0.38,
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(w * 0.06),
              bottomRight: Radius.circular(w * 0.06),
            ),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.selectedLatLng ??
                    LocationPickerStep._fallbackPosition,
                zoom: 14,
              ),
              markers: widget.selectedLatLng != null
                  ? {
                      Marker(
                        markerId: const MarkerId('selected'),
                        position: widget.selectedLatLng!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                      ),
                    }
                  : {},
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              onMapCreated: (ctrl) {
                if (!_mapController.isCompleted) _mapController.complete(ctrl);
              },
            ),
          ),
        ),

        // ── Controls ─────────────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              w * 0.05,
              w * 0.05,
              w * 0.05,
              w * 0.04,
            ),
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: w * 0.05,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: w * 0.01),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: w * 0.033,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: w * 0.05),

              // ── Action buttons ────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: HugeIcons.strokeRoundedMapsLocation01,
                      label: 'My Location',
                      isLoading: _isLocating,
                      onTap: _useCurrentLocation,
                    ),
                  ),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: _ActionButton(
                      icon: HugeIcons.strokeRoundedSearch01,
                      label: 'Search Address',
                      isPrimary: true,
                      onTap: () => _openPlacePicker(context),
                    ),
                  ),
                ],
              ),

              SizedBox(height: w * 0.05),

              // ── Selected address ──────────────────────────────────────────
              _SelectedAddressCard(
                address: widget.selectedAddress,
                w: w,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _useCurrentLocation() async {
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

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final address = place != null
          ? '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'
              .replaceAll(RegExp(r'^,\s*|,\s*$'), '')
              .replaceAll(RegExp(r',\s*,'), ',')
          : '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';

      final latLng = LatLng(position.latitude, position.longitude);
      widget.onLocationSelected(latLng, address);

      final ctrl = await _mapController.future;
      ctrl.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    } catch (_) {
      // Silently ignore — user will see empty state and can search manually.
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _openPlacePicker(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlacePicker(
          apiKey: googleMapKey,
          initialPosition: widget.selectedLatLng ??
              LocationPickerStep._fallbackPosition,
          useCurrentLocation: true,
          selectInitialPosition: true,
          onPlacePicked: (result) {
            Navigator.pop(context);
            if (result.geometry == null) return;
            final latLng = LatLng(
              result.geometry!.location.lat,
              result.geometry!.location.lng,
            );
            final address = result.formattedAddress ?? '';
            widget.onLocationSelected(latLng, address);
          },
          selectedPlaceWidgetBuilder:
              (_, selectedPlace, state, isSearchBarFocused) {
            if (isSearchBarFocused) return const SizedBox.shrink();
            return FloatingCard(
              bottomPosition: 0,
              leftPosition: 0,
              rightPosition: 0,
              width: double.infinity,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: state == SearchingState.Searching
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, selectedPlace),
                        child: const Text('Confirm This Location'),
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: w * 0.04,
          horizontal: w * 0.03,
        ),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.03),
          border: Border.all(
            color: isPrimary ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: w * 0.04,
                height: w * 0.04,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isPrimary ? Colors.white : AppColors.primary,
                ),
              )
            else
              HugeIcon(
                icon: icon,
                color: isPrimary ? Colors.white : AppColors.textSecondary,
                size: w * 0.045,
              ),
            SizedBox(width: w * 0.02),
            Text(
              label,
              style: TextStyle(
                fontSize: w * 0.033,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Selected address card ─────────────────────────────────────────────────────

class _SelectedAddressCard extends StatelessWidget {
  final String address;
  final double w;

  const _SelectedAddressCard({required this.address, required this.w});

  @override
  Widget build(BuildContext context) {
    final hasAddress = address.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: hasAddress
            ? AppColors.success.withValues(alpha: 0.06)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(
          color: hasAddress
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedLocation01,
            color: hasAddress ? AppColors.success : AppColors.textHint,
            size: w * 0.05,
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: hasAddress
                ? Text(
                    address,
                    style: TextStyle(
                      fontSize: w * 0.035,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  )
                : Text(
                    'No location selected yet.\nUse "My Location" or search for an address.',
                    style: TextStyle(
                      fontSize: w * 0.033,
                      color: AppColors.textHint,
                      height: 1.4,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
