import 'dart:async';

import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/home/models/ads_banner.dart';
import 'package:bagyesrushappusernew/src/home/repositories/home_repository.dart';
import 'package:bagyesrushappusernew/src/restaurant/models/restaurant.dart';
import 'package:bagyesrushappusernew/src/restaurant/repositories/restaurant_repository.dart';
import 'package:bagyesrushappusernew/src/restaurant/widgets/food_category_chip.dart'
    show FoodCategory;

enum CategoriesStatus { loading, error, loaded }

enum BannersStatus { loading, error, loaded }

enum VendorListStatus { loading, error, loaded }

enum NearbyStatus { loading, error, loaded }

class HomeDiscoveryState {
  final String selectedCategory;

  final CategoriesStatus categoriesStatus;
  final List<FoodCategory> categories;

  final BannersStatus bannersStatus;
  final AdBannerModel? banners;

  final VendorListStatus vendorListStatus;
  final List<Restaurant> restaurants;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;

  final NearbyStatus nearbyStatus;
  final List<Restaurant> nearbyRestaurants;

  const HomeDiscoveryState({
    this.selectedCategory = 'All',
    this.categoriesStatus = CategoriesStatus.loading,
    this.categories = const [],
    this.bannersStatus = BannersStatus.loading,
    this.banners,
    this.vendorListStatus = VendorListStatus.loading,
    this.restaurants = const [],
    this.isLoadingMore = false,
    this.hasMore = false,
    this.currentPage = 0,
    this.nearbyStatus = NearbyStatus.loading,
    this.nearbyRestaurants = const [],
  });

  HomeDiscoveryState copyWith({
    String? selectedCategory,
    CategoriesStatus? categoriesStatus,
    List<FoodCategory>? categories,
    BannersStatus? bannersStatus,
    AdBannerModel? banners,
    VendorListStatus? vendorListStatus,
    List<Restaurant>? restaurants,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    NearbyStatus? nearbyStatus,
    List<Restaurant>? nearbyRestaurants,
  }) {
    return HomeDiscoveryState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      categoriesStatus: categoriesStatus ?? this.categoriesStatus,
      categories: categories ?? this.categories,
      bannersStatus: bannersStatus ?? this.bannersStatus,
      banners: banners ?? this.banners,
      vendorListStatus: vendorListStatus ?? this.vendorListStatus,
      restaurants: restaurants ?? this.restaurants,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      nearbyStatus: nearbyStatus ?? this.nearbyStatus,
      nearbyRestaurants: nearbyRestaurants ?? this.nearbyRestaurants,
    );
  }
}

/// Backs the Home tab's discovery screen (`home_discovery_tab.dart`,
/// `promo_banner_section.dart`, `popular_restaurants_row.dart`) plus the
/// vendor-side shop-info sheet's cuisine-type chips — all previously five
/// separate Riverpod providers (`selectedCategoryProvider`,
/// `categoriesProvider`, `homeBannersProvider`, `vendorListProvider.family`,
/// `nearbyRestaurantsProvider`) sharing one screen's worth of state,
/// consolidated the same way `DashboardState`/`OrdersState` bundle several
/// concerns into one flat state object.
class HomeDiscoveryViewModel extends ViewModel<HomeDiscoveryState> {
  HomeDiscoveryViewModel({
    required RestaurantRepository restaurantRepository,
    required HomeRepository homeRepository,
  })  : _restaurantRepository = restaurantRepository,
        _homeRepository = homeRepository,
        super(const HomeDiscoveryState()) {
    _loadCategories();
    _loadBanners();
    _loadVendorList(category: state.selectedCategory, page: 1);
    _loadNearby();
  }

  final RestaurantRepository _restaurantRepository;
  final HomeRepository _homeRepository;

  Timer? _categoryDebounce;

  @override
  void dispose() {
    _categoryDebounce?.cancel();
    super.dispose();
  }

