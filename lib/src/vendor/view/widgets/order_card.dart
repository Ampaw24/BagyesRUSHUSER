import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';
import '../../model/vendor_order.dart';

class OrderCard extends StatelessWidget {
  final VendorOrder order;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final statusColor = order.status.color;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(w * 0.04),
        child: Column(
          children: [
            // ── Top color accent bar ──
            Container(
              height: 3,
              color: statusColor,
            ),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.all(w * 0.04),
                childrenPadding: EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, w * 0.04),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                // ── Collapsed: header summary ──
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ID + type badge + status
                    Row(
                      children: [
                        Text(
                          order.id,
                          style: TextStyle(
                            fontSize: w * 0.038,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(width: w * 0.02),
                        _OrderTypeBadge(type: order.orderType),
                        const Spacer(),
                        _StatusBadge(status: order.status),
                      ],
                    ),
                    SizedBox(height: w * 0.03),
                    // Customer + amount
                    Row(
                      children: [
                        _CustomerAvatar(name: order.customerName, w: w),
                        SizedBox(width: w * 0.025),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customerName,
                                style: TextStyle(
                                  fontSize: w * 0.034,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: w * 0.005),
                              Text(
                                order.timeAgo,
                                style: TextStyle(
                                  fontSize: w * 0.028,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          order.amount,
                          style: TextStyle(
                            fontSize: w * 0.042,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // ── Expanded: items + note + actions ──
                children: [
                  // Items list
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(w * 0.03),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(w * 0.025),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < order.itemList.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: i < order.itemList.length - 1 ? w * 0.012 : 0,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: w * 0.05,
                                  height: w * 0.05,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(w * 0.012),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${order.itemList[i].quantity}x',
                                      style: TextStyle(
                                        fontSize: w * 0.024,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: w * 0.02),
                                Expanded(
                                  child: Text(
                                    order.itemList[i].name,
                                    style: TextStyle(
                                      fontSize: w * 0.03,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  order.itemList[i].price,
                                  style: TextStyle(
                                    fontSize: w * 0.028,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Customer note (if any)
                  if (order.customerNote != null && order.customerNote!.isNotEmpty) ...[
                    SizedBox(height: w * 0.02),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.sticky_note_2_outlined,
                          size: w * 0.035,
                          color: AppColors.accent,
                        ),
                        SizedBox(width: w * 0.015),
                        Expanded(
                          child: Text(
                            order.customerNote!,
                            style: TextStyle(
                              fontSize: w * 0.028,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Action buttons for new orders
                  if (order.status == OrderStatus.newOrder) ...[
                    SizedBox(height: w * 0.03),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'Decline',
                            color: AppColors.textSecondary,
                            outlined: true,
                            onTap: onDecline,
                          ),
                        ),
                        SizedBox(width: w * 0.025),
                        Expanded(
                          flex: 2,
                          child: _ActionButton(
                            label: 'Accept Order',
                            color: AppColors.primary,
                            onTap: onAccept,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Customer avatar with initials ───────────────────────────────────────

class _CustomerAvatar extends StatelessWidget {
  final String name;
  final double w;

  const _CustomerAvatar({required this.name, required this.w});

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();

    return Container(
      width: w * 0.09,
      height: w * 0.09,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(w * 0.025),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: w * 0.03,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ── Order type badge ────────────────────────────────────────────────────

class _OrderTypeBadge extends StatelessWidget {
  final OrderType type;

  const _OrderTypeBadge({required this.type});

  String get _label {
    switch (type) {
      case OrderType.delivery:
        return 'Delivery';
      case OrderType.pickup:
        return 'Pickup';
      case OrderType.dineIn:
        return 'Dine-in';
    }
  }

  IconData get _icon {
    switch (type) {
      case OrderType.delivery:
        return Icons.delivery_dining;
      case OrderType.pickup:
        return Icons.shopping_bag_outlined;
      case OrderType.dineIn:
        return Icons.restaurant_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.018,
        vertical: w * 0.008,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(w * 0.012),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: w * 0.03, color: AppColors.secondary),
          SizedBox(width: w * 0.008),
          Text(
            _label,
            style: TextStyle(
              fontSize: w * 0.024,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status badge ────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final color = status.color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.022,
        vertical: w * 0.01,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(w * 0.05),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: w * 0.015,
            height: w * 0.015,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: w * 0.01),
          Text(
            status.label,
            style: TextStyle(
              fontSize: w * 0.026,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action button ───────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    this.outlined = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: w * 0.03),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(w * 0.025),
          border: outlined ? Border.all(color: AppColors.border) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: w * 0.032,
              fontWeight: FontWeight.w600,
              color: outlined ? AppColors.textSecondary : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
