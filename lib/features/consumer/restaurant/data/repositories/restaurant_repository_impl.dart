import 'package:dio/dio.dart';
import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/location_helper.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/menu_item.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/restaurant.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/repositories/i_restaurant_repository.dart'
    show IRestaurantRepository, RestaurantPage;

class RestaurantRepositoryImpl implements IRestaurantRepository {
  const RestaurantRepositoryImpl({required Dio client}) : _client = client;

  final Dio _client;

  // ─── IRestaurantRepository ─────────────────────────────────────────────────

  @override
  Future<List<Restaurant>> getRestaurants({String? category}) async {
    final result = await getRestaurantsPaged(category: category, page: 1);
    return result.restaurants;
  }

  @override
  Future<RestaurantPage> getRestaurantsPaged({
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    appLogger.d(
        'RestaurantRepository.getRestaurantsPaged → category=${category ?? 'all'} page=$page');
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (category != null && category.toLowerCase() != 'all') {
        params['category'] = category.toLowerCase().replaceAll(' ', '-');
      }

      final response = await _client.get(
        ApiEndpoints.vendors,
        queryParameters: params,
      );

      final (list, meta) = _extractPagedList(response);
      final restaurants =
          list.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();

      final currentPage =
          (meta['current_page'] ?? meta['page']) as num? ?? page;
      final lastPage = (meta['last_page'] ?? meta['totalPages']) as num? ?? 1;
      final total = meta['total'] as num? ?? restaurants.length;

      appLogger.i(
          'RestaurantRepository.getRestaurantsPaged → ${restaurants.length} items '
          '(page $currentPage/$lastPage, total $total)');

      return RestaurantPage(
        restaurants: restaurants,
        page: currentPage.toInt(),
        totalPages: lastPage.toInt(),
        total: total.toInt(),
      );
    } on DioException catch (e) {
      appLogger.e('RestaurantRepository.getRestaurantsPaged → DioException', error: e);
      rethrow;
    } catch (e, s) {
      appLogger.e('RestaurantRepository.getRestaurantsPaged → error', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<List<Restaurant>> getFeaturedRestaurants() async {
    appLogger.d('RestaurantRepository.getFeaturedRestaurants → initiated');
    try {
      final response = await _client.get(ApiEndpoints.vendorsFeatured);
      final (list, _) = _extractPagedList(response);
      final restaurants =
          list.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
      appLogger.i(
          'RestaurantRepository.getFeaturedRestaurants → ${restaurants.length} items');
      return restaurants;
    } on DioException catch (e) {
      appLogger.e('RestaurantRepository.getFeaturedRestaurants → DioException', error: e);
      rethrow;
    } catch (e, s) {
      appLogger.e('RestaurantRepository.getFeaturedRestaurants → error', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<List<Restaurant>> getNearbyRestaurants() async {
    appLogger.d('RestaurantRepository.getNearbyRestaurants → initiated');
    try {
      final location = await LocationHelper.getCurrentLocation();
      final position = location['position'];
      if (position == null) {
        appLogger.w(
            'RestaurantRepository.getNearbyRestaurants → no device location, falling back to open vendors');
        final page = await getRestaurantsPaged();
        return page.restaurants.where((r) => r.isOpen).take(6).toList();
      }

      final response = await _client.get(
        ApiEndpoints.vendorsNearby,
        queryParameters: {'lat': position.latitude, 'lng': position.longitude},
      );
      final (list, _) = _extractPagedList(response);
      final restaurants =
          list.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
      appLogger.i(
          'RestaurantRepository.getNearbyRestaurants → ${restaurants.length} items');
      return restaurants;
    } on DioException catch (e) {
      appLogger.e('RestaurantRepository.getNearbyRestaurants → DioException', error: e);
      rethrow;
    } catch (e, s) {
      appLogger.e('RestaurantRepository.getNearbyRestaurants → error', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<Restaurant> getRestaurantById(String id) async {
    appLogger.d('RestaurantRepository.getRestaurantById → id=$id');
    try {
      final response = await _client.get(ApiEndpoints.vendorById(id));
      final payload = _extractSingle(response);
      final restaurant = Restaurant.fromJson(payload);
      appLogger.i('RestaurantRepository.getRestaurantById → loaded id=${restaurant.id}');
      return restaurant;
    } on DioException catch (e) {
      appLogger.e('RestaurantRepository.getRestaurantById → DioException', error: e);
      rethrow;
    } catch (e, s) {
      appLogger.e('RestaurantRepository.getRestaurantById → error', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<Map<String, List<MenuItem>>> getMenu(String restaurantId) async {
    appLogger.d('RestaurantRepository.getMenu → restaurantId=$restaurantId');
    try {
      final response =
          await _client.get(ApiEndpoints.vendorMenuItems(restaurantId));
      final rawItems = _extractMenuItems(response);
      final items = rawItems
          .map((e) => MenuItem.fromJson(
                e as Map<String, dynamic>,
                restaurantId: restaurantId,
              ))
          .toList();

      final grouped = <String, List<MenuItem>>{};
      for (final item in items) {
        grouped.putIfAbsent(item.category, () => []).add(item);
      }

      appLogger.i(
          'RestaurantRepository.getMenu → ${items.length} items in ${grouped.keys.length} categories');
      return grouped;
    } on DioException catch (e) {
      appLogger.e('RestaurantRepository.getMenu → DioException', error: e);
      rethrow;
    } catch (e, s) {
      appLogger.e('RestaurantRepository.getMenu → error', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<List<Restaurant>> search(String query) async {
    appLogger.d('RestaurantRepository.search → query=$query');
    try {
      final response = await _client.get(
        ApiEndpoints.vendors,
        queryParameters: {'search': query},
      );
      final (list, _) = _extractPagedList(response);
      final results = list
          .map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
          .toList();

      appLogger.i('RestaurantRepository.search → ${results.length} results');
      return results;
    } on DioException catch (e) {
      appLogger.e('RestaurantRepository.search → DioException', error: e);
      rethrow;
    } catch (e, s) {
      appLogger.e('RestaurantRepository.search → error', error: e, stackTrace: s);
      rethrow;
    }
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  /// Handles the response shapes returned across vendor endpoints:
  ///   Shape A (flat):        { "data": [...], "meta": {...} }
  ///   Shape B (nested):      { "data": { "data": [...], "meta": {...} } }
  ///   Shape C (bare list):   [...]
  ///   Shape D (items/page):  { "data": { "items": [...], "pagination": {...} } }
  (List<dynamic>, Map<String, dynamic>) _extractPagedList(Response response) {
    final body = response.data;

    // Shape C — bare array
    if (body is List) return (body, {});

    if (body is Map<String, dynamic>) {
      final outer = body['data'];

      if (outer is Map<String, dynamic>) {
        // Shape D — outer["items"] is the list, outer["pagination"] is meta
        final items = outer['items'];
        if (items is List) {
          final pagination = outer['pagination'] as Map<String, dynamic>? ?? {};
          return (items, pagination);
        }

        // Shape B — outer["data"] is itself a map with nested data + meta
        final inner = outer['data'];
        final meta = outer['meta'] as Map<String, dynamic>? ?? {};
        if (inner is List) return (inner, meta);
      }

      // Shape A — outer["data"] is already the list
      if (outer is List) {
        final meta = body['meta'] as Map<String, dynamic>? ?? {};
        return (outer, meta);
      }
    }

    return (const [], {});
  }

  /// Flattens the menu endpoint's nested shape:
  ///   { "data": { "vendor": {...}, "sections": [ { "category": {...}, "items": [...] } ] } }
  List<dynamic> _extractMenuItems(Response response) {
    final body = response.data;
    if (body is! Map<String, dynamic>) return const [];
    final data = body['data'];
    if (data is! Map<String, dynamic>) return const [];
    final sections = data['sections'];
    if (sections is! List) return const [];

    final items = <dynamic>[];
    for (final section in sections) {
      if (section is Map<String, dynamic> && section['items'] is List) {
        items.addAll(section['items'] as List);
      }
    }
    return items;
  }

  Map<String, dynamic> _extractSingle(Response response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final d = body['data'];
      // Nested: { "data": { "data": {...} } }
      if (d is Map<String, dynamic>) {
        final inner = d['data'];
        if (inner is Map<String, dynamic>) return inner;
        return d;
      }
    }
    return const {};
  }
}
