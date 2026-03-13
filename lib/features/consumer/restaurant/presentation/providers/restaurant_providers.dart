import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/data/repositories/restaurant_repository_impl.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/menu_item.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/restaurant.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/repositories/i_restaurant_repository.dart';

// ─── Repository provider ──────────────────────────────────────────────────

final restaurantRepositoryProvider = Provider<IRestaurantRepository>(
  (_) => RestaurantRepositoryImpl(),
);

// ─── Selected category ────────────────────────────────────────────────────

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

// ─── Featured restaurants (for promo banners) ─────────────────────────────

final featuredRestaurantsProvider =
    FutureProvider.autoDispose<List<Restaurant>>((ref) {
  return ref.watch(restaurantRepositoryProvider).getFeaturedRestaurants();
});

// ─── All restaurants, filtered by selected category ───────────────────────

final restaurantsProvider =
    FutureProvider.autoDispose<List<Restaurant>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  return ref.watch(restaurantRepositoryProvider).getRestaurants(
        category: category,
      );
});

// ─── Nearby restaurants ───────────────────────────────────────────────────

final nearbyRestaurantsProvider =
    FutureProvider.autoDispose<List<Restaurant>>((ref) {
  return ref.watch(restaurantRepositoryProvider).getNearbyRestaurants();
});

// ─── Single restaurant + menu for detail screen ───────────────────────────

final restaurantDetailProvider = FutureProvider.autoDispose
    .family<Restaurant, String>((ref, restaurantId) {
  return ref.watch(restaurantRepositoryProvider).getRestaurantById(restaurantId);
});

final restaurantMenuProvider = FutureProvider.autoDispose
    .family<Map<String, List<MenuItem>>, String>((ref, restaurantId) {
  return ref.watch(restaurantRepositoryProvider).getMenu(restaurantId);
});

// ─── Search ───────────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider =
    FutureProvider.autoDispose<List<Restaurant>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return Future.value([]);
  return ref.watch(restaurantRepositoryProvider).search(query);
});
