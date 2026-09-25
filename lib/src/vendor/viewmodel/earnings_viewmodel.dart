import 'package:equatable/equatable.dart';
import '../../../core/viewmodel/viewmodel.dart';
import '../model/earnings_data.dart';
import '../model/vendor_dashboard_stats.dart';
import '../repository/vendor_dashboard_repository.dart';

enum EarningsStatus { initial, loading, loaded, error }

class EarningsState extends Equatable {
  final EarningsStatus status;
  final EarningsData data;

  /// Raw `GET /vendor/me/dashboard` response, kept so switching periods
  /// (via [EarningsViewModel.setPeriod]) can re-derive [data] locally
  /// instead of re-fetching — the endpoint already returns every period's
  /// figures in one response.
  final VendorDashboardStats? stats;
  final String selectedPeriod;
  final String? errorMessage;

  const EarningsState({
    this.status = EarningsStatus.initial,
    this.data = const EarningsData(),
    this.stats,
    this.selectedPeriod = 'today',
    this.errorMessage,
  });

  EarningsState copyWith({
    EarningsStatus? status,
    EarningsData? data,
    VendorDashboardStats? stats,
    String? selectedPeriod,
    String? errorMessage,
  }) {
    return EarningsState(
      status: status ?? this.status,
      data: data ?? this.data,
      stats: stats ?? this.stats,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      errorMessage: errorMessage,
    );
  }

  String get displayRevenue => switch (selectedPeriod) {
        'today' => data.todayRevenue,
        'week' => data.weekRevenue,
        'month' => data.monthRevenue,
        'all' => data.totalRevenue,
        _ => data.todayRevenue,
      };

  String get periodLabel => switch (selectedPeriod) {
        'today' => "Today's Revenue",
        'week' => 'Last 7 Days',
        'month' => 'Last 30 Days',
        'all' => 'All Time',
        _ => 'Revenue',
      };

  @override
  List<Object?> get props => [status, data, stats, selectedPeriod, errorMessage];
}

class EarningsViewModel extends ViewModel<EarningsState> {
  EarningsViewModel(this._repository) : super(const EarningsState());

  final VendorDashboardRepository _repository;

  /// Loads earnings figures from `GET /vendor/me/dashboard` — the same
  /// endpoint the vendor home dashboard uses. This is the only data source
  /// for the earnings page; there's no dedicated earnings endpoint, so
  /// nothing here is backed by placeholder/dummy data.
  Future<void> loadEarnings({String? period}) async {
    final p = period ?? state.selectedPeriod;
    emit(state.copyWith(
      status: EarningsStatus.loading,
      selectedPeriod: p,
    ));

    final result = await _repository.fetchDashboardStats();

    result.fold(
      (failure) => emit(state.copyWith(
        status: EarningsStatus.error,
        errorMessage: failure.message,
      )),
      (stats) => emit(state.copyWith(
        status: EarningsStatus.loaded,
        stats: stats,
        data: _mapDashboardStats(p, stats),
        errorMessage: null,
      )),
    );
  }

  /// Every period's figures already arrived in [loadEarnings]'s single
  /// response, so switching the period chip just re-derives [EarningsData]
  /// from the cached [EarningsState.stats] — no re-fetch needed.
  void setPeriod(String period) {
    final stats = state.stats;
    if (stats == null) {
      loadEarnings(period: period);
      return;
    }
    emit(state.copyWith(
      selectedPeriod: period,
      data: _mapDashboardStats(period, stats),
    ));
  }

  EarningsData _mapDashboardStats(String period, VendorDashboardStats stats) {
    final periodStats = switch (period) {
      'today' => stats.today,
      'week' => stats.last7Days,
      'month' => stats.last30Days,
      _ => stats.allTime,
    };
    final netEarnings = periodStats.revenue - periodStats.commission;

    return EarningsData(
      totalRevenue: _formatCurrency(stats.allTime.revenue),
      todayRevenue: _formatCurrency(stats.today.revenue),
      weekRevenue: _formatCurrency(stats.last7Days.revenue),
      monthRevenue: _formatCurrency(stats.last30Days.revenue),
      totalOrders: periodStats.orders,
      completedOrders: periodStats.delivered,
      cancelledOrders: periodStats.cancelled,
      avgOrderValue: _formatCurrency(periodStats.averageOrderValue),
      completionRate: periodStats.orders > 0
          ? (periodStats.delivered / periodStats.orders) * 100
          : 0.0,
      commission: _formatCurrency(periodStats.commission),
      netEarnings: _formatCurrency(netEarnings),
      topItems: stats.topItems
          .map((t) => TopSellingItem(
                name: t.name,
                orderCount: t.orderCount,
                revenue: _formatCurrency(t.revenue),
              ))
          .toList(),
    );
  }

  String _formatCurrency(double amount) => 'GH₵ ${amount.toStringAsFixed(2)}';
}
