import 'package:flutter/material.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';
import '../../models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final statusColor = _statusColor(transaction.status);
    final order = transaction.order;
    final title = order?.vendor?.name.isNotEmpty == true
        ? order!.vendor!.name
        : transaction.methodLabel;
    final subtitle = order != null
        ? 'Order ${order.orderNumber}'
        : transaction.reference;

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
                  title,
                  style: TextStyle(
                    fontSize: w * 0.038,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: w * 0.008),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: w * 0.032,
                    color: AppColors.textSecondary,
                  ),
                ),
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
                    transaction.statusLabel,
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
                '${transaction.isCredit ? '+' : '-'}${transaction.currency} '
                '${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: w * 0.038,
                  fontWeight: FontWeight.w700,
                  color: transaction.isCredit ? AppColors.success : AppColors.textPrimary,
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'success':
      case 'completed':
        return AppColors.success;
      case 'failed':
      case 'expired':
      case 'cancelled':
        return AppColors.error;
      case 'pending':
      case 'processing':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
