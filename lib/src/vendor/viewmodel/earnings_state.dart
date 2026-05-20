import 'package:equatable/equatable.dart';
import '../../../core/errors/failure.dart';
import '../model/earnings_data.dart';

enum TransactionFilter { all, credits, debits }

sealed class EarningsState extends Equatable {
  const EarningsState();

  @override
  List<Object?> get props => [];
}

final class EarningsInitial extends EarningsState {
  const EarningsInitial();
}

final class EarningsLoading extends EarningsState {
  const EarningsLoading(this.selectedPeriod);

  final String selectedPeriod;

  @override
  List<Object?> get props => [selectedPeriod];
}

final class EarningsLoaded extends EarningsState {
  const EarningsLoaded({
    required this.data,
    required this.selectedPeriod,
    this.transactionFilter = TransactionFilter.all,
  });

  final EarningsData data;
  final String selectedPeriod;
  final TransactionFilter transactionFilter;

  EarningsLoaded copyWith({
    EarningsData? data,
    String? selectedPeriod,
    TransactionFilter? transactionFilter,
  }) =>
      EarningsLoaded(
        data: data ?? this.data,
        selectedPeriod: selectedPeriod ?? this.selectedPeriod,
        transactionFilter: transactionFilter ?? this.transactionFilter,
      );

  List<Transaction> get filteredTransactions => switch (transactionFilter) {
        TransactionFilter.all => data.transactions,
        TransactionFilter.credits =>
          data.transactions.where((t) => t.type == 'credit').toList(),
        TransactionFilter.debits =>
          data.transactions.where((t) => t.type == 'debit').toList(),
      };

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
  List<Object?> get props => [data, selectedPeriod, transactionFilter];
}

final class EarningsError extends EarningsState {
  const EarningsError({required this.message, required this.title});

  EarningsError.fromFailure(Failure failure)
      : this(message: failure.message, title: failure.title);

  final String message;
  final String title;

  @override
  List<Object?> get props => [message, title];
}
