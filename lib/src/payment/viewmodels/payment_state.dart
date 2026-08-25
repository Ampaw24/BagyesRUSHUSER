import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/core/errors/failure.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/payment/models/payment_init_result.dart';
import 'package:bagyesrushappusernew/src/payment/models/payment_transaction.dart';
import 'package:bagyesrushappusernew/src/payment/models/payment_verification_result.dart';
import 'package:bagyesrushappusernew/src/payment/models/payment_wallet.dart';

sealed class PaymentState extends Equatable {
  const PaymentState();
  @override
  List<Object?> get props => [];
}

final class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

final class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

final class PaymentInitializeSuccess extends PaymentState {
  const PaymentInitializeSuccess(this.result);
  final PaymentInitResult result;

  @override
  List<Object?> get props => [result];
}

final class PaymentVerifySuccess extends PaymentState {
  const PaymentVerifySuccess(this.result);
  final PaymentVerificationResult result;

  @override
  List<Object?> get props => [result];
}

final class PaymentWalletLoaded extends PaymentState {
  const PaymentWalletLoaded(this.wallet);
  final PaymentWallet wallet;

  @override
  List<Object?> get props => [wallet];
}

final class PaymentTopUpSuccess extends PaymentState {
  const PaymentTopUpSuccess(this.result);
  final PaymentInitResult result;

  @override
  List<Object?> get props => [result];
}

final class PaymentWithdrawSuccess extends PaymentState {
  const PaymentWithdrawSuccess(this.data);
  final DataMap data;

  @override
  List<Object?> get props => [data];
}

final class PaymentHistoryLoaded extends PaymentState {
  const PaymentHistoryLoaded(this.result);
  final PaymentHistoryResult result;

  @override
  List<Object?> get props => [result];
}

final class PaymentError extends PaymentState {
  const PaymentError({required this.message, required this.title});

  PaymentError.fromFailure(Failure failure)
      : this(message: failure.message, title: failure.title);

  final String message;
  final String title;

  @override
  List<Object?> get props => [message, title];
}
