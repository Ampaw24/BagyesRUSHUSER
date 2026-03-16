import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/menu_item.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/restaurant.dart';

/// Sealed states for the restaurant list screen.
sealed class RestaurantListState {
  const RestaurantListState();
}

class RestaurantListLoading extends RestaurantListState {
  const RestaurantListLoading();
}

class RestaurantListLoaded extends RestaurantListState {
  final List<Restaurant> restaurants;
  const RestaurantListLoaded({required this.restaurants});
}

class RestaurantListError extends RestaurantListState {
  final String message;
  const RestaurantListError({required this.message});
}

/// Sealed states for the restaurant detail + menu screen.
sealed class RestaurantDetailState {
  const RestaurantDetailState();
}

class RestaurantDetailLoading extends RestaurantDetailState {
  const RestaurantDetailLoading();
}

class RestaurantDetailLoaded extends RestaurantDetailState {
  final Restaurant restaurant;
  final Map<String, List<MenuItem>> menu;
  const RestaurantDetailLoaded({
    required this.restaurant,
    required this.menu,
  });
}

class RestaurantDetailError extends RestaurantDetailState {
  final String message;
  const RestaurantDetailError({required this.message});
}
