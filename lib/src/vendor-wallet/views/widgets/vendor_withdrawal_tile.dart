import 'package:flutter/material.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';
import '../../models/vendor_withdrawal_model.dart';

class VendorWithdrawalTile extends StatelessWidget {
  const VendorWithdrawalTile({
    super.key,
    required this.withdrawal,
    required this.currency,
    this.onCancel,
  });

  final VendorWithdrawalModel withdrawal;
  final String currency;

  /// Non-null only when [withdrawal] is still pending — renders a
  /// "Cancel request" affordance.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final statusColor = _statusColor(withdrawal.status);

    return Container(
      margin: EdgeInsets.only(bottom: w * 0.03),
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Withdrawal',
                      style: TextStyle(
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (withdrawal.reference != null) ...[
                      SizedBox(height: w * 0.008),
                      Text(
                        withdrawal.reference!,
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
                        _statusLabel(withdrawal.status),
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
                    '-$currency ${withdrawal.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: w * 0.038,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: w * 0.008),
                  Text(
                    _formatDate(withdrawal.createdAt),
                    style: TextStyle(
                      fontSize: w * 0.028,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (onCancel != null) ...[
            SizedBox(height: w * 0.02),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.03,
                    vertical: w * 0.01,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Cancel request',
                  style: TextStyle(
                    fontSize: w * 0.032,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(VendorWithdrawalStatus status) => switch (status) {
    VendorWithdrawalStatus.completed => AppColors.success,
    VendorWithdrawalStatus.failed => AppColors.error,
    VendorWithdrawalStatus.cancelled => AppColors.textHint,
    VendorWithdrawalStatus.processing => AppColors.info,
    VendorWithdrawalStatus.pending => AppColors.warning,
  };

  String _statusLabel(VendorWithdrawalStatus status) => switch (status) {
    VendorWithdrawalStatus.completed => 'Completed',
    VendorWithdrawalStatus.failed => 'Failed',
    VendorWithdrawalStatus.cancelled => 'Cancelled',
    VendorWithdrawalStatus.processing => 'Processing',
    VendorWithdrawalStatus.pending => 'Pending',
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
