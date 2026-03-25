import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../models/withdrawal_model.dart';

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
