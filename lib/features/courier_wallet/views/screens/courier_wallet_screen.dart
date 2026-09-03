import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constant/app_theme.dart';
import '../../../vendor_wallet/providers/wallet_providers.dart';
import '../../../vendor_wallet/views/widgets/transaction_tile.dart';

/// Customer transactions screen.
///
/// Shows the account's full transaction activity — order payments, refunds,
/// and any other wallet credits. Balance/withdrawal is not yet implemented
/// for customers.
class CourierWalletScreen extends ConsumerStatefulWidget {
  const CourierWalletScreen({super.key});

  @override
  ConsumerState<CourierWalletScreen> createState() =>
      _CourierWalletScreenState();
}

class _CourierWalletScreenState extends ConsumerState<CourierWalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletProvider);

    ref.listen<WalletState>(walletProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Transactions')),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(WalletState state) {
    if (state.status == WalletStatus.initial ||
        state.status == WalletStatus.loading) {
      return const _WalletSkeleton();
    }

    if (state.status == WalletStatus.error) {
      return _ErrorView(
        message: state.errorMessage ?? 'Failed to load wallet',
        onRetry: () => ref.read(walletProvider.notifier).load(),
      );
    }

    // Show the full transaction activity for this account.
    final transactions = state.transactions;

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () => ref.read(walletProvider.notifier).load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 8),

          // ── All transactions ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All Transactions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${transactions.length} total',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          if (transactions.isEmpty)
            const _EmptyTransactions()
          else
            ...transactions.map(
              (tx) => TransactionTile(
                transaction: tx,
                currency: state.wallet.currency,
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Empty transactions ─────────────────────────────────────────────────────────

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 44,
              color: AppColors.textHint,
            ),
            SizedBox(height: 12),
            Text(
              'No transactions yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Your order payments, refunds, and other activity will appear here',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _WalletSkeleton extends StatefulWidget {
  const _WalletSkeleton();

  @override
  State<_WalletSkeleton> createState() => _WalletSkeletonState();
}

class _WalletSkeletonState extends State<_WalletSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

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
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) {
        final color = Color.lerp(
          AppColors.shimmerBase,
          AppColors.shimmerHighlight,
          _anim.value,
        )!;
        return ListView(
          padding: const EdgeInsets.only(top: 8),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 20,
                width: 140,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              4,
              (_) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                height: 72,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
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
