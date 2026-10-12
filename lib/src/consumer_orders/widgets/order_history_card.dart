import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/utils/date_time_format.dart';
import 'package:bagyesrushappusernew/core/utils/money_format.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'order_display.dart';
import 'order_thumbnail.dart';

/// One finished order in the history list: picture, what and when on the
/// left, the amount and how it ended on the right. The whole card opens the
/// order.
class OrderHistoryCard extends StatelessWidget {
  const OrderHistoryCard({super.key, required this.order, required this.onTap});

  final ConsumerOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final radius = BorderRadius.circular(w * 0.045);
    final detail = order.listDetail;

    return Padding(
      padding: EdgeInsets.only(bottom: w * 0.03),
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: AppColors.border, width: 0.8),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(w * 0.035),
            child: Row(
              children: [
                OrderThumbnail(order: order, size: w * 0.15, radius: w * 0.03),
                SizedBox(width: w * 0.035),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.listTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: w * 0.039,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (detail.isNotEmpty) ...[
                        SizedBox(height: w * 0.008),
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: w * 0.032,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      SizedBox(height: w * 0.008),
                      Text(
                        formatDateTimeShort(order.placedAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: w * 0.028,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: w * 0.025),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatMoney(order.total),
                      style: TextStyle(
                        fontSize: w * 0.036,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: w * 0.02),
                    _StatusPill(status: order.status),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final color = status.color;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: w * 0.01),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(w),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: w * 0.028,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
