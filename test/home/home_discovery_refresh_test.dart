import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/core/errors/failure.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/home/models/ads_banner.dart';
import 'package:bagyesrushappusernew/src/home/models/category.dart';
import 'package:bagyesrushappusernew/src/home/repositories/home_repository.dart';
import 'package:bagyesrushappusernew/src/home/viewmodel/home_discovery_viewmodel.dart';
import 'package:bagyesrushappusernew/src/restaurant/models/restaurant.dart';
import 'package:bagyesrushappusernew/src/restaurant/repositories/restaurant_repository.dart';

Restaurant _restaurant(String name) => Restaurant(
      id: name,
      name: name,
      imageUrl: '',
      cuisineType: '',
      categories: const [],
      rating: 4,
      reviewCount: 1,
      deliveryTimeMin: 20,
      deliveryTimeMax: 30,
      deliveryFee: 5,
      minOrder: 0,
      isOpen: true,
      isFeatured: false,
      address: '',
      latitude: 0,
      longitude: 0,
    );

const _failure = ServerFailure(message: 'offline', statusCode: 499, title: 'x');

class _Home extends Fake implements HomeRepository {
  bool fail = false;

  @override
  ResultFuture<AdBannerModel> getHomePageBanners() async => fail
      ? const Left(_failure)
      : const Right(AdBannerModel(banners: [], total: 0));

  @override
  ResultFuture<List<Category>> getCategories() async =>
      fail ? const Left(_failure) : const Right([]);
}

class _Restaurants extends Fake implements RestaurantRepository {
  bool fail = false;
  List<Restaurant> list = [_restaurant('Old Place')];
  List<Restaurant> nearby = [_restaurant('Old Nearby')];

  /// When set, the next list request waits for it — lets a test change the
  /// category while a refresh is still in flight.
  Completer<void>? gate;

  @override
  Future<RestaurantPage> getRestaurantsPaged({
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    await gate?.future;
    if (fail) throw Exception('offline');
    return RestaurantPage(restaurants: list, page: 1, totalPages: 1, total: list.length);
  }

  @override
  Future<List<Restaurant>> getNearbyRestaurants({
    double? radius,
    String? search,
    int? businessTypeId,
    String? category,
    bool? isOpen,
    int perPage = 20,
  }) async {
    if (fail) throw Exception('offline');
    return nearby;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Home home;
  late _Restaurants restaurants;
  late HomeDiscoveryViewModel vm;

  setUp(() async {
    home = _Home();
    restaurants = _Restaurants();
    vm = HomeDiscoveryViewModel(
      restaurantRepository: restaurants,
      homeRepository: home,
    );
    await pumpEventQueue();
    addTearDown(vm.dispose);
  });

  List<String> names(List<Restaurant> list) => [for (final r in list) r.name];

  test('refresh swaps in fresh data without ever blanking the screen',
      () async {
    expect(names(vm.state.restaurants), ['Old Place']);
    restaurants
      ..list = [_restaurant('Fresh Place')]
      ..nearby = [_restaurant('Fresh Nearby')];
    final seen = <(VendorListStatus, NearbyStatus)>[];
    vm.addListener(() => seen.add((vm.state.vendorListStatus, vm.state.nearbyStatus)));

    await vm.refresh();

    expect(names(vm.state.restaurants), ['Fresh Place']);
    expect(names(vm.state.nearbyRestaurants), ['Fresh Nearby']);
    expect(
      seen.every((s) => s.$1 == VendorListStatus.loaded && s.$2 == NearbyStatus.loaded),
      isTrue,
      reason: 'no shimmer/loading state during a pull-to-refresh',
    );
  });

  test('a failed refresh leaves what is already on screen untouched', () async {
    restaurants.fail = true;
    home.fail = true;

    await vm.refresh();

    expect(names(vm.state.restaurants), ['Old Place']);
    expect(names(vm.state.nearbyRestaurants), ['Old Nearby']);
    expect(vm.state.vendorListStatus, VendorListStatus.loaded);
    expect(vm.state.nearbyStatus, NearbyStatus.loaded);
    expect(vm.state.bannersStatus, BannersStatus.loaded);
    expect(vm.state.categoriesStatus, CategoriesStatus.loaded);
  });

  test('refreshing after a failed first load recovers', () async {
    restaurants.fail = true;
    home.fail = true;
    final broken = HomeDiscoveryViewModel(
      restaurantRepository: restaurants,
      homeRepository: home,
    );
    addTearDown(broken.dispose);
    await pumpEventQueue();
    expect(broken.state.vendorListStatus, VendorListStatus.error);

    restaurants
      ..fail = false
      ..list = [_restaurant('Back Online')];
    home.fail = false;
    await broken.refresh();

    expect(names(broken.state.restaurants), ['Back Online']);
    expect(broken.state.vendorListStatus, VendorListStatus.loaded);
    expect(broken.state.bannersStatus, BannersStatus.loaded);
  });

  test('a list for a category the user has since left is dropped', () async {
    restaurants
      ..list = [_restaurant('Stale All-category Result')]
      ..gate = Completer<void>();

    final refreshing = vm.refresh();
    vm.emit(vm.state.copyWith(selectedCategory: 'Pizza'));
    restaurants.gate!.complete();
    await refreshing;

    expect(names(vm.state.restaurants), ['Old Place']);
  });
}
