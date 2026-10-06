import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import '../repositories/customer_wallet_repository.dart';

class PayoutSetupState extends Equatable {
  const PayoutSetupState({
    this.selectedProviderId,
    this.isSaving = false,
    this.errorMessage,
  });

  final int? selectedProviderId;
  final bool isSaving;
  final String? errorMessage;

  bool get canSave => selectedProviderId != null && !isSaving;

  PayoutSetupState copyWith({
    int? selectedProviderId,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PayoutSetupState(
      selectedProviderId: selectedProviderId ?? this.selectedProviderId,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [selectedProviderId, isSaving, errorMessage];
}

/// Choosing the network the customer's verified phone number is paid out
/// through (`PUT /customer/wallet/payout-method`).
class PayoutSetupViewModel extends ViewModel<PayoutSetupState> {
  PayoutSetupViewModel({required CustomerWalletRepository repository})
      : _repository = repository,
        super(const PayoutSetupState());

  final CustomerWalletRepository _repository;

  void select(int providerId) {
    if (state.isSaving) return;
    emit(state.copyWith(selectedProviderId: providerId, clearError: true));
  }

  /// True once saved; otherwise the server's message is in [state].
  Future<bool> save() async {
    final providerId = state.selectedProviderId;
    if (providerId == null || state.isSaving) return false;
    emit(state.copyWith(isSaving: true, clearError: true));

    final result = await _repository.setPayoutMethod(payoutProviderId: providerId);

    return result.fold((failure) {
      appLogger.w('PayoutSetupViewModel.save → ${failure.message}');
      emit(state.copyWith(isSaving: false, errorMessage: failure.message));
      return false;
    }, (_) {
      emit(state.copyWith(isSaving: false));
      return true;
    });
  }
}
