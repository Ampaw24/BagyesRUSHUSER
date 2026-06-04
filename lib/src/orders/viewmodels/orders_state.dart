import 'package:equatable/equatable.dart';
import 'package:bagyesrushappusernew/core/errors/failure.dart';
import 'package:bagyesrushappusernew/src/vendor/model/menu_item.dart';
import '../models/order.dart';

enum MenuStatus { initial, loading, loaded, error }
enum MenuOperation { adding, updating, deleting }

const menuCategories = [
  'All',
  'Meals',
  'Sides',
  'Drinks',
  'Snacks',
  'Desserts',
  'Breakfast',
  'Specials',
];

sealed class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => [];
}

final class OrdersInitial extends OrdersState {
  const OrdersInitial();
}

final class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

final class OrdersLoaded extends OrdersState {
  const OrdersLoaded(this.orders);
  final List<Order> orders;

  @override
  List<Object?> get props => [orders];
}

final class OrderDetailsLoaded extends OrdersState {
  const OrderDetailsLoaded(this.order);
  final Order order;

  @override
  List<Object?> get props => [order];
}

final class OrdersError extends OrdersState {
  const OrdersError({required this.message, required this.title});

  OrdersError.fromFailure(Failure failure)
      : this(message: failure.message, title: failure.title);

  final String message;
  final String title;

  @override
  List<Object?> get props => [message, title];
}

final class MenuLoadedState extends OrdersState {
  final MenuStatus status;
  final List<MenuItem> items;
  final List<String> categories;
  final String searchQuery;
  final String? errorMessage;
  final String selectedCategory;
  final String sortBy;
  final bool isGridView;
  final MenuOperation? pendingOperation;

  const MenuLoadedState({
    this.status = MenuStatus.initial,
    this.items = const [],
    this.categories = const [],
    this.searchQuery = '',
    this.errorMessage,
    this.selectedCategory = 'All',
    this.sortBy = 'default',
    this.isGridView = false,
    this.pendingOperation,
  });

  int get totalCount => items.length;

  int get availableCount =>
      items.where((i) => i.isAvailable && !i.isOutOfStock).length;

  int get outOfStockCount =>
      items.where((i) => i.isOutOfStock || !i.isAvailable).length;

  List<MenuItem> get featuredItems =>
      items.where((i) => i.isFeatured).toList();

  List<MenuItem> get filteredItems {
    var result = List<MenuItem>.from(items);

    if (selectedCategory != 'All') {
      result = result.where((i) => i.category == selectedCategory).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where(
            (i) =>
                i.name.toLowerCase().contains(q) ||
                i.category.toLowerCase().contains(q) ||
                i.description.toLowerCase().contains(q),
          )
          .toList();
    }

    switch (sortBy) {
      case 'name_asc':
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price_asc':
        result.sort((a, b) {
          final aP =
              double.tryParse(a.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
          final bP =
              double.tryParse(b.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
          return aP.compareTo(bP);
        });
        break;
      case 'price_desc':
        result.sort((a, b) {
          final aP =
              double.tryParse(a.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
          final bP =
              double.tryParse(b.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
          return bP.compareTo(aP);
        });
        break;
      case 'featured':
        result.sort(
          (a, b) =>
              (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0),
        );
        break;
    }

    return result;
  }

  MenuLoadedState copyWith({
    MenuStatus? status,
    List<MenuItem>? items,
    List<String>? categories,
    String? searchQuery,
    String? errorMessage,
    String? selectedCategory,
    String? sortBy,
    bool? isGridView,
    MenuOperation? pendingOperation,
    bool clearPendingOperation = false,
    bool clearError = false,
  }) {
    return MenuLoadedState(
      status: status ?? this.status,
      items: items ?? this.items,
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedCategory: selectedCategory ?? this.selectedCategory,
      sortBy: sortBy ?? this.sortBy,
      isGridView: isGridView ?? this.isGridView,
      pendingOperation: clearPendingOperation
          ? null
          : (pendingOperation ?? this.pendingOperation),
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        categories,
        searchQuery,
        errorMessage,
        selectedCategory,
        sortBy,
        isGridView,
        pendingOperation,
      ];
}
