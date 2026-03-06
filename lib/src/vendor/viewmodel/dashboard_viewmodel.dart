import 'package:equatable/equatable.dart';
import '../../../core/viewmodel/viewmodel.dart';
import '../model/vendor_order.dart';
import '../repository/vendor_dashboard_repository.dart';

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

class DashboardViewModel extends ViewModel<DashboardState> {
  final VendorDashboardRepository _repository;

  DashboardViewModel(this._repository) : super(const DashboardState());

  Future<void> loadDashboard() async {
    emit(state.copyWith(status: DashboardStatus.loading));

    final statsResult = await _repository.fetchDashboardStats();
    final ordersResult = await _repository.fetchActiveOrders();

    statsResult.fold(
      (failure) => emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: failure.message,
      )),
      (stats) {
        ordersResult.fold(
          (failure) => emit(state.copyWith(
            status: DashboardStatus.error,
            errorMessage: failure.message,
          )),
          (orders) => emit(state.copyWith(
            status: DashboardStatus.loaded,
            todayRevenue: stats['today_revenue'] as String? ?? 'GH₵ 0',
            activeOrderCount: stats['active_order_count'] as int? ?? 0,
            avgRating: stats['avg_rating'] as String? ?? '0.0',
            activeOrders: orders,
          )),
        );
      },
    );
  }

  Future<void> toggleStore(bool isOpen) async {
    final previous = state.storeOpen;
    emit(state.copyWith(storeOpen: isOpen));

    final result = await _repository.toggleStoreStatus(isOpen);
    result.fold(
      (failure) => emit(state.copyWith(
        storeOpen: previous,
        errorMessage: failure.message,
      )),
      (_) {},
    );
  }
}
