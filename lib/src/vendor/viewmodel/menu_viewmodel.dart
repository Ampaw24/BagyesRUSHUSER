import 'package:equatable/equatable.dart';
import '../../../core/viewmodel/viewmodel.dart';
import '../model/menu_item.dart';
import '../model/dummy_menu.dart';
import '../repository/vendor_dashboard_repository.dart';

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

class MenuState extends Equatable {
  final MenuStatus status;
  final List<MenuItem> items;
  final String searchQuery;
  final String? errorMessage;
  final String selectedCategory;
  final String sortBy;
  final bool isGridView;
  final MenuOperation? pendingOperation;

  const MenuState({
    this.status = MenuStatus.initial,
    this.items = const [],
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

  MenuState copyWith({
    MenuStatus? status,
    List<MenuItem>? items,
    String? searchQuery,
    String? errorMessage,
    String? selectedCategory,
    String? sortBy,
    bool? isGridView,
    MenuOperation? pendingOperation,
    bool clearPendingOperation = false,
    bool clearError = false,
  }) {
    return MenuState(
      status: status ?? this.status,
      items: items ?? this.items,
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
        searchQuery,
        errorMessage,
        selectedCategory,
        sortBy,
        isGridView,
        pendingOperation,
      ];
}

class MenuViewModel extends ViewModel<MenuState> {
  final VendorDashboardRepository _repository;

  MenuViewModel(this._repository) : super(const MenuState());

  Future<void> loadMenu() async {
    emit(state.copyWith(status: MenuStatus.loading));
    // Simulate network delay — swap with _repository.fetchMenuItems() when API is ready.
    await Future.delayed(const Duration(milliseconds: 600));
    emit(state.copyWith(status: MenuStatus.loaded, items: DummyMenu.items));
  }

  Future<void> addItem(Map<String, dynamic> data) async {
    emit(state.copyWith(pendingOperation: MenuOperation.adding));
    final result = await _repository.createMenuItem(data);
    result.fold(
      (failure) => emit(
        state.copyWith(
          clearPendingOperation: true,
          errorMessage: failure.message,
        ),
      ),
      (newItem) => emit(
        state.copyWith(
          clearPendingOperation: true,
          items: [...state.items, newItem].cast<MenuItem>(),
        ),
      ),
    );
  }

  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    emit(state.copyWith(pendingOperation: MenuOperation.updating));
    final result = await _repository.updateMenuItem(id, data);
    result.fold(
      (failure) => emit(
        state.copyWith(
          clearPendingOperation: true,
          errorMessage: failure.message,
        ),
      ),
      (updated) {
        final updatedList =
            state.items.map((i) => i.id == updated.id ? updated : i).toList();
        emit(
          state.copyWith(clearPendingOperation: true, items: updatedList),
        );
      },
    );
  }

  Future<void> deleteItem(String id) async {
    emit(state.copyWith(pendingOperation: MenuOperation.deleting));
    final result = await _repository.deleteMenuItem(id);
    result.fold(
      (failure) => emit(
        state.copyWith(
          clearPendingOperation: true,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        final updatedList =
            state.items.where((i) => i.id != id).toList();
        emit(
          state.copyWith(clearPendingOperation: true, items: updatedList),
        );
      },
    );
  }

  Future<void> toggleAvailability(String itemId, bool isAvailable) async {
    final result =
        await _repository.toggleMenuItemAvailability(itemId, isAvailable);
    result.fold(
      (failure) =>
          emit(state.copyWith(errorMessage: failure.message)),
      (updated) {
        final updatedList =
            state.items.map((i) => i.id == updated.id ? updated : i).toList();
        emit(state.copyWith(items: updatedList));
      },
    );
  }

  Future<void> toggleFeatured(String itemId, bool isFeatured) async {
    final result = await _repository.updateMenuItem(
      itemId,
      {'is_featured': isFeatured},
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (updated) {
        final updatedList =
            state.items.map((i) => i.id == updated.id ? updated : i).toList();
        emit(state.copyWith(items: updatedList));
      },
    );
  }

  void search(String query) => emit(state.copyWith(searchQuery: query));

  void setCategory(String category) =>
      emit(state.copyWith(selectedCategory: category));

  void setSortBy(String sort) => emit(state.copyWith(sortBy: sort));

  void toggleView() =>
      emit(state.copyWith(isGridView: !state.isGridView));
}
