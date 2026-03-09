import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../models/withdrawal_model.dart';
import '../services/wallet_api_service.dart';

// ── Abstract ───────────────────────────────────────────────────────────────

abstract class WalletRepository {
  Future<Either<Failure, WalletModel>> fetchWallet();
  Future<Either<Failure, List<TransactionModel>>> fetchTransactions();
  Future<Either<Failure, WithdrawalModel>> requestWithdrawal({
    required double amount,
    required String paymentMethodId,
    required String paymentMethodLabel,
  });
}

// ── Implementation ─────────────────────────────────────────────────────────

class WalletRepositoryImpl implements WalletRepository {
  final WalletApiService _api;

  WalletRepositoryImpl(this._api);

  @override
  Future<Either<Failure, WalletModel>> fetchWallet() =>
      _run(() => _api.fetchWallet());

  @override
  Future<Either<Failure, List<TransactionModel>>> fetchTransactions() =>
      _run(() => _api.fetchTransactions());

  @override
  Future<Either<Failure, WithdrawalModel>> requestWithdrawal({
    required double amount,
    required String paymentMethodId,
    required String paymentMethodLabel,
  }) =>
      _run(
        () => _api.requestWithdrawal(
          amount: amount,
          paymentMethodId: paymentMethodId,
          paymentMethodLabel: paymentMethodLabel,
        ),
      );

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
