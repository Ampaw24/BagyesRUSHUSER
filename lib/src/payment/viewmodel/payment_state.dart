import 'package:equatable/equatable.dart';
import 'package:bagyesrushappusernew/core/errors/failure.dart';
import '../model/payment_method.dart';

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

final class PaymentMethodsLoaded extends PaymentState {
  const PaymentMethodsLoaded(this.methods);
  final List<PaymentMethod> methods;

  @override
  List<Object?> get props => [methods];
}

final class PaymentMethodAdded extends PaymentState {
  const PaymentMethodAdded(this.method);
  final PaymentMethod method;

  @override
  List<Object?> get props => [method];
}

final class PaymentMethodDeleted extends PaymentState {
  const PaymentMethodDeleted(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

final class PaymentMethodDefaultSet extends PaymentState {
  const PaymentMethodDefaultSet(this.method);
  final PaymentMethod method;

  @override
  List<Object?> get props => [method];
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
