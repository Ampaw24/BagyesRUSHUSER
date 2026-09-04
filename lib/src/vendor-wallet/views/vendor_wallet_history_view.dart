import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/widgets/app_toast.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import '../models/vendor_withdrawal_model.dart';
import '../viewmodels/vendor_wallet_state.dart';
import '../viewmodels/vendor_wallet_viewmodel.dart';
import 'widgets/vendor_wallet_transaction_tile.dart';
import 'widgets/vendor_withdrawal_tile.dart';

/// Full transaction + withdrawal history, each tab independently paginated.
///
/// `VendorWalletState` is a single shared field, so the transactions and
/// withdrawals fetches are run sequentially (never concurrently) — otherwise
/// one call's Loading/Error emission could overwrite the other's before this
/// view reads it. Each tab tracks its own loading/error locally, captured
/// right after its own fetch resolves; list content always comes from the
/// viewmodel's cached `transactionsResult`/`withdrawalsResult` getters, which
/// are safe to read at any time.
class VendorWalletHistoryView extends StatefulWidget {
  const VendorWalletHistoryView({super.key});

  @override
  State<VendorWalletHistoryView> createState() =>
      _VendorWalletHistoryViewState();
}

class _VendorWalletHistoryViewState extends State<VendorWalletHistoryView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _txScrollController = ScrollController();
  final _wdScrollController = ScrollController();
  VendorWalletViewmodel? _vm;

  bool _txLoading = true;
  String? _txError;
  bool _wdLoading = true;
  String? _wdError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _txScrollController.addListener(_onTxScroll);
    _wdScrollController.addListener(_onWdScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _vm = context.read<VendorWalletViewmodel>();
      await _loadTransactions();
      await _loadWithdrawals();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _txScrollController.removeListener(_onTxScroll);
    _txScrollController.dispose();
    _wdScrollController.removeListener(_onWdScroll);
    _wdScrollController.dispose();
    super.dispose();
  }

  void _onTxScroll() {
    if (!_txScrollController.hasClients) return;
    final pos = _txScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) _loadTransactions(loadMore: true);
  }

  void _onWdScroll() {
    if (!_wdScrollController.hasClients) return;
    final pos = _wdScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) _loadWithdrawals(loadMore: true);
  }

  Future<void> _loadTransactions({bool loadMore = false}) async {
    final vm = _vm;
    if (vm == null) return;
    if (!loadMore && mounted) {
      setState(() => _txLoading = vm.transactionsResult == null);
    }
    await vm.fetchTransactions(loadMore: loadMore);
    if (!mounted) return;
    setState(() {
      _txLoading = false;
      _txError = (vm.transactionsResult == null && vm.state is VendorWalletError)
          ? (vm.state as VendorWalletError).message
          : null;
    });
  }

  Future<void> _loadWithdrawals({bool loadMore = false}) async {
    final vm = _vm;
    if (vm == null) return;
    if (!loadMore && mounted) {
      setState(() => _wdLoading = vm.withdrawalsResult == null);
    }
    await vm.fetchWithdrawals(loadMore: loadMore);
    if (!mounted) return;
    setState(() {
      _wdLoading = false;
      _wdError = (vm.withdrawalsResult == null && vm.state is VendorWalletError)
          ? (vm.state as VendorWalletError).message
          : null;
    });
  }

  Future<void> _confirmCancel(VendorWithdrawalModel withdrawal) {
    return CustomDialog.showConfirmation(
      context: context,
      title: 'Cancel withdrawal?',
      subtitle: 'This will cancel your pending withdrawal request.',
      confirmText: 'Cancel Withdrawal',
      cancelText: 'Keep it',
      onConfirm: () => _cancelWithdrawal(withdrawal.id),
    );
  }

  Future<void> _cancelWithdrawal(String id) async {
    final vm = _vm;
    if (vm == null) return;
    final success = await vm.cancelWithdrawal(id);
    if (!mounted) return;

    if (success) {
      AppToast.show(
        context,
        isSuccess: true,
        title: 'Withdrawal cancelled',
        subtitle: 'Your request has been cancelled.',
      );
      _loadWithdrawals();
    } else {
      final message = vm.state is VendorWalletError
          ? (vm.state as VendorWalletError).message
          : 'Failed to cancel withdrawal';
      AppToast.show(
        context,
        isSuccess: false,
        title: 'Cancel failed',
        subtitle: message,
      );
    }
  }

  Widget _scrollableFill(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<VendorWalletViewmodel>().wallet?.currency ?? 'GHS';

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Wallet History'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Transactions'), Tab(text: 'Withdrawals')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _loadTransactions(),
            child: _buildTransactionsTab(currency),
          ),
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _loadWithdrawals(),
            child: _buildWithdrawalsTab(currency),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(String currency) {
    final w = MediaQuery.sizeOf(context).width;

    if (_txLoading) {
      return _scrollableFill(
        const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_txError != null) {
      return _scrollableFill(
        _ErrorState(message: _txError!, onRetry: () => _loadTransactions()),
      );
    }

    final result = _vm?.transactionsResult;
    final transactions = result?.transactions ?? const [];
    if (transactions.isEmpty) {
      return _scrollableFill(
        const _EmptyState(
          icon: Icons.receipt_long_rounded,
          title: 'No transactions yet',
          subtitle: 'Your wallet transactions will appear here',
        ),
      );
    }

    return ListView.builder(
      controller: _txScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.04, w * 0.05, w * 0.05),
      itemCount: transactions.length + (result!.hasMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i >= transactions.length) {
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
        return VendorWalletTransactionTile(
          transaction: transactions[i],
          currency: currency,
        );
      },
    );
  }

  Widget _buildWithdrawalsTab(String currency) {
    final w = MediaQuery.sizeOf(context).width;

    if (_wdLoading) {
      return _scrollableFill(
        const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_wdError != null) {
      return _scrollableFill(
        _ErrorState(message: _wdError!, onRetry: () => _loadWithdrawals()),
      );
    }

    final result = _vm?.withdrawalsResult;
    final withdrawals = result?.withdrawals ?? const [];
    if (withdrawals.isEmpty) {
      return _scrollableFill(
        const _EmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: 'No withdrawals yet',
          subtitle: 'Your withdrawal requests will appear here',
        ),
      );
    }

    return ListView.builder(
      controller: _wdScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.04, w * 0.05, w * 0.05),
      itemCount: withdrawals.length + (result!.hasMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i >= withdrawals.length) {
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
        final withdrawal = withdrawals[i];
        return VendorWithdrawalTile(
          withdrawal: withdrawal,
          currency: currency,
          onCancel: withdrawal.isCancellable
              ? () => _confirmCancel(withdrawal)
              : null,
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    return SizedBox(
      height: h * 0.55,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: w * 0.16, color: AppColors.textHint),
            SizedBox(height: w * 0.04),
            Text(
              title,
              style: TextStyle(
                fontSize: w * 0.042,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.015),
            Text(
              subtitle,
              style: TextStyle(fontSize: w * 0.032, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
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
    final h = MediaQuery.sizeOf(context).height;
    return SizedBox(
      height: h * 0.55,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.08),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: w * 0.14, color: AppColors.error),
              SizedBox(height: w * 0.04),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: w * 0.034, color: AppColors.textSecondary),
              ),
              SizedBox(height: w * 0.05),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
