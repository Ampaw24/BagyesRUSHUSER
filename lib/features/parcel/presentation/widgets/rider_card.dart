import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/parcel/model/parcel_quote.dart';
import 'package:bagyesrushappusernew/src/parcel/model/rider_model.dart';

/// Selectable rider tile. Each rider carries their own quote — fee and ETA
/// differ by where that rider currently is.
class RiderQuoteCard extends StatelessWidget {
  final ParcelQuote quote;
  final bool isSelected;
  final VoidCallback onTap;

  const RiderQuoteCard({
    super.key,
    required this.quote,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final rider = quote.rider!;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(w * 0.04),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.card,
          borderRadius: BorderRadius.circular(w * 0.04),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
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
            SizedBox(width: w * 0.035),
            Expanded(child: _RiderDetails(rider: rider, w: w)),
            SizedBox(width: w * 0.02),
            _QuotePrice(quote: quote, isSelected: isSelected, w: w),
          ],
        ),
      ),
    );
  }
}

class _RiderDetails extends StatelessWidget {
  final RiderModel rider;
  final double w;

  const _RiderDetails({required this.rider, required this.w});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rider.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: w * 0.04,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: w * 0.015),
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
                label: '${rider.distanceAwayKm!.toStringAsFixed(2)} km away',
                color: AppColors.textSecondary,
                w: w,
              ),
          ],
        ),
      ],
    );
  }
}

class _QuotePrice extends StatelessWidget {
  final ParcelQuote quote;
  final bool isSelected;
  final double w;

  const _QuotePrice({
    required this.quote,
    required this.isSelected,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${quote.currency} ${quote.price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: w * 0.038,
            fontWeight: FontWeight.w800,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        if (quote.etaMinutes != null) ...[
          SizedBox(height: w * 0.01),
          _MetaChip(
            icon: HugeIcons.strokeRoundedClock01,
            label: '${quote.etaMinutes} min',
            color: AppColors.textSecondary,
            w: w,
          ),
        ],
      ],
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

/// Placeholder shown in place of the [RiderQuoteCard] list when the backend
/// couldn't match a rider (e.g. none available near the pickup point right
/// now). Mirrors the rider tile's avatar+details shape but muted, so the
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
