import 'package:equatable/equatable.dart';
import 'package:bagyesrushappusernew/core/errors/failure.dart';
import 'package:bagyesrushappusernew/src/home/models/category.dart';
import 'package:bagyesrushappusernew/src/home/models/category_element.model.dart';
import 'package:bagyesrushappusernew/src/home/models/menu_item.dart';
import 'package:bagyesrushappusernew/src/home/models/order.dart';
import 'package:bagyesrushappusernew/src/home/models/vendor.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

final class HomeInitial extends HomeState {
  const HomeInitial();
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class CategoriesLoaded extends HomeState {
  const CategoriesLoaded(this.categories);

  final List<Category> categories;

  @override
  List<Object?> get props => [categories];
}

final class CategoryElementLoaded extends HomeState {
  const CategoryElementLoaded(this.category);

  final CategoryElement category;

  @override
  List<Object?> get props => [category];
}

final class VendorsLoaded extends HomeState {
  const VendorsLoaded(this.vendors);

  final List<Vendor> vendors;

  @override
  List<Object?> get props => [vendors];
}

final class VendorLoaded extends HomeState {
  const VendorLoaded(this.vendor);

  final Vendor vendor;

  @override
  List<Object?> get props => [vendor];
}

final class MenuItemsLoaded extends HomeState {
  const MenuItemsLoaded(this.items);

  final List<MenuItem> items;

  @override
  List<Object?> get props => [items];
}

final class OrdersLoaded extends HomeState {
  const OrdersLoaded(this.orders);

  final List<Order> orders;

  @override
  List<Object?> get props => [orders];
}

final class OrderLoaded extends HomeState {
  const OrderLoaded(this.order);

  final Order order;

  @override
  List<Object?> get props => [order];
}

final class OrderPlaced extends HomeState {
  const OrderPlaced(this.order);

  final Order order;

  @override
  List<Object?> get props => [order];
}

final class HomeError extends HomeState {
  const HomeError({required this.message, required this.title});

  HomeError.fromFailure(Failure failure)
      : this(message: failure.message, title: failure.title);

  final String message;
  final String title;

  @override
  List<Object?> get props => [message, title];
}

final class HomeNetworkError extends HomeError {
  const HomeNetworkError({required super.message, required super.title});

  HomeNetworkError.fromFailure(Failure failure)
      : super(message: failure.message, title: failure.title);
}
