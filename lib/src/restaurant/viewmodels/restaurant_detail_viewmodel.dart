import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/restaurant/models/menu_item.dart';
import 'package:bagyesrushappusernew/src/restaurant/models/restaurant.dart';
import 'package:bagyesrushappusernew/src/restaurant/repositories/restaurant_repository.dart';

enum RestaurantLoadStatus { loading, error, loaded }

enum MenuLoadStatus { loading, error, loaded }

class RestaurantDetailState {
  final RestaurantLoadStatus status;
  final Restaurant? restaurant;
  final String? errorMessage;
  final MenuLoadStatus menuStatus;
  final Map<String, List<MenuItem>> menu;

  const RestaurantDetailState({
    this.status = RestaurantLoadStatus.loading,
    this.restaurant,
    this.errorMessage,
    this.menuStatus = MenuLoadStatus.loading,
    this.menu = const {},
  });

  RestaurantDetailState copyWith({
    RestaurantLoadStatus? status,
    Restaurant? restaurant,
    String? errorMessage,
    MenuLoadStatus? menuStatus,
    Map<String, List<MenuItem>>? menu,
  }) {
    return RestaurantDetailState(
      status: status ?? this.status,
      restaurant: restaurant ?? this.restaurant,
      errorMessage: errorMessage ?? this.errorMessage,
      menuStatus: menuStatus ?? this.menuStatus,
      menu: menu ?? this.menu,
    );
  }
}

/// Screen-scoped — one instance per [RestaurantDetailView] push, created via
/// `sl<RestaurantDetailViewModel>(param1: restaurantId)` and owned/disposed
/// directly by that view's State (not registered as an app-wide
/// ChangeNotifierProvider), since restaurant detail data is never shared
/// across screens the way orders/cart/dashboard state is.
class RestaurantDetailViewModel extends ViewModel<RestaurantDetailState> {
  RestaurantDetailViewModel({
    required RestaurantRepository repository,
    required this.restaurantId,
  })  : _repository = repository,
        super(const RestaurantDetailState()) {
    _loadRestaurant();
    _loadMenu();
  }

  final RestaurantRepository _repository;
  final String restaurantId;

  Future<void> _loadRestaurant() async {
    try {
      final restaurant = await _repository.getRestaurantById(restaurantId);
      emit(state.copyWith(
        status: RestaurantLoadStatus.loaded,
        restaurant: restaurant,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RestaurantLoadStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _loadMenu() async {
    emit(state.copyWith(menuStatus: MenuLoadStatus.loading));
    try {
      final menu = await _repository.getMenu(restaurantId);
      emit(state.copyWith(menuStatus: MenuLoadStatus.loaded, menu: menu));
    } catch (_) {
      emit(state.copyWith(menuStatus: MenuLoadStatus.error));
    }
  }

  /// Retries just the menu fetch — used by the menu section's "Retry" button
  /// when the restaurant itself loaded fine but the menu call failed.
  Future<void> refreshMenu() => _loadMenu();
}
