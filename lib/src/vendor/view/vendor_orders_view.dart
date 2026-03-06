import 'package:flutter/material.dart';
import '../../../constant/app_theme.dart';
import '../model/vendor_order.dart';
import '../model/dummy_orders.dart';
import 'widgets/order_card.dart';

class VendorOrdersView extends StatefulWidget {
  const VendorOrdersView({super.key});

  @override
  State<VendorOrdersView> createState() => _VendorOrdersViewState();
}

class _VendorOrdersViewState extends State<VendorOrdersView> {
  OrderStatus? _activeFilter;

  List<VendorOrder> get _filteredOrders => DummyOrders.byStatus(_activeFilter);

  void _setFilter(OrderStatus? status) {
    setState(() => _activeFilter = status);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final horizontalPad = w * 0.05;
    final orders = _filteredOrders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header with order count ──
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPad, w * 0.03, horizontalPad, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Orders',
                style: TextStyle(
                  fontSize: w * 0.055,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: w * 0.02),
              Padding(
                padding: EdgeInsets.only(bottom: w * 0.008),
                child: Text(
                  '${orders.length} ${_activeFilter?.label ?? 'total'}',
                  style: TextStyle(
                    fontSize: w * 0.03,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: w * 0.035),

        // ── Filter chips ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: horizontalPad),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                count: DummyOrders.all.length,
                selected: _activeFilter == null,
                onTap: () => _setFilter(null),
              ),
              SizedBox(width: w * 0.02),
              _FilterChip(
                label: 'New',
                count: DummyOrders.byStatus(OrderStatus.newOrder).length,
                color: OrderStatus.newOrder.color,
                selected: _activeFilter == OrderStatus.newOrder,
                onTap: () => _setFilter(OrderStatus.newOrder),
              ),
              SizedBox(width: w * 0.02),
              _FilterChip(
                label: 'Preparing',
                count: DummyOrders.byStatus(OrderStatus.preparing).length,
                color: OrderStatus.preparing.color,
                selected: _activeFilter == OrderStatus.preparing,
                onTap: () => _setFilter(OrderStatus.preparing),
              ),
              SizedBox(width: w * 0.02),
              _FilterChip(
                label: 'Rider',
                count: DummyOrders.byStatus(OrderStatus.riderAssigned).length,
                color: OrderStatus.riderAssigned.color,
                selected: _activeFilter == OrderStatus.riderAssigned,
                onTap: () => _setFilter(OrderStatus.riderAssigned),
              ),
              SizedBox(width: w * 0.02),
              _FilterChip(
                label: 'Done',
                count: DummyOrders.byStatus(OrderStatus.completed).length,
                color: OrderStatus.completed.color,
                selected: _activeFilter == OrderStatus.completed,
                onTap: () => _setFilter(OrderStatus.completed),
              ),
              SizedBox(width: w * 0.02),
              _FilterChip(
                label: 'Cancelled',
                count: DummyOrders.byStatus(OrderStatus.cancelled).length,
                color: OrderStatus.cancelled.color,
                selected: _activeFilter == OrderStatus.cancelled,
                onTap: () => _setFilter(OrderStatus.cancelled),
              ),
            ],
          ),
        ),
        SizedBox(height: w * 0.035),

        // ── Order list ──
        Expanded(
          child: orders.isEmpty
              ? _EmptyView(w: w, filter: _activeFilter?.label)
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad, 0, horizontalPad, w * 0.25,
                  ),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => SizedBox(height: w * 0.03),
                  itemBuilder: (_, index) => OrderCard(
                    order: orders[index],
                    onTap: () {},
                    onAccept: () {},
                    onDecline: () {},
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Filter chip with count badge ────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count = 0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final chipColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.035,
          vertical: w * 0.02,
        ),
        decoration: BoxDecoration(
          color: selected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(w * 0.05),
          border: Border.all(
            color: selected ? chipColor : AppColors.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: chipColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: w * 0.031,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            if (count > 0) ...[
              SizedBox(width: w * 0.015),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.015,
                  vertical: w * 0.003,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(w * 0.02),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: w * 0.024,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.textHint,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final double w;
  final String? filter;

  const _EmptyView({required this.w, this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.06),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: w * 0.1,
              color: AppColors.textHint,
            ),
          ),
          SizedBox(height: w * 0.04),
          Text(
            filter != null ? 'No $filter orders' : 'No orders yet',
            style: TextStyle(
              fontSize: w * 0.04,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: w * 0.01),
          Text(
            'Orders will show up here when customers place them',
            style: TextStyle(
              fontSize: w * 0.03,
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
