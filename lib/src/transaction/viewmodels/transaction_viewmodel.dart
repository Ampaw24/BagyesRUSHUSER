import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import '../repositories/transaction_repository.dart';
import 'transaction_state.dart';

class TransactionViewmodel extends ViewModel<TransactionState> {
  TransactionViewmodel({required TransactionRepository repository})
    : _repository = repository,
      super(const TransactionInitial());

  final TransactionRepository _repository;

  Future<void> fetchTransactions({bool loadMore = false}) async {
    final currentState = state;

    if (loadMore) {
      if (currentState is! TransactionsLoaded ||
          !currentState.meta.hasMore ||
          currentState.isLoadingMore) {
        return;
      }
      emit(currentState.copyWith(isLoadingMore: true));
    } else {
      emit(const TransactionLoading());
    }

    final nextPage = loadMore && currentState is TransactionsLoaded
        ? currentState.meta.page + 1
        : 1;

    appLogger.d('TransactionViewmodel.fetchTransactions → page=$nextPage');
    final result = await _repository.getCustomerTransactions(page: nextPage);

    result.fold(
      (failure) {
        appLogger.w(
          'TransactionViewmodel.fetchTransactions → error: ${failure.message}',
        );
        if (loadMore && currentState is TransactionsLoaded) {
          emit(currentState.copyWith(isLoadingMore: false));
        } else {
          emit(TransactionError.fromFailure(failure));
        }
      },
      (result) {
        appLogger.i(
          'TransactionViewmodel.fetchTransactions → loaded ${result.transactions.length} transactions',
        );
        final merged = loadMore && currentState is TransactionsLoaded
            ? [...currentState.transactions, ...result.transactions]
            : result.transactions;
        emit(TransactionsLoaded(transactions: merged, meta: result.meta));
      },
    );
  }
}
