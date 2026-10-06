import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/utils/money_format.dart';
import 'package:bagyesrushappusernew/core/utils/relative_time.dart';
import '../../models/customer_withdrawal_model.dart';

class CustomerWithdrawalTile extends StatelessWidget {
  const CustomerWithdrawalTile({
    super.key,
    required this.withdrawal,
    this.onCancel,
    this.isCancelling = false,
  });

  final CustomerWithdrawalModel withdrawal;

  /// Called by the "Cancel request" button, which only a still-pending
  /// request shows.
  final VoidCallback? onCancel;

  /// This request's cancellation is in flight.
  final bool isCancelling;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final statusColor = _statusColor(withdrawal.status);
    final createdAt = withdrawal.createdAt;
    final canCancel = withdrawal.isCancellable && onCancel != null;

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
                        withdrawal.displayStatus,
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
                    '-${formatMoney(withdrawal.amount, currency: withdrawal.currency)}',
                    style: TextStyle(
                      fontSize: w * 0.038,
                      fontWeight: FontWeight.w700,
                      color: withdrawal.status == CustomerWithdrawalStatus.cancelled
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                      decoration: withdrawal.status == CustomerWithdrawalStatus.cancelled
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (createdAt != null) ...[
                    SizedBox(height: w * 0.008),
                    Text(
                      relativeTimeLabel(createdAt),
                      style: TextStyle(fontSize: w * 0.028, color: AppColors.textHint),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (canCancel) ...[
            SizedBox(height: w * 0.02),
            Align(
              alignment: Alignment.centerRight,
              child: isCancelling
                  ? SizedBox(
                      width: w * 0.045,
                      height: w * 0.045,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.error,
                      ),
                    )
                  : TextButton(
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

  Color _statusColor(CustomerWithdrawalStatus status) => switch (status) {
    CustomerWithdrawalStatus.completed => AppColors.success,
    CustomerWithdrawalStatus.failed => AppColors.error,
    CustomerWithdrawalStatus.cancelled => AppColors.textHint,
    CustomerWithdrawalStatus.processing => AppColors.info,
    CustomerWithdrawalStatus.pending => AppColors.warning,
    CustomerWithdrawalStatus.unknown => AppColors.textSecondary,
  };
}
