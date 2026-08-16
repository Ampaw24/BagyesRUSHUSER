import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/vendor/model/menu_item.dart';
import '../repositories/orders_repository.dart';
import 'orders_state.dart';

class OrderViewModel extends ViewModel<OrdersState> {
  OrderViewModel({
    required OrdersRepository repository,
  })  : _repository = repository,
        super(const OrdersInitial());

  final OrdersRepository _repository;

  Future<void> getCustomerOrders() async {
    appLogger.d('OrdersViewModel.getCustomerOrders → initiated');
    emit(const OrdersLoading());

    final result = await _repository.getCustomerOrders();

    result.fold(
      (failure) {
        appLogger.w('OrdersViewModel.getCustomerOrders → error: ${failure.message}');
        emit(OrdersError.fromFailure(failure));
      },
      (orders) {
        appLogger.i('OrdersViewModel.getCustomerOrders → loaded ${orders.length} orders');
        emit(OrdersLoaded(orders));
      },
    );
  }

  Future<void> getOrderById(String orderId) async {
    appLogger.d('OrdersViewModel.getOrderById → id=$orderId');
    emit(const OrdersLoading());

    final result = await _repository.getOrderById(orderId: orderId);

    result.fold(
      (failure) {
        appLogger.w('OrdersViewModel.getOrderById → error: ${failure.message}');
        emit(OrdersError.fromFailure(failure));
      },
      (order) {
        appLogger.i('OrdersViewModel.getOrderById → success');
        emit(OrderDetailsLoaded(order));
      },
    );
  }

  // ─── Vendor Menu API State Mutations ───────────────────────────────────────

  MenuLoadedState _getMenuState() {
    return state is MenuLoadedState ? state as MenuLoadedState : const MenuLoadedState();
  }

  Future<void> loadMenu() async {
    final currentState = _getMenuState();
    emit(currentState.copyWith(status: MenuStatus.loading, clearError: true));

    final menuItemsResult = await _repository.fetchMenuItems();
    final catsResult = await _repository.getCategories();

    menuItemsResult.fold(
      (failure) => emit(
        currentState.copyWith(
          status: MenuStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (items) {
        catsResult.fold(
          (failure) {
            // If categories fail, we still show items but with default categories
            emit(currentState.copyWith(
              status: MenuStatus.loaded,
              items: items,
            ));
          },
          (categoryList) {
            final apiCategories = categoryList
                .expand((c) => c.categories)
                .where((e) => e.isActive)
                .map((e) => e.name)
                .toList();

            emit(currentState.copyWith(
              status: MenuStatus.loaded,
              items: items,
              categories: ['All', ...apiCategories],
            ));
          },
        );
      },
    );
  }

  Future<void> addItem(Map<String, dynamic> data) async {
    final currentState = _getMenuState();
    emit(currentState.copyWith(pendingOperation: MenuOperation.adding));

    final result = await _repository.createMenuItem(data);

    result.fold(
      (failure) => emit(
        currentState.copyWith(
          clearPendingOperation: true,
          errorMessage: failure.message,
        ),
      ),
      (newItem) => emit(
        currentState.copyWith(
          clearPendingOperation: true,
          items: [...currentState.items, newItem].cast<MenuItem>(),
        ),
      ),
    );
  }

  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    final currentState = _getMenuState();
    emit(currentState.copyWith(pendingOperation: MenuOperation.updating));

    final result = await _repository.updateMenuItem(id: id, data: data);

    result.fold(
      (failure) => emit(
        currentState.copyWith(
          clearPendingOperation: true,
          errorMessage: failure.message,
        ),
      ),
      (updated) {
        final updatedList =
            currentState.items.map((i) => i.id == updated.id ? updated : i).toList();
        emit(
          currentState.copyWith(clearPendingOperation: true, items: updatedList),
        );
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
        final updatedList =
            currentState.items.where((i) => i.id != id).toList();
        emit(
          currentState.copyWith(clearPendingOperation: true, items: updatedList),
        );
      },
    );
  }

  Future<void> uploadItemImage(String itemId, String filePath) async {
    final currentState = _getMenuState();
    emit(currentState.copyWith(pendingOperation: MenuOperation.updating));

    final result =
        await _repository.uploadMenuItemImage(itemId: itemId, filePath: filePath);

    result.fold(
      (failure) => emit(
        currentState.copyWith(
          clearPendingOperation: true,
          errorMessage: failure.message,
        ),
      ),
      (updated) {
        final updatedList =
            currentState.items.map((i) => i.id == updated.id ? updated : i).toList();
        emit(
          currentState.copyWith(clearPendingOperation: true, items: updatedList),
        );
      },
    );
  }

  Future<void> toggleAvailability(String itemId, bool isAvailable) async {
    final currentState = _getMenuState();
    final result =
        await _repository.toggleMenuItemAvailability(itemId: itemId, isAvailable: isAvailable);

    result.fold(
      (failure) =>
          emit(currentState.copyWith(errorMessage: failure.message)),
      (updated) {
        final updatedList =
            currentState.items.map((i) => i.id == updated.id ? updated : i).toList();
        emit(currentState.copyWith(items: updatedList));
      },
    );
  }

  Future<void> toggleFeatured(String itemId, bool isFeatured) async {
    final currentState = _getMenuState();
    final result = await _repository.toggleMenuItemPopular(itemId: itemId, isPopular: isFeatured);

    result.fold(
      (failure) => emit(currentState.copyWith(errorMessage: failure.message)),
      (updated) {
        final updatedList =
            currentState.items.map((i) => i.id == updated.id ? updated : i).toList();
        emit(currentState.copyWith(items: updatedList));
      },
    );
  }

  void clearError() => emit(_getMenuState().copyWith(clearError: true));

  void search(String query) => emit(_getMenuState().copyWith(searchQuery: query));

  void setCategory(String category) =>
      emit(_getMenuState().copyWith(selectedCategory: category));

  void setSortBy(String sort) => emit(_getMenuState().copyWith(sortBy: sort));

  void toggleView() =>
      emit(_getMenuState().copyWith(isGridView: !_getMenuState().isGridView));
}
