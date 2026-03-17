import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import '../../data/models/rider_model.dart';

class ParcelSummaryStep extends StatelessWidget {
  final String packageType;
  final String weightText;
  final String pickupAddress;
  final String deliveryAddress;
  final double sourceLat;
  final double sourceLng;
  final double destLat;
  final double destLng;
  final double distanceKm;
  final RiderModel? selectedRider;
  final double totalCostGhs;

  const ParcelSummaryStep({
    super.key,
    required this.packageType,
    required this.weightText,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.sourceLat,
    required this.sourceLng,
    required this.destLat,
    required this.destLng,
    required this.distanceKm,
    required this.selectedRider,
    required this.totalCostGhs,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.05, w * 0.05, w * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

                  Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: w * 0.05,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: w * 0.04),

                  // ── Addresses ─────────────────────────────────────────────
                  _AddressRow(
                    icon: HugeIcons.strokeRoundedLocation01,
                    iconColor: AppColors.success,
                    label: 'Pickup',
                    address: pickupAddress,
                    w: w,
                  ),
                  _RouteLine(w: w),
                  _AddressRow(
                    icon: HugeIcons.strokeRoundedMapsLocation01,
                    iconColor: AppColors.primary,
                    label: 'Delivery',
                    address: deliveryAddress,
                    w: w,
                  ),

                  SizedBox(height: w * 0.04),
                  _Divider(w: w),
                  SizedBox(height: w * 0.04),

                  // ── Package info ──────────────────────────────────────────
                  Row(
                    children: [
                      _InfoChip(
                        icon: HugeIcons.strokeRoundedDeliveryBox01,
                        label: packageType == 'document' ? 'Document' : 'Parcel',
                        w: w,
                      ),
                      SizedBox(width: w * 0.03),
                      _InfoChip(
                        icon: HugeIcons.strokeRoundedInformationCircle,
                        label: '$weightText kg',
                        w: w,
                      ),
                      SizedBox(width: w * 0.03),
                      _InfoChip(
                        icon: HugeIcons.strokeRoundedMapsLocation01,
                        label: '${distanceKm.toStringAsFixed(1)} km',
                        w: w,
                      ),
                    ],
                  ),

                  if (selectedRider != null) ...[
                    SizedBox(height: w * 0.04),
                    _Divider(w: w),
                    SizedBox(height: w * 0.04),
                    _RiderSummaryRow(rider: selectedRider!, w: w),
                  ],

                  SizedBox(height: w * 0.04),
                  _Divider(w: w),
                  SizedBox(height: w * 0.04),

                  // ── Cost breakdown ────────────────────────────────────────
                  _CostRow(
                    label: 'Base fee',
                    value:
                        'GHS ${selectedRider?.baseFeeGhs.toStringAsFixed(2) ?? '0.00'}',
                    w: w,
                  ),
                  SizedBox(height: w * 0.02),
                  _CostRow(
                    label:
                        'Distance (${distanceKm.toStringAsFixed(1)} km × GHS ${selectedRider?.perKmFeeGhs.toStringAsFixed(2) ?? '0'})',
                    value:
                        'GHS ${((selectedRider?.perKmFeeGhs ?? 0) * distanceKm).toStringAsFixed(2)}',
                    w: w,
                  ),
                  SizedBox(height: w * 0.03),
                  Container(
                    padding: EdgeInsets.all(w * 0.04),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(w * 0.03),
                      border:
                          Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: w * 0.042,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'GHS ${totalCostGhs.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: w * 0.05,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: w * 0.02),
        ],
      ),
    );
  }
}

// ── Address row ───────────────────────────────────────────────────────────────

class _AddressRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color iconColor;
  final String label;
  final String address;
  final double w;

  const _AddressRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HugeIcon(icon: icon, color: iconColor, size: w * 0.05),
        SizedBox(width: w * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: w * 0.028,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHint,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: w * 0.005),
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
      ],
    );
  }
}

// ── Route line ────────────────────────────────────────────────────────────────

class _RouteLine extends StatelessWidget {
  final double w;
  const _RouteLine({required this.w});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: w * 0.023, top: w * 0.01, bottom: w * 0.01),
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            width: 2,
            height: w * 0.02,
            margin: EdgeInsets.symmetric(vertical: w * 0.006),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Divider ───────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  final double w;
  const _Divider({required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.divider);
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final double w;

  const _InfoChip({required this.icon, required this.label, required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.025,
        vertical: w * 0.015,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.02),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: AppColors.textSecondary, size: w * 0.035),
          SizedBox(width: w * 0.015),
          Text(
            label,
            style: TextStyle(
              fontSize: w * 0.03,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rider summary row ─────────────────────────────────────────────────────────

class _RiderSummaryRow extends StatelessWidget {
  final RiderModel rider;
  final double w;

  const _RiderSummaryRow({required this.rider, required this.w});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: w * 0.11,
          height: w * 0.11,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              rider.initials,
              style: TextStyle(
                fontSize: w * 0.038,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(width: w * 0.035),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rider.name,
                style: TextStyle(
                  fontSize: w * 0.038,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: w * 0.008),
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedDeliveryTruck01,
                    color: AppColors.textSecondary,
                    size: w * 0.032,
                  ),
                  SizedBox(width: w * 0.01),
                  Text(
                    rider.vehicleLabel,
                    style: TextStyle(
                      fontSize: w * 0.03,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: w * 0.025),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedStarCircle,
                    color: AppColors.accent,
                    size: w * 0.032,
                  ),
                  SizedBox(width: w * 0.01),
                  Text(
                    rider.rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: w * 0.03,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.03,
            vertical: w * 0.015,
          ),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(w * 0.02),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: w * 0.018,
                height: w * 0.018,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: w * 0.015),
              Text(
                'Available',
                style: TextStyle(
                  fontSize: w * 0.028,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Cost row ──────────────────────────────────────────────────────────────────

class _CostRow extends StatelessWidget {
  final String label;
  final String value;
  final double w;

  const _CostRow({required this.label, required this.value, required this.w});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: w * 0.033,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: w * 0.033,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
