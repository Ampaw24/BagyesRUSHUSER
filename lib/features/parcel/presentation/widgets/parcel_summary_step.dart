import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import '../../data/models/delivery_stop.dart';
import '../../data/models/rider_model.dart';

class ParcelSummaryStep extends StatelessWidget {
  final String packageType;
  final String weightText;
  final String pickupAddress;
  final List<DeliveryStop> deliveryStops;
  final double distanceKm;
  final double extraStopSurchargeGhs;
  final RiderModel? selectedRider;
  final double totalCostGhs;
  final bool fragile;
  final List<File> packageImages;

  const ParcelSummaryStep({
    super.key,
    required this.packageType,
    required this.weightText,
    required this.pickupAddress,
    required this.deliveryStops,
    required this.distanceKm,
    required this.extraStopSurchargeGhs,
    required this.selectedRider,
    required this.totalCostGhs,
    required this.fragile,
    required this.packageImages,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final hasExtraStops = deliveryStops.length > 1;

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

          // ── Route visualization ──────────────────────────────────────────
          _buildRoute(w),

          SizedBox(height: w * 0.04),
          _Divider(),
          SizedBox(height: w * 0.04),

          // ── Package info chips ───────────────────────────────────────────
          Wrap(
            spacing: w * 0.03,
            runSpacing: w * 0.02,
            children: [
              _InfoChip(
                icon: HugeIcons.strokeRoundedDeliveryBox01,
                label: packageType == 'document' ? 'Document' : 'Parcel',
                w: w,
              ),
              _InfoChip(
                icon: HugeIcons.strokeRoundedInformationCircle,
                label: '$weightText kg',
                w: w,
              ),
              _InfoChip(
                icon: HugeIcons.strokeRoundedMapsLocation01,
                label: '${distanceKm.toStringAsFixed(1)} km',
                w: w,
              ),
              if (fragile)
                _InfoChip(
                  icon: HugeIcons.strokeRoundedAlert01,
                  label: 'Fragile',
                  w: w,
                  color: AppColors.error,
                ),
            ],
          ),

          // ── Rider summary ────────────────────────────────────────────────
          if (selectedRider != null) ...[
            SizedBox(height: w * 0.04),
            _Divider(),
            SizedBox(height: w * 0.04),
            _RiderSummaryRow(rider: selectedRider!, w: w),
          ],

          SizedBox(height: w * 0.04),
          _Divider(),
          SizedBox(height: w * 0.04),

          // ── Cost breakdown ───────────────────────────────────────────────
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
          if (hasExtraStops) ...[
            SizedBox(height: w * 0.02),
            _CostRow(
              label:
                  'Extra stops (${deliveryStops.length - 1} × GHS 2.00)',
              value: 'GHS ${extraStopSurchargeGhs.toStringAsFixed(2)}',
              w: w,
              accent: true,
            ),
          ],
          SizedBox(height: w * 0.03),

          // Total box
          Container(
            padding: EdgeInsets.all(w * 0.04),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(w * 0.03),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
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

  // ── Route visualization ────────────────────────────────────────────────────
  //
  // Pickup (green)
  //   │
  //   ● Stop 1
  //   │
  //   ● Stop 2 (if exists)
  //   │
  //   🔵 Final stop (primary blue)

  Widget _buildRoute(double w) {
    final nodes = <Widget>[];

    // Pickup node
    nodes.add(
      _AddressRow(
        icon: HugeIcons.strokeRoundedLocation01,
        iconColor: AppColors.success,
        label: 'Pickup',
        address: pickupAddress,
        w: w,
      ),
    );

    for (int i = 0; i < deliveryStops.length; i++) {
      final isFinal = i == deliveryStops.length - 1;

      nodes.add(_RouteLine(w: w));
      nodes.add(
        _AddressRow(
          icon: isFinal
              ? HugeIcons.strokeRoundedMapsLocation01
              : HugeIcons.strokeRoundedLocation01,
          iconColor: isFinal ? AppColors.primary : AppColors.textSecondary,
          label: deliveryStops.length == 1
              ? 'Delivery'
              : 'Stop ${i + 1}${isFinal ? ' (Final)' : ''}',
          address: deliveryStops[i].address,
          w: w,
        ),
      );
      // Show optional item details beneath the address row if filled in.
      if (deliveryStops[i].hasDetails) {
        nodes.add(_StopDetailChips(
          stop: deliveryStops[i],
          packageImages: packageImages,
          w: w,
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: nodes,
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

// ── Route line (dotted connector) ─────────────────────────────────────────────

class _RouteLine extends StatelessWidget {
  final double w;
  const _RouteLine({required this.w});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: w * 0.023,
        top: w * 0.01,
        bottom: w * 0.01,
      ),
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
  const _Divider();

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
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.w,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.textSecondary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.025,
        vertical: w * 0.015,
      ),
      decoration: BoxDecoration(
        color: color != null
            ? color!.withValues(alpha: 0.08)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.02),
        border: Border.all(
          color: color != null
              ? color!.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: tint, size: w * 0.035),
          SizedBox(width: w * 0.015),
          Text(
            label,
            style: TextStyle(
              fontSize: w * 0.03,
              color: tint,
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

// ── Stop detail chips ─────────────────────────────────────────────────────────

class _StopDetailChips extends StatelessWidget {
  final DeliveryStop stop;
  final List<File> packageImages;
  final double w;

  const _StopDetailChips({
    required this.stop,
    required this.packageImages,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    final taggedImages = stop.selectedImageIndices
        .where((i) => i < packageImages.length)
        .map((i) => packageImages[i])
        .toList();

    return Padding(
      padding: EdgeInsets.only(left: w * 0.08, top: w * 0.015, bottom: w * 0.005),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tagged photo strip ───────────────────────────────────────────
          if (taggedImages.isNotEmpty) ...[
            SizedBox(
              height: w * 0.16,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: taggedImages.length,
                separatorBuilder: (_, _) => SizedBox(width: w * 0.02),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(w * 0.022),
                  child: Image.file(
                    taggedImages[i],
                    width: w * 0.14,
                    height: w * 0.14,
                    fit: BoxFit.cover,
                    cacheWidth: (w * 0.14 *
                            MediaQuery.devicePixelRatioOf(context))
                        .round(),
                  ),
                ),
              ),
            ),
            SizedBox(height: w * 0.015),
          ],
          // ── Detail chips ─────────────────────────────────────────────────
          Wrap(
            spacing: w * 0.02,
            runSpacing: w * 0.015,
            children: [
              if (stop.itemDescription.isNotEmpty)
                _DetailChip(
                  icon: Icons.inventory_2_outlined,
                  label: '${stop.quantity}× ${stop.itemDescription}',
                  w: w,
                ),
              if (stop.recipientName.isNotEmpty || stop.recipientPhone.isNotEmpty)
                _DetailChip(
                  icon: Icons.person_outline_rounded,
                  label: [
                    if (stop.recipientName.isNotEmpty) stop.recipientName,
                    if (stop.recipientPhone.isNotEmpty) stop.recipientPhone,
                  ].join(' · '),
                  w: w,
                ),
              if (stop.specialInstructions.isNotEmpty)
                _DetailChip(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: stop.specialInstructions,
                  w: w,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final double w;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.025,
        vertical: w * 0.012,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.02),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: w * 0.033, color: AppColors.textSecondary),
          SizedBox(width: w * 0.015),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: w * 0.03,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cost row ──────────────────────────────────────────────────────────────────

class _CostRow extends StatelessWidget {
  final String label;
  final String value;
  final double w;
  final bool accent;

  const _CostRow({
    required this.label,
    required this.value,
    required this.w,
    this.accent = false,
  });

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
              color: accent ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: w * 0.033,
            fontWeight: FontWeight.w600,
            color: accent ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
