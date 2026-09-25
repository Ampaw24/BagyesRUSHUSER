import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../constant/app_theme.dart';
import '../../../core/router/app_navigator.dart';
import '../../../src/home/viewmodel/home_discovery_viewmodel.dart';
import '../../../src/restaurant/widgets/restaurant_card.dart';
import 'shimmer_card.dart';

class PopularRestaurantsRow extends StatelessWidget {
  const PopularRestaurantsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final state = context.watch<HomeDiscoveryViewModel>().state;

    switch (state.nearbyStatus) {
      case NearbyStatus.loading:
        return SizedBox(
          height: w * 0.50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: w * 0.05),
            itemCount: 3,
            separatorBuilder: (_, _) => SizedBox(width: w * 0.035),
            itemBuilder: (_, i) => ShimmerCard(width: w * 0.44),
          ),
        );
      case NearbyStatus.error:
        return SizedBox(
          height: w * 0.50,
          child: _PopularRowPlaceholder(
            w: w,
            icon: HugeIcons.strokeRoundedWifiError01,
            title: "Couldn't load nearby spots",
            subtitle: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () =>
                context.read<HomeDiscoveryViewModel>().retryNearby(),
          ),
        );
      case NearbyStatus.loaded:
        final restaurants = state.nearbyRestaurants;
        if (restaurants.isEmpty) {
          return SizedBox(
            height: w * 0.50,
            child: _PopularRowPlaceholder(
              w: w,
              icon: HugeIcons.strokeRoundedLocation01,
              title: 'No popular spots near you yet',
              subtitle: 'Check back soon as more vendors join bagyesRUSH.',
            ),
          );
        }
        return SizedBox(
          height: w * 0.50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: w * 0.05),
            itemCount: restaurants.length,
            separatorBuilder: (_, s) => SizedBox(width: w * 0.035),
            itemBuilder: (ctx, i) => RestaurantCard(
              restaurant: restaurants[i],
              width: w * 0.44,
              onTap: () =>
                  AppNavigator.toRestaurantDetail(context, restaurants[i]),
            ),
          ),
        );
    }
  }
}

/// Compact empty/error filler for the "Popular Near You" horizontal row —
/// sized to sit inside the row's fixed height rather than the full-page
/// [_EmptyState]/[_ErrorState] used below for the main restaurant list.
class _PopularRowPlaceholder extends StatelessWidget {
  final double w;
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _PopularRowPlaceholder({
    required this.w,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: w * 0.05),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.04),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(w * 0.035),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: icon,
                color: AppColors.primary.withValues(alpha: 0.6),
                size: w * 0.07,
              ),
            ),
            SizedBox(height: w * 0.03),
            Text(
              title,
              style: TextStyle(
                fontSize: w * 0.035,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: w * 0.012),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: w * 0.03,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: w * 0.03),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.04,
                    vertical: w * 0.018,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(w * 0.06),
                  ),
                  child: Text(
                    actionLabel!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: w * 0.03,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
