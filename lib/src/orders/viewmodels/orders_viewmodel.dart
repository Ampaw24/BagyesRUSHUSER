import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/common/app/session_aware.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/vendor/model/menu_item.dart';
import '../repositories/orders_repository.dart';
import 'orders_state.dart';

class OrderViewModel extends ViewModel<OrdersState> with SessionAware {
  OrderViewModel({
    required OrdersRepository repository,
    required CurrentUserProvider session,
  })  : _repository = repository,
        super(const OrdersInitial()) {
    bindSession(session);
  }

  final OrdersRepository _repository;

  void reset() => emit(const OrdersInitial());

  /// Drops the previous account's data on logout (see [SessionAware]).
  @override
  void onSignedOut() => reset();

  // ─── Vendor Menu API State Mutations ───────────────────────────────────────

  MenuLoadedState _getMenuState() {
    return state is MenuLoadedState
        ? state as MenuLoadedState
        : const MenuLoadedState();
  }

  Future<void> loadMenu() async {
    final currentState = _getMenuState();
    emit(currentState.copyWith(status: MenuStatus.loading, clearError: true));

    final menuItemsResult = await _repository.fetchMenuItems();
    final catsResult = await _repository.getCategories();

    // Categories and menu items come from independent calls — a failure in
    // one must never suppress a successful result from the other, so each
    // is folded separately before a single combined emit.
    var categoryNames = currentState.categories;
    var categoryOptions = currentState.categoryOptions;
    catsResult.fold((failure) {}, (categoryList) {
      final activeCategories = categoryList
          .expand((c) => c.categories)
          .where((e) => e.isActive)
          .toList();
      categoryNames = ['All', ...activeCategories.map((e) => e.name)];
      categoryOptions = activeCategories;
    });

    menuItemsResult.fold(
      (failure) => emit(
        currentState.copyWith(
          status: MenuStatus.error,
          errorMessage: failure.message,
          categories: categoryNames,
          categoryOptions: categoryOptions,
        ),
      ),
      (items) => emit(
        currentState.copyWith(
          status: MenuStatus.loaded,
          items: items,
          categories: categoryNames,
          categoryOptions: categoryOptions,
        ),
      ),
    );
  }

  /// Creates a menu item, then — only if creation succeeded — uploads
  /// [imagePath] against the newly created item's id. Returns the created
  /// (and possibly image-updated) item, or `null` if creation itself
  /// failed — a failed image upload after a successful create still
  /// returns the item but leaves an [errorMessage] on the state.
  Future<MenuItem?> addItem(
    Map<String, dynamic> data, {
    String? imagePath,
  }) async {
    final currentState = _getMenuState();
    emit(
      currentState.copyWith(
        pendingOperation: MenuOperation.adding,
        clearError: true,
      ),
    );

    final createResult = await _repository.createMenuItem(data);

    return createResult.fold(
      (failure) async {
        emit(
          _getMenuState().copyWith(
            clearPendingOperation: true,
            errorMessage: failure.message,
          ),
        );
        return null;
      },
      (newItem) async {
        var savedItem = newItem;

        if (imagePath != null) {
          final imageResult = await _repository.uploadMenuItemImage(
            itemId: newItem.id,
            filePath: imagePath,
          );
          imageResult.fold(
            (failure) =>
                emit(_getMenuState().copyWith(errorMessage: failure.message)),
            (updated) => savedItem = updated,
          );
        }

        emit(
          _getMenuState().copyWith(
            clearPendingOperation: true,
            items: [..._getMenuState().items, savedItem],
          ),
        );
        return savedItem;
      },
    );
  }

  /// Updates a menu item, then — only if the update succeeded — uploads
  /// [imagePath] against that item's id. See [addItem] for the same
  /// success/failure contract.
  Future<bool> updateItem(
    String id,
    Map<String, dynamic> data, {
    String? imagePath,
  }) async {
    final currentState = _getMenuState();
    emit(
      currentState.copyWith(
        pendingOperation: MenuOperation.updating,
        clearError: true,
      ),
    );

    final updateResult = await _repository.updateMenuItem(id: id, data: data);

    return updateResult.fold(
      (failure) async {
        emit(
          _getMenuState().copyWith(
            clearPendingOperation: true,
            errorMessage: failure.message,
          ),
        );
        return false;
      },
      (updatedItem) async {
        var savedItem = updatedItem;

        if (imagePath != null) {
          final imageResult = await _repository.uploadMenuItemImage(
            itemId: id,
            filePath: imagePath,
          );
          imageResult.fold(
            (failure) =>
                emit(_getMenuState().copyWith(errorMessage: failure.message)),
            (updated) => savedItem = updated,
          );
        }

        final updatedList = _getMenuState().items
            .map((i) => i.id == savedItem.id ? savedItem : i)
            .toList();
        emit(
          _getMenuState().copyWith(
            clearPendingOperation: true,
            items: updatedList,
          ),
        );
        return true;
      },
    );
  }

