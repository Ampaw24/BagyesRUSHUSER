import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/widgets/animated_money.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/payment_receipt.dart';

extension ReceiptStatusStyle on ReceiptStatus {
  Color get color => switch (this) {
    ReceiptStatus.paid => AppColors.success,
    ReceiptStatus.processing => AppColors.paymentPending,
    ReceiptStatus.failed => AppColors.error,
  };

  String get title => switch (this) {
    ReceiptStatus.paid => 'Payment successful',
    ReceiptStatus.processing => 'Payment processing',
    ReceiptStatus.failed => 'Payment not completed',
  };
}

/// Top of the receipt: brand, status badge, headline amount and who it was
/// paid to — or what to expect when the payment isn't settled.
class ReceiptStatusHeader extends StatelessWidget {
  const ReceiptStatusHeader({
    super.key,
    required this.status,
    this.amount,
    this.paidTo,
    this.message,
  });

  final ReceiptStatus status;
  final double? amount;
  final String? paidTo;

  /// Extra explanation under the amount (processing / failed).
  final String? message;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final amount = this.amount;
    final message = this.message;
    final paidTo = this.paidTo;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'bagyesRUSH',
          style: TextStyle(
            fontSize: w * 0.038,
            fontWeight: FontWeight.w800,
            letterSpacing: w * 0.003,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: w * 0.045),
        _StatusBadge(status: status),
        SizedBox(height: w * 0.03),
        Text(
          status.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: w * 0.05,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        if (amount != null) ...[
          SizedBox(height: w * 0.015),
          AnimatedMoney(
            amount: amount,
            style: TextStyle(
              fontSize: w * 0.095,
              fontWeight: FontWeight.w800,
              color: status == ReceiptStatus.failed
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
            ),
          ),
        ],
        if (paidTo != null && paidTo.isNotEmpty) ...[
          SizedBox(height: w * 0.01),
          Text(
            status == ReceiptStatus.paid ? 'Paid to $paidTo' : paidTo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: w * 0.036,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (message != null && message.isNotEmpty) ...[
          SizedBox(height: w * 0.025),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: w * 0.034,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ReceiptStatus status;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final size = w * 0.22;

    if (status == ReceiptStatus.paid) {
      return SizedBox(
        width: size,
        height: size,
        child: Lottie.asset(
          'assets/success_loader.json',
          repeat: false,
          errorBuilder: (_, _, _) => Icon(
            Icons.check_circle_rounded,
            size: size * 0.8,
            color: status.color,
          ),
        ),
      );
    }

    final icon = status == ReceiptStatus.processing
        ? Icons.hourglass_top_rounded
        : Icons.close_rounded;
    return Container(
      width: size * 0.8,
      height: size * 0.8,
      margin: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size * 0.4, color: status.color),
    );
  }
}
