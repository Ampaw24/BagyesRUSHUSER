import 'package:equatable/equatable.dart';
import 'package:bagyesrushappusernew/core/errors/failure.dart';
import '../models/transaction_model.dart';

sealed class TransactionState extends Equatable {
  const TransactionState();
  @override
  List<Object?> get props => [];
}

final class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

final class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

final class TransactionsLoaded extends TransactionState {
  const TransactionsLoaded({
    required this.transactions,
    required this.meta,
    this.isLoadingMore = false,
  });

  final List<TransactionModel> transactions;
  final TransactionMeta meta;
  final bool isLoadingMore;

  TransactionsLoaded copyWith({
    List<TransactionModel>? transactions,
    TransactionMeta? meta,
    bool? isLoadingMore,
  }) {
    return TransactionsLoaded(
      transactions: transactions ?? this.transactions,
      meta: meta ?? this.meta,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [transactions, meta, isLoadingMore];
}

final class TransactionError extends TransactionState {
  const TransactionError({required this.message, required this.title});

  TransactionError.fromFailure(Failure failure)
    : this(message: failure.message, title: failure.title);

  final String message;
  final String title;

  @override
  List<Object?> get props => [message, title];
}
