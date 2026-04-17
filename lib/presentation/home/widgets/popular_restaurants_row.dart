import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../features/consumer/restaurant/presentation/viewmodels/restaurant_viewmodel.dart';
import '../../../features/consumer/restaurant/presentation/widgets/restaurant_card.dart';
import 'shimmer_card.dart';

class PopularRestaurantsRow extends ConsumerWidget {
  const PopularRestaurantsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.sizeOf(context).width;
    final nearby = ref.watch(nearbyRestaurantsProvider);

    return nearby.when(
      loading: () => SizedBox(
        height: w * 0.50,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: w * 0.05),
          itemCount: 3,
          separatorBuilder: (_, _) => SizedBox(width: w * 0.035),
          itemBuilder: (_, i) => ShimmerCard(width: w * 0.44),
        ),
      ),
      error: (_, e) => const SizedBox.shrink(),
      data: (restaurants) => SizedBox(
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
                context.push(AppRoutes.restaurantDetailPath(restaurants[i].id)),
          ),
        ),
      ),
    );
  }
}
