import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/parcel/model/rider_model.dart';
import 'rider_card.dart';

class AvailableRidersStep extends StatelessWidget {
  final List<RiderModel> riders;
  final String? selectedRiderId;
  final double distanceKm;

  /// Additional surcharge for multi-stop bookings (GHS). Zero for
  /// single-delivery — keeps the widget backwards-compatible.
  final double extraStopSurchargeGhs;

  final ValueChanged<String> onRiderSelected;

  const AvailableRidersStep({
    super.key,
    required this.riders,
    required this.selectedRiderId,
    required this.distanceKm,
    this.extraStopSurchargeGhs = 0.0,
    required this.onRiderSelected,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final minCost = riders.isEmpty
        ? 0.0
        : riders
                .map((r) => r.totalCost(distanceKm))
                .reduce((a, b) => a < b ? a : b) +
            extraStopSurchargeGhs;
    final maxCost = riders.isEmpty
        ? 0.0
        : riders
                .map((r) => r.totalCost(distanceKm))
                .reduce((a, b) => a > b ? a : b) +
            extraStopSurchargeGhs;

    return ListView(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.02, w * 0.05, w * 0.04),
      children: [
        Text(
          'Available Riders',
          style: TextStyle(
            fontSize: w * 0.055,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: w * 0.025),

        // ── Trip summary card ───────────────────────────────────────────────
        _TripSummaryCard(
          distanceKm: distanceKm,
          minCost: minCost,
          maxCost: maxCost,
          w: w,
        ),

        SizedBox(height: w * 0.05),

        Text(
          'Select your rider',
          style: TextStyle(
            fontSize: w * 0.038,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: w * 0.03),

        ...riders.map(
          (rider) => RiderCard(
            rider: rider,
            distanceKm: distanceKm,
            extraStopSurchargeGhs: extraStopSurchargeGhs,
            isSelected: rider.id == selectedRiderId,
            onTap: () => onRiderSelected(rider.id),
          ),
        ),
      ],
    );
  }
}

// ── Trip summary card ─────────────────────────────────────────────────────────

class _TripSummaryCard extends StatelessWidget {
  final double distanceKm;
  final double minCost;
  final double maxCost;
  final double w;

  const _TripSummaryCard({
    required this.distanceKm,
    required this.minCost,
    required this.maxCost,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(w * 0.045),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(w * 0.04),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatItem(
            icon: HugeIcons.strokeRoundedMapsLocation01,
            value: '${distanceKm.toStringAsFixed(1)} km',
            label: 'Distance',
            w: w,
          ),
          _divider(w: w),
          _StatItem(
            icon: HugeIcons.strokeRoundedMoneyBag01,
            value: 'GHS ${minCost.toStringAsFixed(0)}–${maxCost.toStringAsFixed(0)}',
            label: 'Est. Cost',
            w: w,
          ),
          _divider(w: w),
          _StatItem(
            icon: HugeIcons.strokeRoundedClock01,
            value: '${_minEta()} min',
            label: 'Fastest',
            w: w,
          ),
        ],
      ),
    );
  }

  String _minEta() => '5–15';

  Widget _divider({required double w}) => Container(
        width: 1,
        height: w * 0.1,
        color: Colors.white.withValues(alpha: 0.25),
        margin: EdgeInsets.symmetric(horizontal: w * 0.02),
      );
}

class _StatItem extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String value;
  final String label;
  final double w;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HugeIcon(icon: icon, color: Colors.white, size: w * 0.05),
          SizedBox(height: w * 0.015),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: w * 0.033,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: w * 0.005),
          Text(
            label,
            style: TextStyle(
              fontSize: w * 0.027,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
