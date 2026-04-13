import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import '../../data/models/rider_model.dart';

class RiderCard extends StatelessWidget {
  final RiderModel rider;
  final double distanceKm;

  /// Per-stop surcharge already computed by the parent (0.0 for single delivery).
  final double extraStopSurchargeGhs;

  final bool isSelected;
  final VoidCallback onTap;

  const RiderCard({
    super.key,
    required this.rider,
    required this.distanceKm,
    this.extraStopSurchargeGhs = 0.0,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cost = rider.totalCost(distanceKm) + extraStopSurchargeGhs;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.only(bottom: w * 0.035),
        padding: EdgeInsets.all(w * 0.045),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.card,
          borderRadius: BorderRadius.circular(w * 0.04),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.06 : 0.03),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Avatar ─────────────────────────────────────────────────────
            Container(
              width: w * 0.13,
              height: w * 0.13,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  rider.initials,
                  style: TextStyle(
                    fontSize: w * 0.04,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.secondary,
                  ),
                ),
              ),
            ),

            SizedBox(width: w * 0.04),

            // ── Info ───────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        rider.name,
                        style: TextStyle(
                          fontSize: w * 0.038,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'GHS ${cost.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: w * 0.042,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: w * 0.015),
                  Row(
                    children: [
                      _VehicleBadge(vehicle: rider.vehicle, w: w),
                      SizedBox(width: w * 0.025),
                      _MetaChip(
                        icon: HugeIcons.strokeRoundedStarCircle,
                        label: rider.rating.toStringAsFixed(1),
                        color: AppColors.accent,
                        w: w,
                      ),
                      SizedBox(width: w * 0.025),
                      _MetaChip(
                        icon: HugeIcons.strokeRoundedClock01,
                        label: '~${rider.etaMinutes} min',
                        color: AppColors.textSecondary,
                        w: w,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: w * 0.03),

            // ── Selection indicator ────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: w * 0.06,
              height: w * 0.06,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Colors.white, size: w * 0.035)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Vehicle badge ─────────────────────────────────────────────────────────────

class _VehicleBadge extends StatelessWidget {
  final VehicleType vehicle;
  final double w;

  const _VehicleBadge({required this.vehicle, required this.w});

  List<List<dynamic>> get _icon {
    switch (vehicle) {
      case VehicleType.motorbike:
        return HugeIcons.strokeRoundedDeliveryTruck01;
      case VehicleType.bicycle:
        return HugeIcons.strokeRoundedDeliveryTruck01;
      case VehicleType.car:
        return HugeIcons.strokeRoundedDeliveryTruck01;
    }
  }

  Color get _color {
    switch (vehicle) {
      case VehicleType.motorbike:
        return AppColors.primary;
      case VehicleType.bicycle:
        return AppColors.success;
      case VehicleType.car:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.02,
        vertical: w * 0.008,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(w * 0.015),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: _icon, color: _color, size: w * 0.03),
          SizedBox(width: w * 0.012),
          Text(
            switch (vehicle) {
              VehicleType.motorbike => 'Motorbike',
              VehicleType.bicycle => 'Bicycle',
              VehicleType.car => 'Car',
            },
            style: TextStyle(
              fontSize: w * 0.027,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Meta chip ─────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final Color color;
  final double w;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(icon: icon, color: color, size: w * 0.032),
        SizedBox(width: w * 0.01),
        Text(
          label,
          style: TextStyle(
            fontSize: w * 0.03,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
