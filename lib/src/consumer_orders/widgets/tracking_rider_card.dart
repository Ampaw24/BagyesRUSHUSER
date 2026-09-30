import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/utils/phone_launcher.dart';
import 'package:bagyesrushappusernew/core/widgets/network_avatar.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'tracking_card.dart';

/// Assigned rider's profile — photo, name, vehicle and number plate — with
/// chat and call actions. Only built once the order has a
/// [ConsumerOrder.driverName]; profile extras appear as the backend sends
/// them (usually with the first live location update).
class TrackingRiderCard extends StatelessWidget {
  const TrackingRiderCard({
    super.key,
    required this.order,
    required this.onChat,
  });

  final ConsumerOrder order;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final name = order.driverName!.trim();
    final phone = order.driverPhone?.trim() ?? '';
    final vehicle = _vehicleLabel(order.driverVehicleType);
    final plate = order.driverPlateNumber?.trim() ?? '';
    final rating = order.driverRating;
    final deliveries = order.driverDeliveriesCompleted ?? 0;

    return TrackingCard(
      child: Row(
        children: [
          _RiderAvatar(name: name, photoUrl: order.driverPhotoUrl),
          SizedBox(width: w * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your rider',
                  style: TextStyle(
                    fontSize: w * 0.029,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: w * 0.042,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (rating != null || deliveries > 0) ...[
                  SizedBox(height: w * 0.008),
                  _RiderStats(
                    rating: rating,
                    reviewCount: order.driverReviewCount,
                    deliveries: deliveries,
                  ),
                ],
                if (vehicle != null || plate.isNotEmpty) ...[
                  SizedBox(height: w * 0.012),
                  Wrap(
                    spacing: w * 0.02,
                    runSpacing: w * 0.01,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (vehicle != null) _VehicleLabel(label: vehicle),
                      if (plate.isNotEmpty) _PlateBadge(plate: plate),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: w * 0.02),
          TrackingCircleButton(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: 'Chat',
            background: AppColors.success.withValues(alpha: 0.1),
            foreground: AppColors.success,
            bordered: false,
            sizeFactor: 0.12,
            onTap: () {
              HapticFeedback.lightImpact();
              onChat();
            },
          ),
          if (phone.isNotEmpty) ...[
            SizedBox(width: w * 0.025),
            TrackingCircleButton(
              icon: Icons.phone_in_talk_rounded,
              tooltip: 'Call',
              background: AppColors.primary,
              foreground: Colors.white,
              bordered: false,
              sizeFactor: 0.12,
              onTap: () {
                HapticFeedback.lightImpact();
                launchPhoneCall(context, phone);
              },
            ),
          ],
        ],
      ),
    );
  }

  /// `motorbike` → `Motorbike`.
  static String? _vehicleLabel(String? raw) {
    final type = raw?.replaceAll('_', ' ').trim() ?? '';
    if (type.isEmpty) return null;
    return type[0].toUpperCase() + type.substring(1);
  }
}

/// Rider photo (initial as fallback). Tapping a photo opens it larger so the
/// customer can recognise the rider at the door.
class _RiderAvatar extends StatelessWidget {
  const _RiderAvatar({required this.name, required this.photoUrl});

  final String name;
  final String? photoUrl;

  void _showPhoto(BuildContext context, String url) {
    final w = MediaQuery.sizeOf(context).width;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(w * 0.1),
        child: GestureDetector(
          onTap: () => Navigator.of(dialogContext).pop(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(w * 0.05),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(url, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final size = w * 0.15;
    final url = photoUrl?.trim() ?? '';

    final avatar = Container(
      padding: EdgeInsets.all(size * 0.05),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: NetworkAvatar(name: name, photoUrl: url, size: size),
    );

    if (url.isEmpty) return avatar;
    return Semantics(
      button: true,
      label: 'View rider photo',
      child: GestureDetector(
        onTap: () => _showPhoto(context, url),
        child: avatar,
      ),
    );
  }
}

/// "★ 4.8 (132) · 486 deliveries".
class _RiderStats extends StatelessWidget {
  const _RiderStats({
    required this.rating,
    required this.reviewCount,
    required this.deliveries,
  });

  final double? rating;
  final int? reviewCount;
  final int deliveries;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final style = TextStyle(
      fontSize: w * 0.03,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    );
    final rating = this.rating;
    final reviews = reviewCount;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: w * 0.015,
      children: [
        if (rating != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: w * 0.04, color: AppColors.accent),
              SizedBox(width: w * 0.006),
              Text(
                reviews == null
                    ? rating.toStringAsFixed(1)
                    : '${rating.toStringAsFixed(1)} ($reviews)',
                style: style.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        if (rating != null && deliveries > 0) Text('·', style: style),
        if (deliveries > 0) Text('$deliveries deliveries', style: style),
      ],
    );
  }
}

class _VehicleLabel extends StatelessWidget {
  const _VehicleLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.two_wheeler_rounded,
          size: w * 0.04,
          color: AppColors.textSecondary,
        ),
        SizedBox(width: w * 0.01),
        Text(
          label,
          style: TextStyle(
            fontSize: w * 0.03,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Number plate styled like a registration plate, so the customer can match
/// it to the bike that pulls up.
class _PlateBadge extends StatelessWidget {
  const _PlateBadge({required this.plate});

  final String plate;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.018, vertical: w * 0.005),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.012),
        border: Border.all(color: AppColors.textPrimary, width: 1.2),
      ),
      child: Text(
        plate.toUpperCase(),
        style: TextStyle(
          fontSize: w * 0.029,
          fontWeight: FontWeight.w800,
          letterSpacing: w * 0.002,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
