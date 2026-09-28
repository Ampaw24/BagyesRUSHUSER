import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import '../../../../core/utils/location_helper.dart';
import '../../../../core/widgets/map_location_picker_sheet.dart';

/// Lets a vendor re-pin their shop's coordinates from the profile editor,
/// using the same map picker / GPS lookup as the registration flow so the
/// geo-pin (used for nearby-vendor queries and delivery-radius checks) can be
/// corrected after onboarding.
///
/// Reports every pick through [onPicked] with the resolved address, which
/// callers typically copy into their address field.
class ShopLocationField extends StatefulWidget {
  final LatLng? pinned;
  final void Function(LatLng latLng, String address) onPicked;

  const ShopLocationField({
    super.key,
    required this.pinned,
    required this.onPicked,
  });

  @override
  State<ShopLocationField> createState() => _ShopLocationFieldState();
}

class _ShopLocationFieldState extends State<ShopLocationField> {
  bool _isLocating = false;

  void _openMapPicker() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => MapLocationPickerSheet(
        title: 'Business Location',
        initialPosition: widget.pinned,
        onConfirm: widget.onPicked,
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final result = await LocationHelper.getCurrentLocation(
        accuracy: LocationAccuracy.high,
      );
      if (!mounted) return;

      switch (result.status) {
        case LocationStatus.success:
          widget.onPicked(
            LatLng(result.position!.latitude, result.position!.longitude),
            result.address,
          );
          break;
        case LocationStatus.serviceDisabled:
          _showSnack('Location services disabled. Enable GPS and try again.');
          break;
        case LocationStatus.permissionDeniedForever:
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                const Text('Location permission denied. Enable it in Settings.'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: LocationHelper.openAppSettings,
            ),
          ));
          break;
        case LocationStatus.permissionDenied:
        case LocationStatus.timeout:
        case LocationStatus.error:
          _showSnack(
            'Could not detect your location. Try pinning it on the map instead.',
          );
          break;
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final pinned = widget.pinned;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Map Location *',
          style: TextStyle(
            fontSize: w * 0.032,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: w * 0.015),
        _PinStatus(pinned: pinned),
        SizedBox(height: w * 0.02),
        Row(
          children: [
            Expanded(
              child: _LocationAction(
                icon: HugeIcons.strokeRoundedGps01,
                label: _isLocating ? 'Locating…' : 'Use current location',
                isLoading: _isLocating,
                onTap: _useCurrentLocation,
              ),
            ),
            SizedBox(width: w * 0.02),
            Expanded(
              child: _LocationAction(
                icon: HugeIcons.strokeRoundedMapsLocation01,
                label: pinned == null ? 'Pick on map' : 'Adjust on map',
                onTap: _openMapPicker,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PinStatus extends StatelessWidget {
  final LatLng? pinned;
  const _PinStatus({required this.pinned});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isPinned = pinned != null;
    final color = isPinned ? AppColors.success : AppColors.warning;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.025),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: isPinned
                ? HugeIcons.strokeRoundedCheckmarkCircle02
                : HugeIcons.strokeRoundedLocation01,
            color: color,
            size: w * 0.045,
          ),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Text(
              isPinned
                  ? 'Pinned at ${pinned!.latitude.toStringAsFixed(5)}, '
                      '${pinned!.longitude.toStringAsFixed(5)}'
                  : 'Not pinned yet. Customers and riders use this to find your shop.',
              style: TextStyle(
                fontSize: w * 0.03,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationAction extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _LocationAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Material(
      color: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isLoading
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap();
              },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.03,
            vertical: w * 0.03,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: w * 0.035,
                  height: w * 0.035,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                HugeIcon(icon: icon, color: AppColors.primary, size: w * 0.04),
              SizedBox(width: w * 0.016),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: w * 0.03,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
