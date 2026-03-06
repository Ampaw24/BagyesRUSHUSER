import 'package:equatable/equatable.dart';
import '../../../core/viewmodel/viewmodel.dart';
import '../model/earnings_data.dart';
import '../repository/vendor_dashboard_repository.dart';

enum EarningsStatus { initial, loading, loaded, error }

class EarningsState extends Equatable {
  final EarningsStatus status;
  final EarningsData data;
  final String selectedPeriod; // 'today' | 'week' | 'month' | 'all'
  final String? errorMessage;

  const EarningsState({
    this.status = EarningsStatus.initial,
    this.data = const EarningsData(),
    this.selectedPeriod = 'today',
    this.errorMessage,
  });

  EarningsState copyWith({
    EarningsStatus? status,
    EarningsData? data,
    String? selectedPeriod,
    String? errorMessage,
  }) {
    return EarningsState(
      status: status ?? this.status,
      data: data ?? this.data,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, selectedPeriod, errorMessage];
}

class EarningsViewModel extends ViewModel<EarningsState> {
  final VendorDashboardRepository _repository;

  EarningsViewModel(this._repository) : super(const EarningsState());

  Future<void> loadEarnings({String? period}) async {
    emit(state.copyWith(
      status: EarningsStatus.loading,
      selectedPeriod: period ?? state.selectedPeriod,
    ));

    final result = await _repository.fetchEarnings(
      period: period ?? state.selectedPeriod,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: EarningsStatus.error,
        errorMessage: failure.message,
      )),
      (data) => emit(state.copyWith(
        status: EarningsStatus.loaded,
        data: data,
      )),
    );
  }
}
