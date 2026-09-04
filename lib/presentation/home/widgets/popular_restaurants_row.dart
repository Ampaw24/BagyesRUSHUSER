import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        return const SizedBox.shrink();
      case NearbyStatus.loaded:
        final restaurants = state.nearbyRestaurants;
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
