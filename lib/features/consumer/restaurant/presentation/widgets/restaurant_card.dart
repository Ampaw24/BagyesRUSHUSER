import 'package:flutter/material.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/restaurant.dart';

/// Vertical restaurant card used in grid / horizontal list.
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  final double width;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(w * 0.04),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover image ──
            _CoverImage(restaurant: restaurant, width: width),
            // ── Info ──
            Padding(
              padding: EdgeInsets.all(w * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: w * 0.038,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: w * 0.006),
                  Text(
                    restaurant.cuisineType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: w * 0.029,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: w * 0.02),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          color: AppColors.accent, size: w * 0.034),
                      SizedBox(width: w * 0.008),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: w * 0.03,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time_rounded,
                          color: AppColors.textSecondary, size: w * 0.03),
                      SizedBox(width: w * 0.007),
                      Text(
                        restaurant.deliveryTimeLabel,
                        style: TextStyle(
                          fontSize: w * 0.028,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: w * 0.01),
                  Text(
                    'GHS ${restaurant.deliveryFee.toStringAsFixed(2)} delivery',
                    style: TextStyle(
                      fontSize: w * 0.028,
                      color: restaurant.deliveryFee == 0
                          ? AppColors.success
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width horizontal restaurant card used in vertical list sections.
class RestaurantListCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const RestaurantListCard({
    super.key,
    required this.restaurant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: w * 0.04),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(w * 0.04),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CoverImage(restaurant: restaurant, width: w, height: w * 0.44),
            Padding(
              padding: EdgeInsets.all(w * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: TextStyle(
                            fontSize: w * 0.043,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!restaurant.isOpen)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: w * 0.02,
                            vertical: w * 0.008,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Closed',
                            style: TextStyle(
                              fontSize: w * 0.028,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: w * 0.007),
                  Text(
                    restaurant.cuisineType,
                    style: TextStyle(
                      fontSize: w * 0.032,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: w * 0.025),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.star_rounded,
                        iconColor: AppColors.accent,
                        label: restaurant.rating.toStringAsFixed(1),
                      ),
                      SizedBox(width: w * 0.025),
                      _InfoChip(
                        icon: Icons.access_time_rounded,
                        label: restaurant.deliveryTimeLabel,
                      ),
                      SizedBox(width: w * 0.025),
                      _InfoChip(
                        icon: Icons.delivery_dining_rounded,
                        label: restaurant.deliveryFee == 0
                            ? 'Free delivery'
                            : 'GHS ${restaurant.deliveryFee.toStringAsFixed(0)}',
                        iconColor: restaurant.deliveryFee == 0
                            ? AppColors.success
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────

class _CoverImage extends StatelessWidget {
  final Restaurant restaurant;
  final double width;
  final double? height;

  const _CoverImage({
    required this.restaurant,
    required this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final h = height ?? width * 0.55;
    final w = MediaQuery.sizeOf(context).width;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.04)),
      child: Stack(
        children: [
          SizedBox(
            width: width,
            height: h,
            child: Image.network(
              restaurant.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.shimmerBase,
                child: const Icon(Icons.restaurant,
                    color: AppColors.textHint, size: 48),
              ),
            ),
          ),
          // Gradient overlay at bottom
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: h * 0.35,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
          ),
          // Promo badge
          if (restaurant.promoText != null)
            Positioned(
              top: w * 0.025,
              left: w * 0.025,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.025,
                  vertical: w * 0.01,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  restaurant.promoText!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: w * 0.027,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          // Closed overlay
          if (!restaurant.isOpen)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.04,
                    vertical: w * 0.015,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Closed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: w * 0.036,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: w * 0.033,
            color: iconColor ?? AppColors.textSecondary),
        SizedBox(width: w * 0.01),
        Text(
          label,
          style: TextStyle(
            fontSize: w * 0.03,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
