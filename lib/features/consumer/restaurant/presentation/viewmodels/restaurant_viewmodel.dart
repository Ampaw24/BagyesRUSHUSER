import 'dart:async';    
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/data/repositories/restaurant_repository_impl.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/menu_item.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/restaurant.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/repositories/i_restaurant_repository.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/presentation/widgets/food_category_chip.dart';
import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/src/home/repositories/home_repository.dart';
import 'package:bagyesrushappusernew/src/home/models/ads_banner.dart';

// ─── Repository provider ──────────────────────────────────────────────────

final restaurantRepositoryProvider = Provider<IRestaurantRepository>(
  (_) => RestaurantRepositoryImpl(client: sl<Dio>()),
);

// ─── Selected category (debounced) ───────────────────────────────────────

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String>(
      SelectedCategoryNotifier.new,
    );

class SelectedCategoryNotifier extends Notifier<String> {
  Timer? _debounce;

  @override
  String build() {
    ref.onDispose(() => _debounce?.cancel());
    return 'All';
  }

  void updateCategory(String category) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      state = category;
    });
  }
}

final homeBannersProvider = FutureProvider<AdBannerModel>((ref) async {
  final repo = sl<HomeRepository>();
  final result = await repo.getHomePageBanners();
  return result.fold((failure) => throw failure, (banners) => banners);
});

// ─── Featured restaurants (promo banners) ────────────────────────────────

final featuredRestaurantsProvider =
    FutureProvider.autoDispose<List<Restaurant>>((ref) {
      return ref.watch(restaurantRepositoryProvider).getFeaturedRestaurants();
    });

// ─── All restaurants, filtered by selected category (legacy) ─────────────

final restaurantsProvider = FutureProvider.autoDispose<List<Restaurant>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  return ref
      .watch(restaurantRepositoryProvider)
      .getRestaurants(category: category);
});

// ─── Paginated restaurant list state ─────────────────────────────────────

class VendorListState {
  final List<Restaurant> restaurants;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;

  const VendorListState({
    this.restaurants = const [],
    this.isLoadingMore = false,
    this.hasMore = false,
    this.currentPage = 0,
  });

  VendorListState copyWith({
    List<Restaurant>? restaurants,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
  }) => VendorListState(
    restaurants: restaurants ?? this.restaurants,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    currentPage: currentPage ?? this.currentPage,
  );
}

class VendorListNotifier
    extends AutoDisposeFamilyAsyncNotifier<VendorListState, String> {
  @override
  Future<VendorListState> build(String category) async {
    return _fetch(category: category, page: 1);
  }

  Future<VendorListState> _fetch({
    required String category,
    required int page,
  }) async {
    final repo = ref.read(restaurantRepositoryProvider);
    final result = await repo.getRestaurantsPaged(
      category: category,
      page: page,
    );
    return VendorListState(
      restaurants: result.restaurants,
      hasMore: result.hasMore,
      currentPage: result.page,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final repo = ref.read(restaurantRepositoryProvider);
      final result = await repo.getRestaurantsPaged(
        category: arg,
        page: current.currentPage + 1,
      );
      state = AsyncData(
        VendorListState(
          restaurants: [...current.restaurants, ...result.restaurants],
          hasMore: result.hasMore,
          currentPage: result.page,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      // Keep existing data; clear loading flag
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final vendorListProvider = AsyncNotifierProvider.autoDispose
    .family<VendorListNotifier, VendorListState, String>(
      VendorListNotifier.new,
    );

// ─── Categories (from API) ────────────────────────────────────────────────

final categoriesProvider = FutureProvider<List<FoodCategory>>((ref) async {
  final repo = sl<HomeRepository>();
  final result = await repo.getCategories();
  return result.fold(
    (_) => FoodCategory.all, // fallback to static list on error
    (categories) {
      final apiChips =
          categories
              .expand((c) => c.categories)
              .where((e) => e.isActive)
              .toList()
            ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      return [
        const FoodCategory(label: 'All', emoji: '🍽️'),
        ...apiChips.map(
          (e) => FoodCategory(
            label: e.name,
            emoji: '',
            imageUrl: e.imageUrl.isNotEmpty ? e.imageUrl : null,
          ),
        ),
      ];
    },
  );
});

// ─── Nearby restaurants ───────────────────────────────────────────────────

final nearbyRestaurantsProvider = FutureProvider.autoDispose<List<Restaurant>>((
  ref,
) {
  return ref.watch(restaurantRepositoryProvider).getNearbyRestaurants();
});

// ─── Single restaurant + menu for detail screen ───────────────────────────

final restaurantDetailProvider = FutureProvider.autoDispose
    .family<Restaurant, String>((ref, restaurantId) {
      return ref
          .watch(restaurantRepositoryProvider)
          .getRestaurantById(restaurantId);
    });

final restaurantMenuProvider = FutureProvider.autoDispose
    .family<Map<String, List<MenuItem>>, String>((ref, restaurantId) {
      return ref.watch(restaurantRepositoryProvider).getMenu(restaurantId);
    });
