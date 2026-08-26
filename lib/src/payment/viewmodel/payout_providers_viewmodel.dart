import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import '../model/payout_provider_model.dart';
import '../repository/payment_repository.dart';
import 'payout_providers_state.dart';

/// Shared, cached catalog of live payout providers (banks + mobile money).
///
/// Registered as a single app-wide instance so every payout screen reads
/// from the same in-memory list instead of re-fetching on each visit.
class PayoutProvidersViewModel extends ViewModel<PayoutProvidersState> {
  PayoutProvidersViewModel({required PaymentRepository repository})
      : _repository = repository,
        super(const PayoutProvidersInitial());

  final PaymentRepository _repository;

  List<PayoutProviderModel> get banks =>
      switch (state) { PayoutProvidersLoaded(:final banks) => banks, _ => const [] };

  List<PayoutProviderModel> get mobileMoneyProviders => switch (state) {
        PayoutProvidersLoaded(:final mobileMoneyProviders) => mobileMoneyProviders,
        _ => const [],
      };

  bool get isLoading => state is PayoutProvidersLoading;

  String? get error =>
      switch (state) { PayoutProvidersError(:final message) => message, _ => null };

  Future<void> load({bool force = false}) async {
    if (!force && state is PayoutProvidersLoaded) return;
    if (state is PayoutProvidersLoading) return;

    appLogger.d('PayoutProvidersViewModel.load → initiated');
    emit(const PayoutProvidersLoading());

    final result = await _repository.getPayoutProviders();

    result.fold(
      (failure) {
        appLogger.w('PayoutProvidersViewModel.load → error: ${failure.message}');
        emit(PayoutProvidersError(failure.message));
      },
      (providers) {
        appLogger.i('PayoutProvidersViewModel.load → loaded ${providers.length} providers');
        emit(PayoutProvidersLoaded(providers));
      },
    );
  }
}
