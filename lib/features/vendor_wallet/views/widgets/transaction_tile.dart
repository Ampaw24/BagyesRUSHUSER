import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';
import '../../models/transaction_model.dart';

/// A single transaction row with type icon, color-coded amount, and status badge.
class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final String currency;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.currency = 'GH₵',
  });

  // ── Icon & color ──────────────────────────────────────────────────────────

  IconData get _icon => switch (transaction.type) {
        TransactionType.credit     => Icons.arrow_downward_rounded,
        TransactionType.withdrawal => Icons.arrow_upward_rounded,
        TransactionType.refund     => Icons.undo_rounded,
      };

  Color get _iconColor => transaction.isCredit
      ? AppColors.success
      : transaction.status == TransactionStatus.failed
          ? AppColors.error
          : AppColors.primary;

  Color get _amountColor => transaction.isCredit
      ? AppColors.success
      : transaction.status == TransactionStatus.failed
          ? AppColors.error
          : AppColors.textPrimary;

  // ── Status chip ───────────────────────────────────────────────────────────

  Widget _statusChip() {
    final (label, color) = switch (transaction.status) {
      TransactionStatus.completed  => ('Completed', AppColors.success),
      TransactionStatus.pending    => ('Pending', AppColors.warning),
      TransactionStatus.processing => ('Processing', AppColors.info),
      TransactionStatus.failed     => ('Failed', AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ── Date formatting ───────────────────────────────────────────────────────

  String get _formattedDate {
    final d = transaction.createdAt;
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)  return '${diff.inHours}h ago';
    if (diff.inDays == 1)   return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Type icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _iconColor, size: 20),
          ),
          const SizedBox(width: 14),

          // Description + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _statusChip(),
                    const SizedBox(width: 8),
                    Text(
                      _formattedDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.formattedAmount(currency),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _amountColor,
                ),
              ),
              if (transaction.fee != null && transaction.fee! > 0) ...[
                const SizedBox(height: 2),
                Text(
                  'Fee: $currency ${transaction.fee!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
