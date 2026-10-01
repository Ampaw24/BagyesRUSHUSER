import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/utils/money_format.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';

/// Items + total, with "View order details" expanding the fee breakdown,
/// delivery address and payment status.
class TrackingOrderSummary extends StatefulWidget {
  const TrackingOrderSummary({
    super.key,
    required this.order,
    this.onViewReceipt,
  });

  final ConsumerOrder order;

  /// Offered once the order is paid; null hides the action.
  final VoidCallback? onViewReceipt;

  @override
  State<TrackingOrderSummary> createState() => _TrackingOrderSummaryState();
}

class _TrackingOrderSummaryState extends State<TrackingOrderSummary> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final order = widget.order;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in order.items) _ItemRow(item: item),
        if (order.items.isNotEmpty) SizedBox(height: w * 0.02),
        Row(
          children: [
            Text(
              'Total',
              style: TextStyle(
                fontSize: w * 0.042,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              formatMoney(order.total),
              style: TextStyle(
                fontSize: w * 0.055,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: EdgeInsets.only(top: w * 0.03),
                  child: _OrderDetails(order: order),
                )
              : const SizedBox(width: double.infinity),
        ),
        SizedBox(height: w * 0.02),
        if (widget.onViewReceipt != null)
          Center(
            child: TextButton.icon(
              onPressed: widget.onViewReceipt,
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              icon: Icon(Icons.receipt_long_rounded, size: w * 0.045),
              label: Text(
                'View payment receipt',
                style: TextStyle(
                  fontSize: w * 0.036,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _expanded ? 'Hide order details' : 'View order details',
                  style: TextStyle(
                    fontSize: w * 0.036,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: w * 0.01),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 280),
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: w * 0.05),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final tile = w * 0.12;

    return Padding(
      padding: EdgeInsets.only(bottom: w * 0.03),
      child: Row(
        children: [
          Container(
            width: tile,
            height: tile,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(w * 0.03),
            ),
            child: Icon(
              Icons.fastfood_rounded,
              size: tile * 0.5,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: w * 0.035),
          Expanded(
            child: Text(
              '${item.quantity} x ${item.name}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: w * 0.036,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: w * 0.02),
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

class _OrderDetails extends StatelessWidget {
  const _OrderDetails({required this.order});

  final ConsumerOrder order;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final instructions = order.deliveryInstructions?.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (order.items.isNotEmpty) _PriceRow('Subtotal', order.subtotal),
          _PriceRow('Delivery fee', order.deliveryFee),
          _PriceRow('Service fee', order.serviceFee),
          if (order.discount > 0)
            _PriceRow('Discount', -order.discount, color: AppColors.success),
          Divider(color: AppColors.divider, height: w * 0.06),
          _DetailRow(
            icon: Icons.location_on_rounded,
            label: 'Delivery address',
            value: order.deliveryAddress,
          ),
          if (instructions.isNotEmpty)
            _DetailRow(
              icon: Icons.sticky_note_2_outlined,
              label: 'Instructions',
              value: instructions,
            ),
          _DetailRow(
            icon: Icons.payments_rounded,
            label: 'Payment',
            value: _paymentMethodLabel(order.paymentMethod),
            trailing: _PaymentStatusChip(status: order.paymentStatus),
          ),
        ],
      ),
    );
  }

  static String _paymentMethodLabel(String raw) {
    final spaced = raw.replaceAll('_', ' ').trim();
    if (spaced.isEmpty) return '—';
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.value, {this.color});

  final String label;
  final double value;
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
            value < 0 ? '-${formatMoney(-value)}' : formatMoney(value),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final trailing = this.trailing;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.012),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: w * 0.045, color: AppColors.primary),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: w * 0.029,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: w * 0.034,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[SizedBox(width: w * 0.02), trailing],
        ],
      ),
    );
  }
}

class _PaymentStatusChip extends StatelessWidget {
  const _PaymentStatusChip({required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final (color, label) = switch (status) {
      PaymentStatus.paid => (AppColors.success, 'Paid'),
      PaymentStatus.failed => (AppColors.error, 'Failed'),
      PaymentStatus.pending => (AppColors.paymentPending, 'Pending'),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: w * 0.01),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(w),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: w * 0.029,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