  Future<void> deleteItem(String id) async {
    final currentState = _getMenuState();
    emit(currentState.copyWith(pendingOperation: MenuOperation.deleting));

    final result = await _repository.deleteMenuItem(id: id);

    result.fold(
      (failure) => emit(
        currentState.copyWith(
          clearPendingOperation: true,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        final updatedList = currentState.items
            .where((i) => i.id != id)
            .toList();
        emit(
          currentState.copyWith(
            clearPendingOperation: true,
            items: updatedList,
          ),
        );
      },
    );
  }

  Future<bool> uploadItemImage(String itemId, String filePath) async {
    final currentState = _getMenuState();
    emit(
      currentState.copyWith(
        pendingOperation: MenuOperation.updating,
        clearError: true,
      ),
    );

    final result = await _repository.uploadMenuItemImage(
      itemId: itemId,
      filePath: filePath,
    );

    return result.fold(
      (failure) {
        emit(
          _getMenuState().copyWith(
            clearPendingOperation: true,
            errorMessage: failure.message,
          ),
        );
        return false;
      },
      (updated) {
        final updatedList = _getMenuState().items
            .map((i) => i.id == updated.id ? updated : i)
            .toList();
        emit(
          _getMenuState().copyWith(
            clearPendingOperation: true,
            items: updatedList,
          ),
        );
        return true;
      },
    );
  }

  Future<void> toggleAvailability(String itemId, bool isAvailable) async {
    final currentState = _getMenuState();
    final result = await _repository.toggleMenuItemAvailability(
      itemId: itemId,
      isAvailable: isAvailable,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(errorMessage: failure.message)),
      (updated) {
        final updatedList = currentState.items
            .map((i) => i.id == updated.id ? updated : i)
            .toList();
        emit(currentState.copyWith(items: updatedList));
      },
    );
  }

  /// Flips [MenuItem.isPopular] via the general-purpose `PUT
  /// /vendor/me/menu-items/:id` endpoint — there's no dedicated toggle route
  /// for this flag (unlike availability's `toggle-availability`), and that
  /// endpoint is a full-replace, so the request is built from the item's
  /// already-loaded fields rather than sending `is_popular` alone. Bails out
  /// instead of submitting if the item's category can't be resolved from
  /// [MenuLoadedState.categoryOptions], since sending a null `category_id`
  /// would clear the item's category server-side.
  Future<void> toggleFeatured(String itemId, bool isPopular) async {
    final currentState = _getMenuState();
    final itemIndex = currentState.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) return;
    final item = currentState.items[itemIndex];

    final categoryIndex = currentState.categoryOptions
        .indexWhere((c) => c.name == item.category);
    if (categoryIndex == -1) {
      emit(currentState.copyWith(
        errorMessage: "Couldn't find this item's category — refresh the menu and try again.",
      ));
      return;
    }

    final data = <String, dynamic>{
      'name': item.name,
      'description': item.description,
      'price': double.tryParse(item.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0,
      'category_id': currentState.categoryOptions[categoryIndex].id,
      'is_available': item.isAvailable,
      'is_popular': isPopular,
      'minimum_order_qty': item.minimumOrderQty,
      if (item.maximumOrderQty != null) 'maximum_order_qty': item.maximumOrderQty,
      'addon_groups': item.addonGroups.map((g) => g.toJson()).toList(),
    };

    final result = await _repository.updateMenuItem(id: itemId, data: data);

    result.fold(
      (failure) => emit(currentState.copyWith(errorMessage: failure.message)),
      (updated) {
        final updatedList = currentState.items
            .map((i) => i.id == updated.id ? updated : i)
            .toList();
        emit(currentState.copyWith(items: updatedList));
      },
    );
  }

  void clearError() => emit(_getMenuState().copyWith(clearError: true));

  void search(String query) =>
      emit(_getMenuState().copyWith(searchQuery: query));

  void setCategory(String category) =>
      emit(_getMenuState().copyWith(selectedCategory: category));

  void setSortBy(String sort) => emit(_getMenuState().copyWith(sortBy: sort));

  void toggleView() =>
      emit(_getMenuState().copyWith(isGridView: !_getMenuState().isGridView));
}
