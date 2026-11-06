import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import '../../../../core/utils/location_helper.dart';
import '../../../../core/widgets/map_location_picker_sheet.dart';
import 'package:gopady/constant/app_tokens.dart';
import 'parcel_ui.dart';

class LocationPickerStep extends StatefulWidget {
  final String title;
  final String subtitle;
  final LatLng? selectedLatLng;
  final String selectedAddress;
  final void Function(LatLng latLng, String address) onLocationSelected;

  /// Extra content rendered below the selected-address card.
  final Widget? footer;

  const LocationPickerStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selectedLatLng,
    required this.selectedAddress,
    required this.onLocationSelected,
    this.footer,
  });

  @override
  State<LocationPickerStep> createState() => _LocationPickerStepState();
}

class _LocationPickerStepState extends State<LocationPickerStep> {
  bool _isLocating = false;

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final result = await LocationHelper.getCurrentLocation(
        accuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      switch (result.status) {
        case LocationStatus.success:
          final position = result.position!;
          final latLng = LatLng(position.latitude, position.longitude);
          widget.onLocationSelected(latLng, result.address);
          break;
        case LocationStatus.serviceDisabled:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location services are disabled. Enable GPS and try again.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          break;
        case LocationStatus.permissionDeniedForever:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Location permission permanently denied. Enable it in Settings.',
              ),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Settings',
                onPressed: LocationHelper.openAppSettings,
              ),
            ),
          );
          break;
        case LocationStatus.permissionDenied:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission denied. Please allow access in Settings.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          break;
        case LocationStatus.timeout:
        case LocationStatus.error:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not detect location. Try searching for your address.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          break;
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return ListView(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.02, w * 0.05, w * 0.08),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        ParcelStepHeader(title: widget.title, subtitle: widget.subtitle),
        const ParcelGap(0.06),
        _SearchBar(onTap: () => _openAddressSearch(context)),
        const ParcelGap(0.03),
        _CurrentLocationRow(isLoading: _isLocating, onTap: _useCurrentLocation),
        const ParcelGap(0.05),
        AnimatedSwitcher(
          duration: AppMotion.standard,
          child: widget.selectedAddress.isNotEmpty
              ? _SelectedAddressCard(
                  key: const ValueKey('selected'),
                  label: widget.title,
                  address: widget.selectedAddress,
                  onChange: () => _openAddressSearch(context),
                )
              : const ParcelNote(
                  key: ValueKey('empty'),
                  icon: HugeIcons.strokeRoundedLocation01,
                  message:
                      'No location yet — search for an address or use '
                      'where you are now.',
                ),
        ),
        if (widget.footer != null) ...[const ParcelGap(0.06), widget.footer!],
      ],
    );
  }

  void _openAddressSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => MapLocationPickerSheet(
        title: widget.title,
        initialPosition: widget.selectedLatLng,
        onConfirm: (latLng, address) {
          widget.onLocationSelected(latLng, address);
        },
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final radius = BorderRadius.circular(w * 0.035);
    return Semantics(
      button: true,
      label: 'Search for an address',
      child: Material(
        color: AppColors.surface,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.04,
              vertical: w * 0.04,
            ),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  color: AppColors.textPrimary,
                  size: w * 0.05,
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: Text(
                    'Search street, area or landmark',
                    style: TextStyle(
                      fontSize: w * 0.036,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedMaps,
                  color: AppColors.textSecondary,
                  size: w * 0.045,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Current location row ──────────────────────────────────────────────────────

class _CurrentLocationRow extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _CurrentLocationRow({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final radius = BorderRadius.circular(w * 0.035);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: radius,
        onTap: isLoading ? null : onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: w * 0.02),
          child: Row(
            children: [
              SizedBox(
                width: w * 0.11,
                height: w * 0.11,
                child: isLoading
                    ? Padding(
                        padding: EdgeInsets.all(w * 0.028),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const ParcelIconBadge(
                        icon: HugeIcons.strokeRoundedGps01,
                        active: true,
                      ),
              ),
              SizedBox(width: w * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoading ? 'Finding you…' : 'Use my current location',
                      style: TextStyle(
                        fontSize: w * 0.036,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: w * 0.004),
                    Text(
                      'Detect it automatically with GPS',
                      style: TextStyle(
                        fontSize: w * 0.03,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: AppColors.textHint,
                size: w * 0.045,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Selected address card ─────────────────────────────────────────────────────

class _SelectedAddressCard extends StatelessWidget {
  final String label;
  final String address;
  final VoidCallback onChange;

  const _SelectedAddressCard({
    super.key,
    required this.label,
    required this.address,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return ParcelCard(
      highlighted: true,
      child: Row(
        children: [
          const ParcelIconBadge(
            icon: HugeIcons.strokeRoundedLocation01,
            active: true,
          ),
          SizedBox(width: w * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: w * 0.026,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: w * 0.008),
                Text(
                  address,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: w * 0.035,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onChange, child: const Text('Change')),
        ],
      ),
    );
  }
}
