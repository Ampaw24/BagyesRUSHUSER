import 'package:equatable/equatable.dart';
import '../../../core/viewmodel/viewmodel.dart';
import '../model/earnings_data.dart';
import '../model/dummy_earnings.dart';

enum EarningsStatus { initial, loading, loaded, error }

enum TransactionFilter { all, credits, debits }

class EarningsState extends Equatable {
  final EarningsStatus status;
  final EarningsData data;
  final String selectedPeriod;
  final TransactionFilter transactionFilter;
  final String? errorMessage;

  const EarningsState({
    this.status = EarningsStatus.initial,
    this.data = const EarningsData(),
    this.selectedPeriod = 'today',
    this.transactionFilter = TransactionFilter.all,
    this.errorMessage,
  });

  EarningsState copyWith({
    EarningsStatus? status,
    EarningsData? data,
    String? selectedPeriod,
    TransactionFilter? transactionFilter,
    String? errorMessage,
  }) {
    return EarningsState(
      status: status ?? this.status,
      data: data ?? this.data,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      transactionFilter: transactionFilter ?? this.transactionFilter,
      errorMessage: errorMessage,
    );
  }

  List<Transaction> get filteredTransactions {
    switch (transactionFilter) {
      case TransactionFilter.all:
        return data.transactions;
      case TransactionFilter.credits:
        return data.transactions.where((t) => t.type == 'credit').toList();
      case TransactionFilter.debits:
        return data.transactions.where((t) => t.type == 'debit').toList();
    }
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
        'week' => 'This Week',
        'month' => 'This Month',
        'all' => 'All Time',
        _ => 'Revenue',
      };

  String get growthComparison => switch (selectedPeriod) {
        'today' => 'vs yesterday',
        'week' => 'vs last week',
        'month' => 'vs last month',
        'all' => 'overall growth',
        _ => '',
      };

  @override
  List<Object?> get props =>
      [status, data, selectedPeriod, transactionFilter, errorMessage];
}

class EarningsViewModel extends ViewModel<EarningsState> {
  EarningsViewModel() : super(const EarningsState());

  /// Load earnings data for a given period.
  /// Uses dummy data until API is ready.
  Future<void> loadEarnings({String? period}) async {
    final p = period ?? state.selectedPeriod;
    emit(state.copyWith(
      status: EarningsStatus.loading,
      selectedPeriod: p,
    ));

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));

    emit(state.copyWith(
      status: EarningsStatus.loaded,
      data: DummyEarnings.getForPeriod(p),
    ));
  }

  void setPeriod(String period) => loadEarnings(period: period);

  void setTransactionFilter(TransactionFilter filter) {
    emit(state.copyWith(transactionFilter: filter));
  }
}
