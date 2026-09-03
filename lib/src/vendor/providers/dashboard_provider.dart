import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/errors/failure.dart';
import '../model/vendor_order.dart';
import '../repository/vendor_dashboard_repository.dart';
import 'package:equatable/equatable.dart';

// ── State ────────────────────────────────────────────────────────────────

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState extends Equatable {
  final DashboardStatus status;
  final bool storeOpen;
  final String todayRevenue;
  final int activeOrderCount;
  final String avgRating;
  final List<VendorOrder> activeOrders;
  final String? errorMessage;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.storeOpen = false,
    this.todayRevenue = 'GH₵ 0',
    this.activeOrderCount = 0,
    this.avgRating = '0.0',
    this.activeOrders = const [],
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    bool? storeOpen,
    String? todayRevenue,
    int? activeOrderCount,
    String? avgRating,
    List<VendorOrder>? activeOrders,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      storeOpen: storeOpen ?? this.storeOpen,
      todayRevenue: todayRevenue ?? this.todayRevenue,
      activeOrderCount: activeOrderCount ?? this.activeOrderCount,
      avgRating: avgRating ?? this.avgRating,
      activeOrders: activeOrders ?? this.activeOrders,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        storeOpen,
        todayRevenue,
        activeOrderCount,
        avgRating,
        activeOrders,
        errorMessage,
      ];
}

// ── Notifier ─────────────────────────────────────────────────────────────

class DashboardNotifier extends Notifier<DashboardState> {
  late final VendorDashboardRepository _repository;

  @override
  DashboardState build() {
    _repository = sl<VendorDashboardRepository>();
    return const DashboardState();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(status: DashboardStatus.loading);

    final statsResult = await _repository.fetchDashboardStats();
    final ordersResult = await _repository.fetchActiveOrders();

    statsResult.fold(
      (failure) => state = state.copyWith(
        status: DashboardStatus.error,
        errorMessage: failure.message,
      ),
      (stats) {
        ordersResult.fold(
          (failure) => state = state.copyWith(
            status: DashboardStatus.error,
            errorMessage: failure.message,
          ),
          (orders) => state = state.copyWith(
            status: DashboardStatus.loaded,
            todayRevenue: 'GH₵ ${stats.today.revenue.toStringAsFixed(2)}',
            activeOrderCount: orders.length,
            avgRating: stats.reputation.rating.toStringAsFixed(1),
            activeOrders: orders,
            errorMessage: null,
          ),
        );
      },
    );
  }

  /// The dashboard endpoint doesn't report open/closed status — seed it from
  /// the vendor's profile (`VendorProfile.isOpenNow`, the server-computed
  /// status also used by customers' restaurant cards) once, before
  /// [loadDashboard] runs. Subsequent changes come from [toggleStore]'s
  /// server response.
  void seedStoreOpen(bool isOpen) {
    state = state.copyWith(storeOpen: isOpen);
  }

  Future<void> _applyOrderAction(
    String orderId,
    Future<Either<Failure, VendorOrder>> Function() call, {
    bool removeFromActive = false,
  }) async {
    final result = await call();
    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (updated) {
        final updatedList = removeFromActive
            ? state.activeOrders.where((o) => o.id != updated.id).toList()
            : state.activeOrders
                .map((o) => o.id == updated.id ? updated : o)
                .toList();
        state = state.copyWith(activeOrders: updatedList, errorMessage: null);
      },
    );
  }

  Future<void> acceptOrder(String orderId, {int? estimatedPrepMinutes}) =>
      _applyOrderAction(
        orderId,
        () => _repository.acceptOrder(
          orderId,
          estimatedPrepMinutes: estimatedPrepMinutes,
        ),
        removeFromActive: true,
      );

  Future<void> rejectOrder(String orderId, {required String reason}) =>
      _applyOrderAction(
        orderId,
        () => _repository.rejectOrder(orderId, reason: reason),
        removeFromActive: true,
      );

  Future<void> markPreparing(String orderId) => _applyOrderAction(
      orderId, () => _repository.markPreparing(orderId),
      removeFromActive: true);

  Future<void> markReady(String orderId) => _applyOrderAction(
      orderId, () => _repository.markReady(orderId),
      removeFromActive: true);

  Future<void> markOutForDelivery(String orderId) => _applyOrderAction(
      orderId, () => _repository.markOutForDelivery(orderId),
      removeFromActive: true);

  Future<void> markDelivered(String orderId) => _applyOrderAction(
      orderId, () => _repository.markDelivered(orderId),
      removeFromActive: true);

  Future<void> cancelOrder(String orderId, {required String reason}) =>
      _applyOrderAction(
        orderId,
        () => _repository.cancelOrder(orderId, reason: reason),
        removeFromActive: true,
      );

  Future<void> toggleStore(bool isOpen) async {
    final previous = state.storeOpen;
    // Optimistic update
    state = state.copyWith(storeOpen: isOpen);

    final result = await _repository.toggleStoreStatus();
    await result.fold(
      (failure) async {
        // Revert on failure
        state = state.copyWith(
          storeOpen: previous,
          errorMessage: failure.message,
        );
      },
      (serverIsOpen) async {
        if (serverIsOpen == isOpen) {
          state = state.copyWith(storeOpen: serverIsOpen, errorMessage: null);
          return;
        }
        // `toggle-open` is a stateless flip, not a "set to X" call — if our
        // locally-tracked storeOpen had drifted from the server's, this
        // flip lands opposite of what the user asked for. Issue one
        // corrective flip so it converges to the requested state right
        // away instead of requiring a second tap.
        final retry = await _repository.toggleStoreStatus();
        retry.fold(
          (failure) => state = state.copyWith(
            storeOpen: serverIsOpen,
            errorMessage: failure.message,
          ),
          (correctedIsOpen) => state = state.copyWith(
            storeOpen: correctedIsOpen,
            errorMessage: null,
          ),
        );
      },
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────────────

final dashboardProvider =
    NotifierProvider<DashboardNotifier, DashboardState>(DashboardNotifier.new);
