import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/checkout/viewmodels/checkout_viewmodel.dart';
import 'package:bagyesrushappusernew/src/customer_address/models/customer_address.dart';

/// Saved delivery addresses for checkout, plus "Use current location" /
/// "Pick on map" which save a new address and select it.
class DeliveryAddressSection extends StatelessWidget {
  const DeliveryAddressSection({
    super.key,
    required this.status,
    required this.addresses,
    required this.selected,
    required this.isBusy,
    required this.isLocating,
    required this.onSelect,
    required this.onRetry,
    required this.onUseCurrentLocation,
    required this.onPickOnMap,
  });

  final AddressesStatus status;
  final List<CustomerAddress> addresses;
  final CustomerAddress? selected;

  /// Saving a new address is in flight.
  final bool isBusy;
  final bool isLocating;
  final ValueChanged<CustomerAddress> onSelect;
  final VoidCallback onRetry;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onPickOnMap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final Widget list = switch (status) {
      AddressesStatus.loading => Padding(
          padding: EdgeInsets.symmetric(vertical: w * 0.04),
          child: const Center(child: CircularProgressIndicator()),
        ),
      AddressesStatus.error => Row(
          children: [
            Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: w * 0.05),
            SizedBox(width: w * 0.02),
            Expanded(
              child: Text(
                'Could not load your saved addresses',
                style: TextStyle(fontSize: w * 0.033),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      AddressesStatus.loaded => addresses.isEmpty
          ? Padding(
              padding: EdgeInsets.only(bottom: w * 0.02),
              child: Text(
                'No saved addresses yet — add one below.',
                style: TextStyle(
                  fontSize: w * 0.032,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : Column(
              children: addresses
                  .map((a) => _AddressTile(
                        address: a,
                        isSelected: selected?.id == a.id,
                        onTap: () => onSelect(a),
                      ))
                  .toList(),
            ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        list,
        Wrap(
          spacing: w * 0.02,
          runSpacing: w * 0.02,
          children: [
            _QuickAddressChip(
              icon: Icons.my_location_rounded,
              label: isLocating ? 'Locating…' : 'Use current location',
              isLoading: isLocating,
              onTap: isBusy ? null : onUseCurrentLocation,
            ),
            _QuickAddressChip(
              icon: Icons.map_rounded,
              label: isBusy ? 'Saving…' : 'Pick on map',
              isLoading: isBusy && !isLocating,
              onTap: isBusy ? null : onPickOnMap,
            ),
          ],
        ),
      ],
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  final CustomerAddress address;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final label = address.label;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.only(bottom: w * 0.025),
        padding: EdgeInsets.all(w * 0.035),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.07)
              : AppColors.card,
          borderRadius: BorderRadius.circular(w * 0.03),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_rounded,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: w * 0.055,
            ),
            SizedBox(width: w * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null && label.isNotEmpty)
                    Text(
                      address.isDefault ? '$label · Default' : label,
                      style: TextStyle(
                        fontSize: w * 0.035,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  Text(
                    address.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: w * 0.032,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _QuickAddressChip extends StatelessWidget {
  const _QuickAddressChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      onTap: isLoading || onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.025,
          vertical: w * 0.015,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(w * 0.02),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
              Icon(icon, size: w * 0.035, color: AppColors.primary),
            SizedBox(width: w * 0.015),
            Text(
              label,
              style: TextStyle(
                fontSize: w * 0.028,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
