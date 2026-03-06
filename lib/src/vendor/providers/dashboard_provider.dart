import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/service_locator.dart';
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
    this.storeOpen = true,
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
            storeOpen: stats['store_open'] as bool? ?? state.storeOpen,
            todayRevenue: stats['today_revenue'] as String? ?? 'GH₵ 0',
            activeOrderCount: stats['active_order_count'] as int? ?? 0,
            avgRating: stats['avg_rating'] as String? ?? '0.0',
            activeOrders: orders,
          ),
        );
      },
    );
  }

  Future<void> toggleStore(bool isOpen) async {
    final previous = state.storeOpen;
    // Optimistic update
    state = state.copyWith(storeOpen: isOpen);

    final result = await _repository.toggleStoreStatus(isOpen);
    result.fold(
      (failure) {
        // Revert on failure
        state = state.copyWith(
          storeOpen: previous,
          errorMessage: failure.message,
        );
      },
      (_) {
        // Clear any previous error on success
        state = state.copyWith(errorMessage: null);
      },
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────────────

final dashboardProvider =
    NotifierProvider<DashboardNotifier, DashboardState>(DashboardNotifier.new);
