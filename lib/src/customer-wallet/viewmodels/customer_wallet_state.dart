import 'package:equatable/equatable.dart';
import 'package:bagyesrushappusernew/core/errors/failure.dart';
import '../models/customer_wallet_model.dart';

sealed class CustomerWalletState extends Equatable {
  const CustomerWalletState();
  @override
  List<Object?> get props => [];
}

final class CustomerWalletInitial extends CustomerWalletState {
  const CustomerWalletInitial();
}

final class CustomerWalletLoading extends CustomerWalletState {
  const CustomerWalletLoading();
}

final class CustomerWalletLoaded extends CustomerWalletState {
  const CustomerWalletLoaded(this.wallet);
  final CustomerWalletModel wallet;

  @override
  List<Object?> get props => [wallet];
}

final class CustomerWalletError extends CustomerWalletState {
  const CustomerWalletError({required this.message, required this.title});

  CustomerWalletError.fromFailure(Failure failure)
    : this(message: failure.message, title: failure.title);

  final String message;
  final String title;

  @override
  List<Object?> get props => [message, title];
}
