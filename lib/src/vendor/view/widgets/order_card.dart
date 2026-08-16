import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../constant/app_theme.dart';
import '../../model/vendor_order.dart';

class OrderCard extends StatelessWidget {
  final VendorOrder order;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onMarkPreparing;
  final VoidCallback? onMarkReady;
  final VoidCallback? onMarkOutForDelivery;
  final VoidCallback? onMarkDelivered;
  final VoidCallback? onCancel;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onAccept,
    this.onDecline,
    this.onMarkPreparing,
    this.onMarkReady,
    this.onMarkOutForDelivery,
    this.onMarkDelivered,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: AppColors.primary.withValues(alpha: 0.05),
        ),
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
                    '#${order.id}',
                    style: TextStyle(
                      fontSize: w * 0.036,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Mukta',
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(width: w * 0.02),
                  _OrderTypeBadge(type: order.orderType),
                  const Spacer(),
                  _StatusBadge(status: order.status),
                ],
              ),
              SizedBox(height: w * 0.04),
              // Customer + amount
              Row(
                children: [
                  _CustomerAvatar(name: order.customerName, w: w),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName,
                          style: TextStyle(
                            fontSize: w * 0.038,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Mukta',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: w * 0.002),
                        Text(
                          order.timeAgo,
                          style: TextStyle(
                            fontSize: w * 0.03,
                            color: AppColors.textHint,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Mukta',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    order.amount,
                    style: TextStyle(
                      fontSize: w * 0.045,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontFamily: 'Mukta',
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // ── Expanded: items + note + actions ──
          children: [
            // Divider
            Container(
              height: 1,
              width: double.infinity,
              color: AppColors.divider,
              margin: EdgeInsets.only(bottom: w * 0.03),
            ),
            // Items list
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(w * 0.035),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(w * 0.03),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < order.itemList.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i < order.itemList.length - 1 ? w * 0.015 : 0,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: w * 0.015, vertical: w * 0.005),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(w * 0.012),
                            ),
                            child: Text(
                              '${order.itemList[i].quantity}x',
                              style: TextStyle(
                                fontSize: w * 0.026,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                fontFamily: 'Mukta',
                              ),
                            ),
                          ),
                          SizedBox(width: w * 0.025),
                          Expanded(
                            child: Text(
                              order.itemList[i].name,
                              style: TextStyle(
                                fontSize: w * 0.032,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mukta',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            order.itemList[i].price,
                            style: TextStyle(
                              fontSize: w * 0.03,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Mukta',
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
              SizedBox(height: w * 0.03),
              Container(
                padding: EdgeInsets.all(w * 0.03),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(w * 0.025),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      size: w * 0.035,
                      color: AppColors.accent,
                    ),
                    SizedBox(width: w * 0.02),
                    Expanded(
                      child: Text(
                        order.customerNote!,
                        style: TextStyle(
                          fontSize: w * 0.03,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Mukta',
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons — exactly one primary next-action per status.
            ..._buildActions(w),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(double w) {
    Widget primary(String label, VoidCallback? onTap) => Row(
          children: [
            Expanded(
              flex: 2,
              child: _ActionButton(
                label: label,
                color: AppColors.primary,
                onTap: onTap,
              ),
            ),
          ],
        );

    Widget? actionRow;
    switch (order.status) {
      case OrderStatus.pending:
        actionRow = Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Decline',
                color: AppColors.textSecondary,
                outlined: true,
                onTap: onDecline,
              ),
            ),
            SizedBox(width: w * 0.03),
            Expanded(
              flex: 2,
              child: _ActionButton(
                label: 'Accept Order',
                color: AppColors.primary,
                onTap: onAccept,
              ),
            ),
          ],
        );
        break;
      case OrderStatus.accepted:
        actionRow = primary('Start Preparing', onMarkPreparing);
        break;
      case OrderStatus.preparing:
        actionRow = primary('Mark Ready', onMarkReady);
        break;
      case OrderStatus.ready:
        actionRow = primary('Out for Delivery', onMarkOutForDelivery);
        break;
      case OrderStatus.outForDelivery:
        actionRow = primary('Mark Delivered', onMarkDelivered);
        break;
      case OrderStatus.delivered:
      case OrderStatus.rejected:
      case OrderStatus.cancelled:
        actionRow = null;
        break;
    }

    final showCancel = onCancel != null &&
        (order.status == OrderStatus.accepted ||
            order.status == OrderStatus.preparing ||
            order.status == OrderStatus.ready);

    if (actionRow == null && !showCancel) return const [];

    return [
      SizedBox(height: w * 0.04),
      if (actionRow != null) actionRow,
      if (showCancel) ...[
        SizedBox(height: w * 0.02),
        Center(
          child: GestureDetector(
            onTap: onCancel,
            child: Text(
              'Cancel order',
              style: TextStyle(
                fontSize: w * 0.03,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ),
      ],
    ];
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

  List<List<dynamic>> get _icon {
    switch (type) {
      case OrderType.delivery:
        return HugeIcons.strokeRoundedDeliveryTruck01;
      case OrderType.pickup:
        return HugeIcons.strokeRoundedShoppingBag01;
      case OrderType.dineIn:
        return HugeIcons.strokeRoundedRestaurant01;
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
          HugeIcon(icon: _icon, size: w * 0.03, color: AppColors.secondary),
          SizedBox(width: w * 0.008),
          Text(
            _label,
            style: TextStyle(
              fontSize: w * 0.024,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
              fontFamily: 'Mukta',
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
