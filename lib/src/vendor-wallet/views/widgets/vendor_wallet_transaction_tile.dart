import 'package:flutter/material.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';
import '../../models/vendor_wallet_transaction_model.dart';

class VendorWalletTransactionTile extends StatelessWidget {
  const VendorWalletTransactionTile({
    super.key,
    required this.transaction,
    required this.currency,
  });

  final VendorWalletTransactionModel transaction;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final statusColor = _statusColor(transaction.status);

    return Container(
      margin: EdgeInsets.only(bottom: w * 0.03),
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description.isNotEmpty
                      ? transaction.description
                      : (transaction.isCredit
                            ? 'Wallet credit'
                            : 'Wallet debit'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: w * 0.038,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (transaction.reference != null) ...[
                  SizedBox(height: w * 0.008),
                  Text(
                    transaction.reference!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: w * 0.032,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                SizedBox(height: w * 0.012),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.022,
                    vertical: w * 0.008,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(w * 0.5),
                  ),
                  child: Text(
                    _statusLabel(transaction.status),
                    style: TextStyle(
                      fontSize: w * 0.028,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: w * 0.03),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.isCredit ? '+' : '-'}$currency '
                '${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: w * 0.038,
                  fontWeight: FontWeight.w700,
                  color: transaction.isCredit
                      ? AppColors.success
                      : AppColors.textPrimary,
                ),
              ),
              SizedBox(height: w * 0.008),
              Text(
                _formatDate(transaction.createdAt),
                style: TextStyle(fontSize: w * 0.028, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(VendorWalletTransactionStatus status) => switch (status) {
    VendorWalletTransactionStatus.success => AppColors.success,
    VendorWalletTransactionStatus.failed => AppColors.error,
    VendorWalletTransactionStatus.pending => AppColors.warning,
  };

  String _statusLabel(VendorWalletTransactionStatus status) => switch (status) {
    VendorWalletTransactionStatus.success => 'Success',
    VendorWalletTransactionStatus.failed => 'Failed',
    VendorWalletTransactionStatus.pending => 'Pending',
  };

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
