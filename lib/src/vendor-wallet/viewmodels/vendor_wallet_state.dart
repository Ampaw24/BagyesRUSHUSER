import 'package:equatable/equatable.dart';
import 'package:bagyesrushappusernew/core/errors/failure.dart';
import '../models/vendor_wallet_model.dart';
import '../models/vendor_wallet_transaction_model.dart';
import '../models/vendor_withdrawal_model.dart';

sealed class VendorWalletState extends Equatable {
  const VendorWalletState();
  @override
  List<Object?> get props => [];
}

final class VendorWalletInitial extends VendorWalletState {
  const VendorWalletInitial();
}

final class VendorWalletLoading extends VendorWalletState {
  const VendorWalletLoading();
}

final class VendorWalletLoaded extends VendorWalletState {
  const VendorWalletLoaded(this.wallet);
  final VendorWalletModel wallet;

  @override
  List<Object?> get props => [wallet];
}

final class VendorWalletTransactionsLoaded extends VendorWalletState {
  const VendorWalletTransactionsLoaded({
    required this.result,
    this.isLoadingMore = false,
  });

  final VendorWalletTransactionListResult result;
  final bool isLoadingMore;

  VendorWalletTransactionsLoaded copyWith({
    VendorWalletTransactionListResult? result,
    bool? isLoadingMore,
  }) {
    return VendorWalletTransactionsLoaded(
      result: result ?? this.result,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [result, isLoadingMore];
}

final class VendorWithdrawalsLoaded extends VendorWalletState {
  const VendorWithdrawalsLoaded({
    required this.result,
    this.isLoadingMore = false,
  });

  final VendorWithdrawalListResult result;
  final bool isLoadingMore;

  VendorWithdrawalsLoaded copyWith({
    VendorWithdrawalListResult? result,
    bool? isLoadingMore,
  }) {
    return VendorWithdrawalsLoaded(
      result: result ?? this.result,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [result, isLoadingMore];
}

final class VendorWithdrawalRequested extends VendorWalletState {
  const VendorWithdrawalRequested(this.withdrawal);
  final VendorWithdrawalModel withdrawal;

  @override
  List<Object?> get props => [withdrawal];
}

final class VendorWithdrawalCancelled extends VendorWalletState {
  const VendorWithdrawalCancelled(this.withdrawal);
  final VendorWithdrawalModel withdrawal;

  @override
  List<Object?> get props => [withdrawal];
}

final class VendorWalletError extends VendorWalletState {
  const VendorWalletError({required this.message, required this.title});

  VendorWalletError.fromFailure(Failure failure)
    : this(message: failure.message, title: failure.title);

  final String message;
  final String title;

  @override
  List<Object?> get props => [message, title];
}
