import 'package:equatable/equatable.dart';

import '../models/customer_withdrawal_model.dart';

enum WithdrawalsStatus { initial, loading, loaded, error }

class CustomerWithdrawalsState extends Equatable {
  const CustomerWithdrawalsState({
    this.status = WithdrawalsStatus.initial,
    this.withdrawals = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.isRequesting = false,
    this.cancellingId,
  });

  final WithdrawalsStatus status;
  final List<CustomerWithdrawalModel> withdrawals;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;

  /// A withdrawal request is in flight.
  final bool isRequesting;

  /// The id of the withdrawal whose cancellation is in flight.
  final String? cancellingId;

  int get pendingCount => withdrawals.where((w) => w.isCancellable).length;

  CustomerWithdrawalsState copyWith({
    WithdrawalsStatus? status,
    List<CustomerWithdrawalModel>? withdrawals,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    bool? isRequesting,
    String? cancellingId,
    bool clearCancelling = false,
  }) {
    return CustomerWithdrawalsState(
      status: status ?? this.status,
      withdrawals: withdrawals ?? this.withdrawals,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isRequesting: isRequesting ?? this.isRequesting,
      cancellingId: clearCancelling ? null : (cancellingId ?? this.cancellingId),
    );
  }

  @override
  List<Object?> get props => [
    status,
    withdrawals,
    page,
    hasMore,
    isLoadingMore,
    errorMessage,
    isRequesting,
    cancellingId,
  ];
}
