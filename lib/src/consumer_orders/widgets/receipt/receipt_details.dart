import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/utils/date_time_format.dart';
import 'package:bagyesrushappusernew/core/utils/money_format.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/payment_receipt.dart';

/// The lower half of the receipt: payment facts, what was bought and the
/// breakdown. Only facts the backend supplied are listed.
class ReceiptDetails extends StatelessWidget {
  const ReceiptDetails({
    super.key,
    required this.receipt,
    required this.onCopyReference,
  });

  final PaymentReceipt receipt;
  final VoidCallback onCopyReference;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final channel = receipt.channelLabel;
    final reference = receipt.reference;
    final isPaid = receipt.status == ReceiptStatus.paid;
    final showItems = !receipt.isParcel && receipt.items.isNotEmpty;
    final partlyWallet =
        receipt.amountPaid != null &&
        (receipt.amountPaid! - receipt.total).abs() > 0.005;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReceiptRow(
          label: receipt.isParcel ? 'Parcel' : 'Order',
          value: '#${receipt.orderNumber}',
        ),
        ReceiptRow(
          label: receipt.dateLabel,
          value: formatDateTimeShort(receipt.displayDate),
        ),
        if (channel != null)
          ReceiptRow(
            label: isPaid ? 'Paid with' : 'Payment method',
            value: _prettyChannel(channel),
          ),
        if (reference != null)
          ReceiptRow(
            label: 'Reference',
            value: reference,
            trailing: _CopyButton(onTap: onCopyReference),
          ),
        if (receipt.isParcel && receipt.deliveryAddress.isNotEmpty)
          ReceiptRow(label: 'Deliver to', value: receipt.deliveryAddress),
        SizedBox(height: w * 0.03),
        if (showItems) ...[
          for (final item in receipt.items) _ItemRow(item: item),
          SizedBox(height: w * 0.01),
        ],
        if (showItems) _AmountRow('Subtotal', receipt.subtotal),
        _AmountRow('Delivery fee', receipt.deliveryFee),
        _AmountRow('Service fee', receipt.serviceFee),
        if (receipt.discount > 0)
          _AmountRow('Discount', -receipt.discount, color: AppColors.success),
        if (receipt.walletApplied != null && receipt.walletApplied! > 0)
          _AmountRow('Wallet', -receipt.walletApplied!, color: AppColors.success),
        Divider(color: AppColors.divider, height: w * 0.07),
        _TotalRow(
          label: partlyWallet ? 'Order total' : 'Total',
          amount: receipt.total,
          emphasised: !partlyWallet,
        ),
        if (partlyWallet)
          _TotalRow(
            label: 'Charged',
            amount: receipt.amountPaid!,
            emphasised: true,
          ),
        SizedBox(height: w * 0.045),
        Text(
          'Thank you for choosing bagyesRUSH',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: w * 0.032,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  static String _prettyChannel(String raw) {
    final spaced = raw.replaceAll('_', ' ').trim();
    if (spaced.isEmpty) return spaced;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}

/// A label on the left, a right-aligned value on the right.
class ReceiptRow extends StatelessWidget {
  const ReceiptRow({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final trailing = this.trailing;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.013),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: w * 0.034,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: w * 0.034,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (trailing != null) ...[SizedBox(width: w * 0.015), trailing],
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return InkResponse(
      onTap: onTap,
      radius: w * 0.05,
      child: Tooltip(
        message: 'Copy reference',
        child: Icon(
          Icons.copy_rounded,
          size: w * 0.042,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.01),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '${item.quantity} × ${item.name}',
              style: TextStyle(
                fontSize: w * 0.035,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: w * 0.03),
          Text(
            formatMoney(item.lineTotal),
            style: TextStyle(
              fontSize: w * 0.035,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow(this.label, this.amount, {this.color});

  final String label;
  final double amount;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.008),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: w * 0.033,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            amount < 0 ? '-${formatMoney(-amount)}' : formatMoney(amount),
            style: TextStyle(
              fontSize: w * 0.033,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.amount,
    required this.emphasised,
  });

  final String label;
  final double amount;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.006),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: w * (emphasised ? 0.042 : 0.034),
              fontWeight: emphasised ? FontWeight.w700 : FontWeight.w500,
              color: emphasised
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
          Text(
            formatMoney(amount),
            style: TextStyle(
              fontSize: w * (emphasised ? 0.05 : 0.034),
              fontWeight: emphasised ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
