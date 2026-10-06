import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/common/app/session_aware.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import '../models/customer_withdrawal_model.dart';
import '../repositories/customer_wallet_repository.dart';
import 'customer_withdrawals_state.dart';

/// The customer's withdrawals: list, request, cancel. Actions return the
/// failure message (null on success) so the screen can show it where the
/// customer is looking.
class CustomerWithdrawalsViewModel extends ViewModel<CustomerWithdrawalsState>
    with SessionAware {
  CustomerWithdrawalsViewModel({
    required CustomerWalletRepository repository,
    required CurrentUserProvider session,
  })  : _repository = repository,
        super(const CustomerWithdrawalsState()) {
    bindSession(session);
  }

  final CustomerWalletRepository _repository;

  /// Drops the previous account's withdrawals on logout (see [SessionAware]).
  void reset() => emit(const CustomerWithdrawalsState());

  @override
  void onSignedOut() => reset();

  /// Loads the first page, or the next one with [loadMore]. [silent] keeps
  /// what's on screen instead of showing the spinner — for refreshes after
  /// the customer's own actions.
  Future<void> fetch({bool loadMore = false, bool silent = false}) async {
    if (loadMore) {
      if (state.isLoadingMore || !state.hasMore) return;
      emit(state.copyWith(isLoadingMore: true));
    } else if (!silent || state.status != WithdrawalsStatus.loaded) {
      emit(state.copyWith(status: WithdrawalsStatus.loading, clearError: true));
    }

    final page = loadMore ? state.page + 1 : 1;
    final result = await _repository.getWithdrawals(page: page);

    result.fold(
      (failure) {
        appLogger.w('CustomerWithdrawalsViewModel.fetch → ${failure.message}');
        if (loadMore || (silent && state.status == WithdrawalsStatus.loaded)) {
          emit(state.copyWith(isLoadingMore: false));
        } else {
          emit(state.copyWith(
            status: WithdrawalsStatus.error,
            errorMessage: failure.message,
          ));
        }
      },
      (data) => emit(state.copyWith(
        status: WithdrawalsStatus.loaded,
        withdrawals: loadMore
            ? [...state.withdrawals, ...data.withdrawals]
            : data.withdrawals,
        page: data.page,
        hasMore: data.hasMore,
        isLoadingMore: false,
        clearError: true,
      )),
    );
  }

  /// `POST /customer/withdrawals`. Null on success, else the failure message.
  Future<String?> request(num amount) async {
    if (state.isRequesting) return null;
    emit(state.copyWith(isRequesting: true));

    final result = await _repository.requestWithdrawal(amount: amount);

    final message = result.fold<String?>((failure) {
      appLogger.w('CustomerWithdrawalsViewModel.request → ${failure.message}');
      return failure.message;
    }, (_) => null);
    emit(state.copyWith(isRequesting: false));

    // The server's list is the truth — pick up the new request (and its id).
    if (message == null) await fetch(silent: true);
    return message;
  }

  /// `PATCH /customer/withdrawals/:id/cancel`. Null on success, else the
  /// failure message.
  Future<String?> cancel(String id) async {
    if (state.cancellingId != null) return null;
    emit(state.copyWith(cancellingId: id));

    final result = await _repository.cancelWithdrawal(id);

    final message = result.fold<String?>((failure) {
      appLogger.w('CustomerWithdrawalsViewModel.cancel → ${failure.message}');
      return failure.message;
    }, (updated) {
      // Show it cancelled straight away; the silent refresh below confirms.
      emit(state.copyWith(
        withdrawals: [
          for (final w in state.withdrawals)
            if (w.id == id)
              (updated ?? w).copyWith(status: CustomerWithdrawalStatus.cancelled)
            else
              w,
        ],
      ));
      return null;
    });
    emit(state.copyWith(clearCancelling: true));

    if (message == null) await fetch(silent: true);
    return message;
  }
}