  /// The `keepOnError` / `silent` flags are for [refresh]: a pull-to-refresh
  /// that fails must leave what's already on screen alone.
  Future<void> _loadCategories({bool keepOnError = false}) async {
    final result = await _homeRepository.getCategories();
    result.fold(
      // Fallback to the static list on error, mirroring the original
      // provider's `(_) => FoodCategory.all` behavior.
      (_) {
        if (keepOnError && state.categoriesStatus == CategoriesStatus.loaded) {
          return;
        }
        emit(state.copyWith(
          categoriesStatus: CategoriesStatus.error,
          categories: FoodCategory.all,
        ));
      },
      (categories) {
        final apiChips = categories
            .expand((c) => c.categories)
            .where((e) => e.isActive)
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

        emit(state.copyWith(
          categoriesStatus: CategoriesStatus.loaded,
          categories: [
            const FoodCategory(label: 'All', emoji: '🍽️'),
            ...apiChips.map(
              (e) => FoodCategory(
                label: e.name,
                emoji: '',
                imageUrl: e.imageUrl.isNotEmpty ? e.imageUrl : null,
              ),
            ),
          ],
        ));
      },
    );
  }

  Future<void> _loadBanners({bool keepOnError = false}) async {
    final result = await _homeRepository.getHomePageBanners();
    result.fold(
      (_) {
        if (keepOnError && state.bannersStatus == BannersStatus.loaded) return;
        emit(state.copyWith(bannersStatus: BannersStatus.error));
      },
      (banners) => emit(state.copyWith(
        bannersStatus: BannersStatus.loaded,
        banners: banners,
      )),
    );
  }

  Future<void> _loadNearby({bool silent = false}) async {
    if (!silent) emit(state.copyWith(nearbyStatus: NearbyStatus.loading));
    try {
      final restaurants = await _restaurantRepository.getNearbyRestaurants();
      emit(state.copyWith(
        nearbyStatus: NearbyStatus.loaded,
        nearbyRestaurants: restaurants,
      ));
    } catch (_) {
      if (silent && state.nearbyStatus == NearbyStatus.loaded) return;
      emit(state.copyWith(nearbyStatus: NearbyStatus.error));
    }
  }

  Future<void> _loadVendorList({
    required String category,
    required int page,
    bool silent = false,
  }) async {
    if (page == 1 && !silent) {
      emit(state.copyWith(vendorListStatus: VendorListStatus.loading));
    }
    try {
      final result = await _restaurantRepository.getRestaurantsPaged(
        category: category,
        page: page,
      );
      // The category changed while this was in flight — its list is stale.
      if (category != state.selectedCategory) return;
      emit(state.copyWith(
        vendorListStatus: VendorListStatus.loaded,
        restaurants: page == 1
            ? result.restaurants
            : [...state.restaurants, ...result.restaurants],
        hasMore: result.hasMore,
        currentPage: result.page,
        isLoadingMore: false,
      ));
    } catch (_) {
      if (page == 1) {
        if (silent && state.vendorListStatus == VendorListStatus.loaded) return;
        emit(state.copyWith(vendorListStatus: VendorListStatus.error));
      } else {
        // Keep existing data; clear loading flag so the user can retry by
        // scrolling again.
        emit(state.copyWith(isLoadingMore: false));
      }
    }
  }

  /// Debounced category switch (350ms, matching the original
  /// `SelectedCategoryNotifier`) — the chip highlight and the refetch both
  /// only happen once the debounce settles, not on every tap.
  void updateCategory(String category) {
    _categoryDebounce?.cancel();
    _categoryDebounce = Timer(const Duration(milliseconds: 350), () {
      emit(state.copyWith(
        selectedCategory: category,
        restaurants: const [],
        currentPage: 0,
        hasMore: false,
      ));
      _loadVendorList(category: category, page: 1);
    });
  }

  /// Infinite scroll on the restaurant list.
  Future<void> loadMoreVendors() async {
    if (state.isLoadingMore || !state.hasMore) return;
    emit(state.copyWith(isLoadingMore: true));
    await _loadVendorList(
      category: state.selectedCategory,
      page: state.currentPage + 1,
    );
  }

  /// Pull-to-refresh: reloads everything on the home screen. Content already
  /// shown stays put (no shimmer) until the fresh data replaces it, and a
  /// failed reload leaves it untouched.
  Future<void> refresh() => Future.wait([
        _loadCategories(keepOnError: true),
        _loadBanners(keepOnError: true),
        _loadNearby(silent: true),
        _loadVendorList(
          category: state.selectedCategory,
          page: 1,
          silent: true,
        ),
      ]);

  /// Retries the first page after an error.
  Future<void> retryVendorList() =>
      _loadVendorList(category: state.selectedCategory, page: 1);

  Future<void> retryNearby() => _loadNearby();
}
