import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/utils/money_format.dart';
import 'package:bagyesrushappusernew/core/widgets/app_toast.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/models/customer_withdrawal_model.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/viewmodels/customer_withdrawals_viewmodel.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/views/widgets/withdrawals_list.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/viewmodels/customer_wallet_state.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/viewmodels/customer_wallet_viewmodel.dart';
import '../viewmodels/transaction_state.dart';
import '../viewmodels/transaction_viewmodel.dart';
import 'widgets/transaction_tile.dart';
import 'widgets/wallet_balance_card.dart';
import 'widgets/withdraw_sheet.dart';

enum _WalletTab { transactions, withdrawals }

class TransactionView extends StatefulWidget {
  const TransactionView({super.key});

  @override
  State<TransactionView> createState() => _TransactionViewState();
}

class _TransactionViewState extends State<TransactionView> {
  final _scrollController = ScrollController();
  TransactionViewmodel? _vm;
  _WalletTab _tab = _WalletTab.transactions;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm = context.read<TransactionViewmodel>();
      _vm!.fetchTransactions();
      context.read<CustomerWalletViewmodel>().fetchWallet();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _vm?.fetchTransactions(loadMore: true);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Opens the withdraw sheet; what can actually be withdrawn is up to the
  /// sheet's checks and the server, not a pre-emptive block here.
  Future<void> _onWithdraw(CustomerWalletViewmodel walletVm) async {
    final wallet = walletVm.wallet;
    if (wallet == null) return;

    final withdrew = await WithdrawSheet.show(
      context,
      wallet: wallet,
      onAddPayoutMethod: () => _addPayoutMethod(walletVm),
    );
    if (withdrew != true || !mounted) return;
    walletVm.fetchWallet();
    _vm?.fetchTransactions();
    // Land on the new request — it's the one they'll want to track or cancel.
    setState(() => _tab = _WalletTab.withdrawals);
    AppToast.show(
      context,
      isSuccess: true,
      title: 'Withdrawal requested',
      subtitle: 'We\'ll process it shortly. Track or cancel it under Withdrawals.',
    );
  }

  /// Opens the add-payout flow; once saved, refreshes the wallet so its
  /// payout flag clears and the customer can withdraw.
  Future<void> _addPayoutMethod(CustomerWalletViewmodel walletVm) async {
    final saved = await context.push<bool>(AppRoutes.addPayoutMethod);
    if (saved != true || !mounted) return;
    walletVm.fetchWallet();
    AppToast.show(
      context,
      isSuccess: true,
      title: 'Payout method saved',
      subtitle: 'You can now withdraw from your wallet.',
    );
  }

  void _confirmCancel(CustomerWithdrawalModel withdrawal) {
    CustomDialog.showConfirmation(
      context: context,
      title: 'Cancel this withdrawal?',
      subtitle:
          'Your ${formatMoney(withdrawal.amount, currency: withdrawal.currency)} '
          'withdrawal request will be cancelled.',
      confirmText: 'Cancel withdrawal',
      cancelText: 'Keep it',
      onConfirm: () => _cancelWithdrawal(withdrawal),
    );
  }

  Future<void> _cancelWithdrawal(CustomerWithdrawalModel withdrawal) async {
    final withdrawals = context.read<CustomerWithdrawalsViewModel>();
    final wallet = context.read<CustomerWalletViewmodel>();
    final error = await withdrawals.cancel(withdrawal.id);
    if (!mounted) return;
    if (error == null) {
      wallet.fetchWallet();
      AppToast.show(
        context,
        isSuccess: true,
        title: 'Withdrawal cancelled',
        subtitle: 'Your request has been cancelled.',
      );
    } else {
      AppToast.show(
        context,
        isSuccess: false,
        title: 'Couldn\'t cancel',
        subtitle: error,
      );
    }
  }

  /// The payment ledger below the wallet card.
  Widget _buildTransactions(double w) {
    return Consumer<TransactionViewmodel>(
      builder: (context, vm, _) {
        final state = vm.state;

        if (state is TransactionLoading || state is TransactionInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is TransactionError) {
          return _ErrorState(
            message: state.message,
            onRetry: () => vm.fetchTransactions(),
          );
        }

        final loaded = state as TransactionsLoaded;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => vm.fetchTransactions(),
          child: loaded.transactions.isEmpty
              ? _EmptyState(scrollController: _scrollController)
              : ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    w * 0.05,
                    w * 0.02,
                    w * 0.05,
                    w * 0.05,
                  ),
                  itemCount:
                      loaded.transactions.length +
                      (loaded.isLoadingMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i >= loaded.transactions.length) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: w * 0.06),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2.5,
                          ),
                        ),
                      );
                    }
                    return TransactionTile(transaction: loaded.transactions[i]);
                  },
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Transactions')),
      body: Column(
        children: [
          Consumer<CustomerWalletViewmodel>(
            builder: (context, walletVm, _) {
              final state = walletVm.state;
              return WalletBalanceCard(
                wallet: walletVm.wallet,
                isLoading: state is CustomerWalletLoading,
                errorMessage: state is CustomerWalletError
                    ? state.message
                    : null,
                onRetry: () => walletVm.fetchWallet(),
                onWithdraw: () => _onWithdraw(walletVm),
              );
            },
          ),
          _TabToggle(
            selected: _tab,
            onSelected: (tab) => setState(() => _tab = tab),
          ),
          Expanded(
            child: _tab == _WalletTab.withdrawals
                ? WithdrawalsList(onCancel: _confirmCancel)
                : _buildTransactions(w),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: w * 0.18,
                  color: AppColors.textHint,
                ),
                SizedBox(height: w * 0.04),
                Text(
                  'No transactions yet',
                  style: TextStyle(
                    fontSize: w * 0.044,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: w * 0.015),
                Text(
                  'Your transaction history will appear here',
                  style: TextStyle(
                    fontSize: w * 0.033,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: w * 0.18,
              color: AppColors.error,
            ),
            SizedBox(height: w * 0.04),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.036,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: w * 0.05),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Switches between the payment ledger and the customer's withdrawals.
class _TabToggle extends StatelessWidget {
  const _TabToggle({required this.selected, required this.onSelected});

  final _WalletTab selected;
  final ValueChanged<_WalletTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    // A dot on "Withdrawals" while the backend reports money in flight.
    final hasPending = context.select<CustomerWalletViewmodel, bool>(
      (vm) => (vm.wallet?.pendingWithdrawal ?? 0) > 0,
    );

    Widget segment(_WalletTab tab, String label, {bool dot = false}) {
      final isSelected = selected == tab;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelected(tab),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(vertical: w * 0.025),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(w * 0.03),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: w * 0.034,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                if (dot) ...[
                  SizedBox(width: w * 0.015),
                  Container(
                    width: w * 0.02,
                    height: w * 0.02,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.fromLTRB(w * 0.05, w * 0.02, w * 0.05, w * 0.02),
      padding: EdgeInsets.all(w * 0.01),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          segment(_WalletTab.transactions, 'Transactions'),
          segment(_WalletTab.withdrawals, 'Withdrawals', dot: hasPending),
        ],
      ),
    );
  }
}
