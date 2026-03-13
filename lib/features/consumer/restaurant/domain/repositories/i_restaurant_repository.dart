import '../entities/restaurant.dart';
import '../entities/menu_item.dart';

/// Abstract contract for the restaurant data layer.
/// Swap the implementation (mock → real API) without touching any presentation code.
abstract interface class IRestaurantRepository {
  /// All active restaurants, optionally filtered by [category].
  Future<List<Restaurant>> getRestaurants({String? category});

  /// Featured / promoted restaurants for the home banner.
  Future<List<Restaurant>> getFeaturedRestaurants();

  /// Restaurants within ~5 km of the user.
  Future<List<Restaurant>> getNearbyRestaurants();

  /// Single restaurant detail.
  Future<Restaurant> getRestaurantById(String id);

  /// Full menu for a restaurant, grouped by category key.
  Future<Map<String, List<MenuItem>>> getMenu(String restaurantId);

  /// Search restaurants + menu items by [query].
  Future<List<Restaurant>> search(String query);
}
