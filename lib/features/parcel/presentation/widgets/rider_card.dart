import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/parcel/model/rider_model.dart';

/// Read-only card showing the rider the backend has matched to the current
/// quote. There is no selection here — the backend picks the nearest
/// available rider, not the customer.
class AssignedRiderCard extends StatelessWidget {
  final RiderModel rider;

  const AssignedRiderCard({super.key, required this.rider});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      padding: EdgeInsets.all(w * 0.045),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _RiderAvatar(rider: rider, w: w),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rider.name,
                  style: TextStyle(
                    fontSize: w * 0.04,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: w * 0.018),
                Wrap(
                  spacing: w * 0.025,
                  runSpacing: w * 0.012,
                  children: [
                    if (rider.vehicleTypeLabel != null)
                      _MetaChip(
                        icon: HugeIcons.strokeRoundedDeliveryTruck01,
                        label: rider.vehicleTypeLabel!,
                        color: AppColors.primary,
                        w: w,
                      ),
                    _MetaChip(
                      icon: HugeIcons.strokeRoundedStarCircle,
                      label: '${rider.rating.toStringAsFixed(1)} (${rider.reviewCount})',
                      color: AppColors.accent,
                      w: w,
                    ),
                    if (rider.distanceAwayKm != null)
                      _MetaChip(
                        icon: HugeIcons.strokeRoundedMapsLocation01,
                        label: '${rider.distanceAwayKm!.toStringAsFixed(1)} km away',
                        color: AppColors.textSecondary,
                        w: w,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar ─────────────────────────────────────────────────────────────────

class _RiderAvatar extends StatelessWidget {
  final RiderModel rider;
  final double w;

  const _RiderAvatar({required this.rider, required this.w});

  @override
  Widget build(BuildContext context) {
    final photoUrl = rider.photoUrl;
    return CircleAvatar(
      radius: w * 0.075,
      backgroundColor: AppColors.primary,
      backgroundImage: photoUrl != null && photoUrl.isNotEmpty
          ? NetworkImage(photoUrl)
          : null,
      child: photoUrl == null || photoUrl.isEmpty
          ? Text(
              rider.initials,
              style: TextStyle(
                fontSize: w * 0.042,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}

// ── No rider available ───────────────────────────────────────────────────

/// Placeholder shown in [AssignedRiderCard]'s place when the backend
/// couldn't match a rider (e.g. none available near the pickup point right
/// now). Mirrors the assigned card's avatar+details shape but muted, so the
/// screen still reads as "a rider will appear here" rather than collapsing
/// into a bare error message — the way Uber/Bolt grey out the driver card
/// while no match has been found instead of showing an alarm.
class NoRiderAvailableCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const NoRiderAvailableCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      padding: EdgeInsets.all(w * 0.045),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: w * 0.075,
                backgroundColor: AppColors.surfaceVariant,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedDeliveryTruck01,
                  color: AppColors.textSecondary,
                  size: w * 0.06,
                ),
              ),
              SizedBox(width: w * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No riders nearby right now',
                      style: TextStyle(
                        fontSize: w * 0.04,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: w * 0.01),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: w * 0.032,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.04),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: w * 0.03),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(w * 0.03),
              ),
              child: Text(
                'Search again',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: w * 0.035,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Meta chip ─────────────────────────────────────────────────────────────

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
