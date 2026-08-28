import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import '../../../../core/utils/location_helper.dart';
import '../../../../core/widgets/map_location_picker_sheet.dart';

class LocationPickerStep extends StatefulWidget {
  final String title;
  final String subtitle;
  final LatLng? selectedLatLng;
  final String selectedAddress;
  final void Function(LatLng latLng, String address) onLocationSelected;

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
                  'Location services are disabled. Enable GPS and try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          break;
        case LocationStatus.permissionDeniedForever:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Location permission permanently denied. Enable it in Settings.'),
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
                  'Location permission denied. Please allow access in Settings.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          break;
        case LocationStatus.timeout:
        case LocationStatus.error:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Could not detect location. Try searching for your address.'),
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
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.05, w * 0.05, w * 0.06),
      children: [
        // ── Header ───────────────────────────────────────────────────────────
        Text(
          widget.title,
          style: TextStyle(
            fontSize: w * 0.055,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: w * 0.015),
        Text(
          widget.subtitle,
          style: TextStyle(
            fontSize: w * 0.035,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: w * 0.06),

        // ── Action buttons ────────────────────────────────────────────────────
        _ActionButton(
          icon: HugeIcons.strokeRoundedMapsLocation01,
          label: 'Use My Current Location',
          description: 'Detect your location automatically',
          isLoading: _isLocating,
          onTap: _useCurrentLocation,
          w: w,
        ),
        SizedBox(height: w * 0.03),
        _ActionButton(
          icon: HugeIcons.strokeRoundedSearch01,
          label: 'Search for an Address',
          description: 'Type a street, area or landmark',
          isPrimary: true,
          onTap: () => _openAddressSearch(context, w),
          w: w,
        ),

        SizedBox(height: w * 0.06),

        // ── Selected address card ─────────────────────────────────────────────
        _SelectedAddressCard(
          address: widget.selectedAddress,
          latLng: widget.selectedLatLng,
          w: w,
        ),
      ],
    );
  }

  void _openAddressSearch(BuildContext context, double w) {
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

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String description;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback onTap;
  final double w;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    required this.w,
    this.isPrimary = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isPrimary ? AppColors.primary : AppColors.surfaceVariant;
    final fg = isPrimary ? Colors.white : AppColors.textPrimary;
    final sub = isPrimary
        ? Colors.white.withValues(alpha: 0.75)
        : AppColors.textSecondary;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.045,
          vertical: w * 0.04,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(w * 0.035),
          border: Border.all(
            color: isPrimary ? AppColors.primary : AppColors.border,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            if (isLoading)
              SizedBox(
                width: w * 0.055,
                height: w * 0.055,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: isPrimary ? Colors.white : AppColors.primary,
                ),
              )
            else
              Container(
                padding: EdgeInsets.all(w * 0.02),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.border.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(w * 0.02),
                ),
                child: HugeIcon(
                  icon: icon,
                  color: isPrimary ? Colors.white : AppColors.textSecondary,
                  size: w * 0.05,
                ),
              ),
            SizedBox(width: w * 0.035),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: w * 0.038,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  SizedBox(height: w * 0.005),
                  Text(
                    description,
                    style: TextStyle(fontSize: w * 0.03, color: sub),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isPrimary
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppColors.textHint,
              size: w * 0.038,
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
  final LatLng? latLng;
  final double w;

  const _SelectedAddressCard({
    required this.address,
    required this.latLng,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    final hasAddress = address.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(w * 0.045),
      decoration: BoxDecoration(
        color: hasAddress
            ? AppColors.success.withValues(alpha: 0.06)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(
          color: hasAddress
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: hasAddress
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(w * 0.022),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedLocation01,
                    color: AppColors.success,
                    size: w * 0.045,
                  ),
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location Selected',
                        style: TextStyle(
                          fontSize: w * 0.032,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                      SizedBox(height: w * 0.01),
                      Text(
                        address,
                        style: TextStyle(
                          fontSize: w * 0.035,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: w * 0.05,
                ),
              ],
            )
          : Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedMapsLocation01,
                  color: AppColors.textHint,
                  size: w * 0.05,
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: Text(
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

