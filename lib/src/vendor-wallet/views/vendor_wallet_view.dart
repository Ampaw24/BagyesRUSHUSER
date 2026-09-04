import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';
import '../viewmodels/vendor_wallet_state.dart';
import '../viewmodels/vendor_wallet_viewmodel.dart';
import 'vendor_wallet_history_view.dart';
import 'vendor_withdraw_view.dart';
import 'widgets/vendor_balance_card.dart';
import 'widgets/vendor_wallet_transaction_tile.dart';

/// Vendor wallet hub: balance + recent transactions. Mirrors
/// `TransactionView`'s wiring (global `Consumer<VendorWalletViewmodel>`,
/// no locally-installed provider).
class VendorWalletView extends StatefulWidget {
  const VendorWalletView({super.key});

  @override
  State<VendorWalletView> createState() => _VendorWalletViewState();
}

class _VendorWalletViewState extends State<VendorWalletView> {
  VendorWalletViewmodel? _vm;

  bool _initialLoading = true;
  String? _walletError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm = context.read<VendorWalletViewmodel>();
      _load();
    });
  }

  /// Loads wallet then transactions sequentially — never concurrently —
  /// so a later call's state emission can't mask an earlier one's error
  /// (both write into the same shared `VendorWalletState` field).
  Future<void> _load() async {
    final vm = _vm;
    if (vm == null) return;

    setState(() => _initialLoading = vm.wallet == null);

    await vm.fetchWallet();
    _walletError = (vm.wallet == null && vm.state is VendorWalletError)
        ? (vm.state as VendorWalletError).message
        : null;

    await vm.fetchTransactions();

    if (mounted) setState(() => _initialLoading = false);
  }

  void _openHistory() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const VendorWalletHistoryView(),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim, child: child),
        ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  void _openWithdraw() {
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const VendorWithdrawView(),
            transitionsBuilder: (_, anim, _, child) => SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 380),
          ),
        )
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Wallet history',
            onPressed: _openHistory,
          ),
        ],
      ),
      body: Consumer<VendorWalletViewmodel>(
        builder: (context, vm, _) {
          final wallet = vm.wallet;

          if (wallet == null && _initialLoading) {
            return const _WalletSkeleton();
          }

          if (wallet == null) {
            return _ErrorView(
              message: _walletError ?? 'Failed to load wallet',
              onRetry: _load,
            );
          }

          final transactions = vm.transactionsResult?.transactions ?? const [];
          final recent = transactions.take(5).toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(vertical: w * 0.03),
              children: [
                VendorBalanceCard(wallet: wallet, onWithdraw: _openWithdraw),
                SizedBox(height: w * 0.07),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: w * 0.042,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (transactions.length > 5)
                        GestureDetector(
                          onTap: _openHistory,
                          child: Text(
                            'View all',
                            style: TextStyle(
                              fontSize: w * 0.033,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: w * 0.03),
                if (recent.isEmpty)
                  const _EmptyTransactions()
                else
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                    child: Column(
                      children: [
                        for (final tx in recent)
                          VendorWalletTransactionTile(
                            transaction: tx,
                            currency: wallet.currency,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.1),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: w * 0.11,
              color: AppColors.textHint,
            ),
            SizedBox(height: w * 0.03),
            Text(
              'No transactions yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: w * 0.035,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletSkeleton extends StatefulWidget {
  const _WalletSkeleton();

  @override
  State<_WalletSkeleton> createState() => _WalletSkeletonState();
}

class _WalletSkeletonState extends State<_WalletSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) {
        final color = Color.lerp(
          AppColors.shimmerBase,
          AppColors.shimmerHighlight,
          _anim.value,
        )!;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: w * 0.04),
          children: [
            Container(
              height: w * 0.5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(w * 0.06),
              ),
            ),
            SizedBox(height: w * 0.07),
            Container(
              height: w * 0.05,
              width: w * 0.4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(w * 0.02),
              ),
            ),
            SizedBox(height: w * 0.04),
            ...List.generate(
              4,
              (_) => Container(
                margin: EdgeInsets.only(bottom: w * 0.03),
                height: w * 0.18,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(w * 0.035),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
            Icon(Icons.wifi_off_rounded, size: w * 0.14, color: AppColors.textHint),
            SizedBox(height: w * 0.04),
            Text(
              message,
              style: TextStyle(fontSize: w * 0.035, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: w * 0.05),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
