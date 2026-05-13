import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/home/models/order.dart';
import 'package:bagyesrushappusernew/src/home/repositories/home_repository.dart';
import 'package:bagyesrushappusernew/src/home/viewmodels/home_state.dart';

class HomeViewmodel extends ViewModel<HomeState> {
  HomeViewmodel({required HomeRepository repository})
      : _repository = repository,
        super(const HomeInitial());

  final HomeRepository _repository;
  // ─── Categories ────────────────
  Future<void> getCategories() async {
    appLogger.d('HomeViewmodel.getCategories → initiated');
    emit(const HomeLoading());

    final result = await _repository.getCategories();

    result.fold(
      (failure) {
        appLogger.w(
            'HomeViewmodel.getCategories → error: ${failure.message}');
        emit(HomeError.fromFailure(failure));
      },
      (categories) {
        appLogger.i(
            'HomeViewmodel.getCategories → loaded ${categories.length} categories');
        emit(CategoriesLoaded(categories));
      },
    );
  }
void setcategories(){
  

}

  //Home page Path 1
  //Get Ads banner for courier homepage
    Future<void> getHomePageBanners() async {
      appLogger.d('HomeViewmodel.getHomePageBanners → initiated');
      emit(const HomeLoading());
  
      final result = await _repository.getHomePageBanners();
  
      result.fold(
        (failure) {
          appLogger.w(
              'HomeViewmodel.getHomePageBanners → error: ${failure.message}');
          emit(HomeError.fromFailure(failure));
        },
        (banners) {
          appLogger.i(
              'HomeViewmodel.getHomePageBanners → loaded ${banners.banners.length} banners');
          emit(HomePageBannersLoaded(banners));
        },
      );
    }
    //Ads banner for courier homepage End
    

  Future<void> getCategoryById(String id) async {
    appLogger.d('HomeViewmodel.getCategoryById → id=$id');
    emit(const HomeLoading());

    final result = await _repository.getCategoryById(id);

    result.fold(
      (failure) {
        appLogger.w('HomeViewmodel.getCategoryById → error: ${failure.message}');
        emit(HomeError.fromFailure(failure));
      },
      (category) {
        appLogger.i('HomeViewmodel.getCategoryById → loaded category id=${category.id}');
        emit(CategoryElementLoaded(category));
      },
    );
  }

  // ─── Vendors ───────────────────────────────────────────────────────────────

  Future<void> getVendors({String? categoryId}) async {
    appLogger.d(
        'HomeViewmodel.getVendors → categoryId=${categoryId ?? 'all'}');
    emit(const HomeLoading());

    final result = await _repository.getVendors(categoryId: categoryId);

    result.fold(
      (failure) {
        appLogger.w('HomeViewmodel.getVendors → error: ${failure.message}');
        emit(HomeError.fromFailure(failure));
      },
      (vendors) {
        appLogger.i(
            'HomeViewmodel.getVendors → loaded ${vendors.length} vendors');
        emit(VendorsLoaded(vendors));
      },
    );
  }

  Future<void> getVendorById(String vendorId) async {
    appLogger.d('HomeViewmodel.getVendorById → vendorId=$vendorId');
    emit(const HomeLoading());

    final result = await _repository.getVendorById(vendorId);

    result.fold(
      (failure) {
        appLogger.w(
            'HomeViewmodel.getVendorById → error: ${failure.message}');
        emit(HomeError.fromFailure(failure));
      },
      (vendor) {
        appLogger.i(
            'HomeViewmodel.getVendorById → loaded vendor id=${vendor.id}');
        emit(VendorLoaded(vendor));
      },
    );
  }

  // ─── Menu Items ────────────────────────────────────────────────────────────

  Future<void> getVendorMenuItems(String vendorId) async {
    appLogger.d('HomeViewmodel.getVendorMenuItems → vendorId=$vendorId');
    emit(const HomeLoading());

    final result = await _repository.getVendorMenuItems(vendorId);

    result.fold(
      (failure) {
        appLogger.w(
            'HomeViewmodel.getVendorMenuItems → error: ${failure.message}');
        emit(HomeError.fromFailure(failure));
      },
      (items) {
        appLogger.i(
            'HomeViewmodel.getVendorMenuItems → loaded ${items.length} items');
        emit(MenuItemsLoaded(items));
      },
    );
  }

  // ─── Orders ────────────────────────────────────────────────────────────────

  Future<void> getOrders() async {
    appLogger.d('HomeViewmodel.getOrders → initiated');
    emit(const HomeLoading());

    final result = await _repository.getOrders();

    result.fold(
      (failure) {
        appLogger.w('HomeViewmodel.getOrders → error: ${failure.message}');
        emit(HomeError.fromFailure(failure));
      },
      (orders) {
        appLogger.i(
            'HomeViewmodel.getOrders → loaded ${orders.length} orders');
        emit(OrdersLoaded(orders));
      },
    );
  }

  Future<void> getOrderById(String orderId) async {
    appLogger.d('HomeViewmodel.getOrderById → orderId=$orderId');
    emit(const HomeLoading());

    final result = await _repository.getOrderById(orderId);

    result.fold(
      (failure) {
        appLogger.w(
            'HomeViewmodel.getOrderById → error: ${failure.message}');
        emit(HomeError.fromFailure(failure));
      },
      (order) {
        appLogger.i(
            'HomeViewmodel.getOrderById → loaded order id=${order.id}');
        emit(OrderLoaded(order));
      },
    );
  }

  Future<void> placeOrder({
    required String vendorId,
    required List<OrderItem> items,
    required String deliveryAddress,
  }) async {
    appLogger.d(
        'HomeViewmodel.placeOrder → vendorId=$vendorId, items=${items.length}');
    emit(const HomeLoading());

    final result = await _repository.placeOrder(
      vendorId: vendorId,
      items: items,
      deliveryAddress: deliveryAddress,
    );

    result.fold(
      (failure) {
        appLogger.w('HomeViewmodel.placeOrder → error: ${failure.message}');
        emit(HomeError.fromFailure(failure));
      },
      (order) {
        appLogger.i(
            'HomeViewmodel.placeOrder → order placed id=${order.id}');
        emit(OrderPlaced(order));
      },
    );
  }

  /// Resets state to [HomeInitial] after a one-shot action has been handled.
  void resetState() => emit(const HomeInitial());
}
