import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/service_locator.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../models/withdrawal_model.dart';
import '../repositories/wallet_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Wallet state
// ─────────────────────────────────────────────────────────────────────────────

enum WalletStatus { initial, loading, loaded, error }

class WalletState extends Equatable {
  final WalletStatus status;
  final WalletModel wallet;
  final List<TransactionModel> transactions;
  final String? errorMessage;

  const WalletState({
    this.status = WalletStatus.initial,
    this.wallet = const WalletModel(),
    this.transactions = const [],
    this.errorMessage,
  });

  /// Only the most recent 5, shown on the main wallet screen.
  List<TransactionModel> get recentTransactions =>
      transactions.take(5).toList();

  WalletState copyWith({
    WalletStatus? status,
    WalletModel? wallet,
    List<TransactionModel>? transactions,
    String? errorMessage,
    bool clearError = false,
  }) =>
      WalletState(
        status: status ?? this.status,
        wallet: wallet ?? this.wallet,
        transactions: transactions ?? this.transactions,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [status, wallet, transactions, errorMessage];
}

// ─────────────────────────────────────────────────────────────────────────────
// Wallet notifier
// ─────────────────────────────────────────────────────────────────────────────

class WalletNotifier extends Notifier<WalletState> {
  late final WalletRepository _repo;

  @override
  WalletState build() {
    _repo = sl<WalletRepository>();
    return const WalletState();
  }

  Future<void> load() async {
    state = state.copyWith(status: WalletStatus.loading, clearError: true);

    final walletResult = await _repo.fetchWallet();
    final txResult     = await _repo.fetchTransactions();

    walletResult.fold(
      (f) => state = state.copyWith(
        status: WalletStatus.error,
        errorMessage: f.message,
      ),
      (wallet) => txResult.fold(
        (f) => state = state.copyWith(
          status: WalletStatus.error,
          errorMessage: f.message,
        ),
        (txs) => state = state.copyWith(
          status: WalletStatus.loaded,
          wallet: wallet,
          transactions: txs,
        ),
      ),
    );
  }

  /// Called after a successful withdrawal to refresh balance/history.
  void applyWithdrawal(WithdrawalModel withdrawal) {
    final updatedWallet = state.wallet.copyWith(
      availableBalance:
          state.wallet.availableBalance - withdrawal.amount,
      totalWithdrawn: state.wallet.totalWithdrawn + withdrawal.amount,
    );
    final newTx = TransactionModel(
      id: withdrawal.id,
      type: TransactionType.withdrawal,
      status: withdrawal.status,
      amount: withdrawal.amount,
      fee: withdrawal.fee,
      description: 'Withdrawal to ${withdrawal.paymentMethodLabel}',
      paymentMethodLabel: withdrawal.paymentMethodLabel,
      referenceId: withdrawal.referenceCode,
      createdAt: withdrawal.createdAt,
    );
    state = state.copyWith(
      wallet: updatedWallet,
      transactions: [newTx, ...state.transactions],
    );
  }
}

final walletProvider =
    NotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Withdrawal state
// ─────────────────────────────────────────────────────────────────────────────

enum WithdrawalStatus { idle, loading, success, error }

class WithdrawalState extends Equatable {
  final WithdrawalStatus status;
  final String? errorMessage;
  final WithdrawalModel? result;

  // Form fields
  final double amount;
  final String? selectedMethodId;
  final String? selectedMethodLabel;

  const WithdrawalState({
    this.status = WithdrawalStatus.idle,
    this.errorMessage,
    this.result,
    this.amount = 0,
    this.selectedMethodId,
    this.selectedMethodLabel,
  });

  bool get canSubmit =>
      amount >= kMinWithdrawal &&
      selectedMethodId != null &&
      status != WithdrawalStatus.loading;

  double get fee => WithdrawalModel.calculateFee(amount);
  double get net => WithdrawalModel.calculateNet(amount);

  WithdrawalState copyWith({
    WithdrawalStatus? status,
    String? errorMessage,
    WithdrawalModel? result,
    double? amount,
    String? selectedMethodId,
    String? selectedMethodLabel,
    bool clearError = false,
  }) =>
      WithdrawalState(
        status: status ?? this.status,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        result: result ?? this.result,
        amount: amount ?? this.amount,
        selectedMethodId: selectedMethodId ?? this.selectedMethodId,
        selectedMethodLabel: selectedMethodLabel ?? this.selectedMethodLabel,
      );

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        result,
        amount,
        selectedMethodId,
        selectedMethodLabel,
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Withdrawal notifier
// ─────────────────────────────────────────────────────────────────────────────

class WithdrawalNotifier extends Notifier<WithdrawalState> {
  late final WalletRepository _repo;

  @override
  WithdrawalState build() {
    _repo = sl<WalletRepository>();
    return const WithdrawalState();
  }

  void setAmount(double amount) =>
      state = state.copyWith(amount: amount, clearError: true);

  void selectMethod(String id, String label) =>
      state = state.copyWith(
        selectedMethodId: id,
        selectedMethodLabel: label,
        clearError: true,
      );

  Future<void> submit() async {
    if (!state.canSubmit) return;
    state = state.copyWith(status: WithdrawalStatus.loading, clearError: true);

    final result = await _repo.requestWithdrawal(
      amount: state.amount,
      paymentMethodId: state.selectedMethodId!,
      paymentMethodLabel: state.selectedMethodLabel!,
    );

    result.fold(
      (f) => state = state.copyWith(
        status: WithdrawalStatus.error,
        errorMessage: f.message,
      ),
      (withdrawal) {
        state = state.copyWith(
          status: WithdrawalStatus.success,
          result: withdrawal,
        );
        // Update wallet balance in parallel provider
        ref.read(walletProvider.notifier).applyWithdrawal(withdrawal);
      },
    );
  }

  void reset() => state = const WithdrawalState();
}

final withdrawalProvider =
    NotifierProvider<WithdrawalNotifier, WithdrawalState>(
  WithdrawalNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Transaction filter provider (for history screen)
// ─────────────────────────────────────────────────────────────────────────────

enum TxFilter { all, credits, withdrawals }

final txFilterProvider = StateProvider<TxFilter>((ref) => TxFilter.all);

final filteredTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final txs    = ref.watch(walletProvider).transactions;
  final filter = ref.watch(txFilterProvider);
  return switch (filter) {
    TxFilter.all         => txs,
    TxFilter.credits     => txs.where((t) => t.isCredit).toList(),
    TxFilter.withdrawals => txs.where((t) => t.isDebit).toList(),
  };
});
