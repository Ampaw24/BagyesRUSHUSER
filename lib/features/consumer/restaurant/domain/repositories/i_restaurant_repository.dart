import '../entities/restaurant.dart';
import '../entities/menu_item.dart';

class RestaurantPage {
  final List<Restaurant> restaurants;
  final int page;
  final int totalPages;
  final int total;

  const RestaurantPage({
    required this.restaurants,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  bool get hasMore => page < totalPages;
}

/// Abstract contract for the restaurant data layer.
/// Swap the implementation (mock → real API) without touching any presentation code.
abstract interface class IRestaurantRepository {
  /// All active restaurants, optionally filtered by [category].
  Future<List<Restaurant>> getRestaurants({String? category});

  /// Paginated restaurant list with meta (page, totalPages, total).
  Future<RestaurantPage> getRestaurantsPaged({
    String? category,
    int page = 1,
    int limit = 20,
  });

  /// Featured / promoted restaurants for the home banner.
  Future<List<Restaurant>> getFeaturedRestaurants();

  /// Restaurants near the user's current location.
  ///
  /// Mirrors `GET /vendors/nearby`'s query contract:
  ///   - [radius] km, 0.1–100 (server default applies when omitted).
  ///   - [search] free-text vendor search, max 255 chars.
  ///   - [businessTypeId] must reference an existing `business_types.id`.
  ///   - [category] vendor category slug/name.
  ///   - [isOpen] filters to currently-open vendors only.
  ///   - [perPage] page size, 1–100 (defaults to 20).
  Future<List<Restaurant>> getNearbyRestaurants({
    double? radius,
    String? search,
    int? businessTypeId,
    String? category,
    bool? isOpen,
    int perPage = 20,
  });

  /// Single restaurant detail.
  Future<Restaurant> getRestaurantById(String id);

  /// Full menu for a restaurant, grouped by category key.
  Future<Map<String, List<MenuItem>>> getMenu(String restaurantId);

  /// Search restaurants + menu items by [query].
  Future<List<Restaurant>> search(String query);
}
