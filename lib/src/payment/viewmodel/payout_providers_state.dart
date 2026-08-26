import 'package:equatable/equatable.dart';
import '../model/payout_provider_model.dart';

sealed class PayoutProvidersState extends Equatable {
  const PayoutProvidersState();
  @override
  List<Object?> get props => [];
}

final class PayoutProvidersInitial extends PayoutProvidersState {
  const PayoutProvidersInitial();
}

final class PayoutProvidersLoading extends PayoutProvidersState {
  const PayoutProvidersLoading();
}

final class PayoutProvidersLoaded extends PayoutProvidersState {
  const PayoutProvidersLoaded(this.providers);
  final List<PayoutProviderModel> providers;

  List<PayoutProviderModel> get banks =>
      providers.where((p) => p.isBank).toList();

  List<PayoutProviderModel> get mobileMoneyProviders =>
      providers.where((p) => p.isMobileMoney).toList();

  @override
  List<Object?> get props => [providers];
}

final class PayoutProvidersError extends PayoutProvidersState {
  const PayoutProvidersError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
