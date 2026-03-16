import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constant/app_theme.dart';
import '../../../vendor_wallet/models/wallet_model.dart';
import '../../../vendor_wallet/models/transaction_model.dart';
import '../../../vendor_wallet/providers/wallet_providers.dart';
import '../../../vendor_wallet/views/widgets/transaction_tile.dart';
import '../../../vendor_wallet/views/screens/withdraw_screen.dart';
import '../../../vendor_wallet/views/screens/transaction_history_screen.dart';

/// Courier wallet screen.
///
/// A courier's wallet only holds system-issued refund credits — funds returned
/// by the platform when there are issues with an order or courier activity.
/// Withdrawal is only available when there is a positive available balance.
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

  void _openWithdraw() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, anim, _) => const WithdrawScreen(),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  void _openHistory() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, anim, _) => const TransactionHistoryScreen(),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim, child: child),
        ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletProvider);

    ref.listen<WalletState>(walletProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Transaction history',
            onPressed: _openHistory,
          ),
        ],
      ),
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

    // Filter to only refund-related transactions for couriers
    final courierTxs = state.transactions
        .where((t) =>
            t.type == TransactionType.refund ||
            t.type == TransactionType.withdrawal)
        .toList();

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () => ref.read(walletProvider.notifier).load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 8),

          // ── Balance card ──────────────────────────────────────────────────
          _CourierBalanceCard(
            wallet: state.wallet,
            onWithdraw:
                state.wallet.availableBalance > 0 ? _openWithdraw : null,
          ),

          const SizedBox(height: 16),

          // ── Info banner ───────────────────────────────────────────────────
          _RefundInfoBanner(),

          const SizedBox(height: 16),

          // ── Stats row ─────────────────────────────────────────────────────
          _CourierStatRow(wallet: state.wallet),

          const SizedBox(height: 24),

          // ── Pending notice ─────────────────────────────────────────────────
          if (state.wallet.pendingBalance > 0)
            _PendingBanner(amount: state.wallet.pendingFormatted),

          // ── Recent transactions ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (courierTxs.length > 5)
                  GestureDetector(
                    onTap: _openHistory,
                    child: Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          if (courierTxs.isEmpty)
            const _EmptyTransactions()
          else
            ...courierTxs.take(5).map(
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

// ── Courier balance card ───────────────────────────────────────────────────────

class _CourierBalanceCard extends StatefulWidget {
  final WalletModel wallet;
  final VoidCallback? onWithdraw;

  const _CourierBalanceCard({
    required this.wallet,
    this.onWithdraw,
  });

  @override
  State<_CourierBalanceCard> createState() => _CourierBalanceCardState();
}

class _CourierBalanceCardState extends State<_CourierBalanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final hasBalance = widget.wallet.availableBalance > 0;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: w * 0.55,
          decoration: BoxDecoration(
            // Teal/green gradient to distinguish from vendor's indigo
            gradient: const LinearGradient(
              colors: [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF00897B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF004D40).withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Decorative blurred circles
                Positioned(
                  right: -w * 0.12,
                  top: -w * 0.12,
                  child: Container(
                    width: w * 0.6,
                    height: w * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Positioned(
                  left: -w * 0.08,
                  bottom: -w * 0.15,
                  child: Container(
                    width: w * 0.5,
                    height: w * 0.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),

                // Glass layer
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: const SizedBox.expand(),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.all(w * 0.06),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Courier Wallet',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: w * 0.033,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.wallet.currency,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Available balance (large)
                      Text(
                        'Available Balance',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: w * 0.03,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.wallet.availableFormatted,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: w * 0.085,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const Spacer(),

                      // Bottom: pending + conditional withdraw button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: w * 0.027,
                                ),
                              ),
                              Text(
                                widget.wallet.pendingFormatted,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: w * 0.04,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (hasBalance && widget.onWithdraw != null)
                            _WithdrawRefundButton(onTap: widget.onWithdraw!),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Withdraw refund button ─────────────────────────────────────────────────────

class _WithdrawRefundButton extends StatefulWidget {
  final VoidCallback onTap;
  const _WithdrawRefundButton({required this.onTap});

  @override
  State<_WithdrawRefundButton> createState() => _WithdrawRefundButtonState();
}

class _WithdrawRefundButtonState extends State<_WithdrawRefundButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0,
      upperBound: 1,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_upward_rounded,
                size: 16,
                color: Color(0xFF00695C),
              ),
              const SizedBox(width: 6),
              const Text(
                'Withdraw',
                style: TextStyle(
                  color: Color(0xFF00695C),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Refund info banner ────────────────────────────────────────────────────────

class _RefundInfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.info, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your wallet balance consists of refund credits issued by the system. '
              'These are applied when there are issues with your orders or activity. '
              'You can withdraw refund credits at any time.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Courier stat row ──────────────────────────────────────────────────────────

class _CourierStatRow extends StatelessWidget {
  final WalletModel wallet;
  const _CourierStatRow({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.undo_rounded,
              iconColor: AppColors.success,
              label: 'Total Refunds',
              value: wallet.earningsFormatted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              icon: Icons.account_balance_outlined,
              iconColor: AppColors.info,
              label: 'Withdrawn',
              value: wallet.withdrawnFormatted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pending banner ────────────────────────────────────────────────────────────

class _PendingBanner extends StatelessWidget {
  final String amount;
  const _PendingBanner({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded,
              color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, height: 1.4),
                children: [
                  TextSpan(
                    text: '$amount ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                  const TextSpan(
                    text:
                        'in refunds is being reviewed and will be available within 24 hours.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
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
            Icon(Icons.receipt_long_outlined,
                size: 44, color: AppColors.textHint),
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
              'Refunds from the system will appear here',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
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
    _anim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
          padding: const EdgeInsets.only(top: 8),
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: w * 0.55,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 56,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(
              4,
              (_) => Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
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
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.textHint),
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
