import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constant/app_theme.dart';
import '../../providers/wallet_providers.dart';
import '../widgets/transaction_tile.dart';

/// Full paginated transaction history with filter tabs.
class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState  = ref.watch(walletProvider);
    final filter       = ref.watch(txFilterProvider);
    final filtered     = ref.watch(filteredTransactionsProvider);
    final currency     = walletState.wallet.currency;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Transaction History')),
      body: Column(
        children: [
          // ── Filter tabs ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: TxFilter.values.map((f) {
                final selected = filter == f;
                final label = switch (f) {
                  TxFilter.all         => 'All',
                  TxFilter.credits     => 'Credits',
                  TxFilter.withdrawals => 'Withdrawals',
                };
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(txFilterProvider.notifier).state = f,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // ── Transaction count ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${filtered.length} transaction${filtered.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _EmptyFilter()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 32),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => TransactionTile(
                      transaction: filtered[i],
                      currency: currency,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: AppColors.textHint),
          SizedBox(height: 12),
          Text(
            'No transactions found',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
