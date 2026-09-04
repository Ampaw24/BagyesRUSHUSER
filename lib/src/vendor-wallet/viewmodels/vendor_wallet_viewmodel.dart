import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import '../models/vendor_wallet_model.dart';
import '../models/vendor_wallet_transaction_model.dart';
import '../models/vendor_withdrawal_model.dart';
import '../repositories/vendor_wallet_repository.dart';
import 'vendor_wallet_state.dart';

class VendorWalletViewmodel extends ViewModel<VendorWalletState> {
  VendorWalletViewmodel({required VendorWalletRepository repository})
    : _repository = repository,
      super(const VendorWalletInitial());

  final VendorWalletRepository _repository;

  /// Last successfully loaded wallet — cached so other screens can read the
  /// balance without re-fetching (mirrors [PaymentViewmodel]'s cached getter).
  VendorWalletModel? _wallet;
  VendorWalletModel? get wallet => _wallet;

  VendorWalletTransactionListResult? _transactionsResult;
  VendorWalletTransactionListResult? get transactionsResult => _transactionsResult;

  VendorWithdrawalListResult? _withdrawalsResult;
  VendorWithdrawalListResult? get withdrawalsResult => _withdrawalsResult;

  Future<void> fetchWallet() async {
    appLogger.d('VendorWalletViewmodel.fetchWallet → initiated');
    emit(const VendorWalletLoading());

    final result = await _repository.getWallet();

    result.fold(
      (failure) {
        appLogger.w('VendorWalletViewmodel.fetchWallet → error: ${failure.message}');
        emit(VendorWalletError.fromFailure(failure));
      },
      (data) {
        _wallet = data;
        appLogger.i('VendorWalletViewmodel.fetchWallet → balance=${data.balance}');
        emit(VendorWalletLoaded(data));
      },
    );
  }

  Future<void> fetchTransactions({bool loadMore = false}) async {
    final current = _transactionsResult;

    if (loadMore) {
      if (current == null || !current.hasMore) return;
      emit(
        VendorWalletTransactionsLoaded(result: current, isLoadingMore: true),
      );
    } else {
      emit(const VendorWalletLoading());
    }

    final nextPage = loadMore && current != null ? current.page + 1 : 1;

    appLogger.d('VendorWalletViewmodel.fetchTransactions → page=$nextPage');
    final result = await _repository.getWalletTransactions(page: nextPage);

    result.fold(
      (failure) {
        appLogger.w(
          'VendorWalletViewmodel.fetchTransactions → error: ${failure.message}',
        );
        if (loadMore && current != null) {
          emit(VendorWalletTransactionsLoaded(result: current));
        } else {
          emit(VendorWalletError.fromFailure(failure));
        }
      },
      (data) {
        final merged = loadMore && current != null
            ? VendorWalletTransactionListResult(
                transactions: [...current.transactions, ...data.transactions],
                page: data.page,
                totalPages: data.totalPages,
                total: data.total,
              )
            : data;
        _transactionsResult = merged;
        appLogger.i(
          'VendorWalletViewmodel.fetchTransactions → loaded ${merged.transactions.length} transactions',
        );
        emit(VendorWalletTransactionsLoaded(result: merged));
      },
    );
  }

  Future<void> fetchWithdrawals({bool loadMore = false}) async {
    final current = _withdrawalsResult;

    if (loadMore) {
      if (current == null || !current.hasMore) return;
      emit(VendorWithdrawalsLoaded(result: current, isLoadingMore: true));
    } else {
      emit(const VendorWalletLoading());
    }

    final nextPage = loadMore && current != null ? current.page + 1 : 1;

    appLogger.d('VendorWalletViewmodel.fetchWithdrawals → page=$nextPage');
    final result = await _repository.getWithdrawals(page: nextPage);

    result.fold(
      (failure) {
        appLogger.w(
          'VendorWalletViewmodel.fetchWithdrawals → error: ${failure.message}',
        );
        if (loadMore && current != null) {
          emit(VendorWithdrawalsLoaded(result: current));
        } else {
          emit(VendorWalletError.fromFailure(failure));
        }
      },
      (data) {
        final merged = loadMore && current != null
            ? VendorWithdrawalListResult(
                withdrawals: [...current.withdrawals, ...data.withdrawals],
                page: data.page,
                totalPages: data.totalPages,
                total: data.total,
              )
            : data;
        _withdrawalsResult = merged;
        appLogger.i(
          'VendorWalletViewmodel.fetchWithdrawals → loaded ${merged.withdrawals.length} withdrawals',
        );
        emit(VendorWithdrawalsLoaded(result: merged));
      },
    );
  }

  /// `POST /vendor/me/withdrawals`. Returns `true` on success.
  Future<bool> requestWithdrawal({required num amount}) async {
    appLogger.d('VendorWalletViewmodel.requestWithdrawal → amount=$amount');
    emit(const VendorWalletLoading());

    final result = await _repository.requestWithdrawal(amount: amount);

    return result.fold(
      (failure) {
        appLogger.w(
          'VendorWalletViewmodel.requestWithdrawal → error: ${failure.message}',
        );
        emit(VendorWalletError.fromFailure(failure));
        return false;
      },
      (data) {
        appLogger.i(
          'VendorWalletViewmodel.requestWithdrawal → success id=${data.id}',
        );
        emit(VendorWithdrawalRequested(data));
        return true;
      },
    );
  }

  /// `PATCH /vendor/me/withdrawals/:id/cancel`. Returns `true` on success.
  Future<bool> cancelWithdrawal(String id) async {
    appLogger.d('VendorWalletViewmodel.cancelWithdrawal → id=$id');
    emit(const VendorWalletLoading());

    final result = await _repository.cancelWithdrawal(id);

    return result.fold(
      (failure) {
        appLogger.w(
          'VendorWalletViewmodel.cancelWithdrawal → error: ${failure.message}',
        );
        emit(VendorWalletError.fromFailure(failure));
        return false;
      },
      (data) {
        appLogger.i('VendorWalletViewmodel.cancelWithdrawal → success id=$id');
        emit(VendorWithdrawalCancelled(data));
        return true;
      },
    );
  }

  /// Resets state to [VendorWalletInitial] after a one-shot action has been
  /// handled.
  void resetState() => emit(const VendorWalletInitial());
}
