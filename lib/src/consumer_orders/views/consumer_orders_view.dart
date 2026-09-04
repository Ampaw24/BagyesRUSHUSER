import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_state.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/report/model/report.dart';
import 'package:bagyesrushappusernew/src/report/views/report_flow_args.dart';
import 'package:bagyesrushappusernew/src/report/widgets/report_quick_action_sheet.dart';

class ConsumerOrdersView extends StatelessWidget {
  const ConsumerOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('My Orders'),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ActiveOrdersList(),
            _PastOrdersList(),
          ],
        ),
      ),
    );
  }
}

/// Active orders are always few — refreshable, but never paginated.
class _ActiveOrdersList extends StatelessWidget {
  const _ActiveOrdersList();

  @override
  Widget build(BuildContext context) {
    final ordersState = context.watch<OrdersViewModel>().state;
    final active = ordersState is OrdersLoaded ? ordersState.active : const <ConsumerOrder>[];
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<OrdersViewModel>().refresh(),
      child: _OrderList(orders: active, isActive: true),
    );
  }
}

/// Order history can be arbitrarily long — refreshable and infinite-scroll
/// paginated via `OrdersViewModel.loadMore()`.
class _PastOrdersList extends StatefulWidget {
  const _PastOrdersList();

  @override
  State<_PastOrdersList> createState() => _PastOrdersListState();
}

class _PastOrdersListState extends State<_PastOrdersList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<OrdersViewModel>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = context.watch<OrdersViewModel>().state;
    final past = ordersState is OrdersLoaded ? ordersState.past : const <ConsumerOrder>[];
    final isLoadingMore =
        ordersState is OrdersLoaded && ordersState.isLoadingMore;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<OrdersViewModel>().refresh(),
      child: _OrderList(
        orders: past,
        isActive: false,
        scrollController: _scrollController,
        footer: isLoadingMore ? const _LoadMoreFooter() : null,
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.06),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<ConsumerOrder> orders;
  final bool isActive;
  final ScrollController? scrollController;
  final Widget? footer;

  const _OrderList({
    required this.orders,
    required this.isActive,
    this.scrollController,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    if (orders.isEmpty) {
      // Wrapped in a scrollable (rather than a bare Center) so the
      // enclosing RefreshIndicator's pull gesture still has something to
      // attach to when there's no data yet.
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.6,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive
                        ? Icons.delivery_dining_rounded
                        : Icons.receipt_long_rounded,
                    size: w * 0.18,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: w * 0.04),
                  Text(
                    isActive ? 'No active orders' : 'No past orders',
                    style: TextStyle(
                      fontSize: w * 0.044,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: w * 0.015),
                  Text(
                    isActive
                        ? 'Place an order to see it here'
                        : 'Your order history will appear here',
                    style: TextStyle(
                      fontSize: w * 0.033,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final itemCount = orders.length + (footer != null ? 1 : 0);
    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.04, w * 0.05, w * 0.05),
      itemCount: itemCount,
      itemBuilder: (ctx, i) {
        if (i >= orders.length) return footer!;
        return _buildOrderCard(ctx, orders[i]);
      },
    );
  }
}

/// Shared per-order card wiring, reused by both the Active and Past lists.
Widget _buildOrderCard(BuildContext context, ConsumerOrder order) {
  return _OrderCard(
    order: order,
    onTap: () => context.push(AppRoutes.trackOrder, extra: order.id),
    onReorder: () async {
      await context.read<OrdersViewModel>().reorder(order.id);
      if (context.mounted) {
        context.push(AppRoutes.trackOrder, extra: order.id);
      }
    },
    onReport: () => ReportQuickActionSheet.show(
      context,
      role: ReportRole.customer,
      orderId: order.id,
      primaryTarget: ReportFlowArgs(
        role: ReportRole.customer,
        targetType: ReportTargetType.vendor,
        orderId: order.id,
        targetId: order.restaurantId,
        targetName: order.restaurantName,
        targetImageUrl: order.restaurantImageUrl,
      ),
      riderTarget: order.driverName != null && order.driverName!.isNotEmpty
          ? ReportFlowArgs(
              role: ReportRole.customer,
              targetType: ReportTargetType.rider,
              orderId: order.id,
              targetName: order.driverName!,
              targetPhone: order.driverPhone,
            )
          : null,
    ),
  );
}

class _OrderCard extends StatelessWidget {
  final ConsumerOrder order;
  final VoidCallback onTap;
  final VoidCallback onReorder;
  final VoidCallback onReport;

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onReorder,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: w * 0.04),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(w * 0.04),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with restaurant info
            Padding(
              padding: EdgeInsets.all(w * 0.04),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(w * 0.025),
                    child: SizedBox(
                      width: w * 0.155,
                      height: w * 0.155,
                      child: Image.network(
                        order.restaurantImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.shimmerBase,
                          child: const Icon(
                            Icons.restaurant,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.restaurantName,
                          style: TextStyle(
                            fontSize: w * 0.04,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: w * 0.008),
                        Text(
                          '${order.totalItems} item${order.totalItems > 1 ? 's' : ''} · GHS ${order.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: w * 0.032,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: w * 0.008),
                        Text(
                          _formatDate(order.placedAt),
                          style: TextStyle(
                            fontSize: w * 0.028,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Status bar
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.04,
                vertical: w * 0.025,
              ),
              decoration: BoxDecoration(
                color: _statusColor(order.status).withValues(alpha: 0.08),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(w * 0.04),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: w * 0.02,
                    height: w * 0.02,
                    decoration: BoxDecoration(
                      color: _statusColor(order.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: w * 0.02),
                  Text(
                    order.status.label,
                    style: TextStyle(
                      fontSize: w * 0.033,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(order.status),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onReport,
                    child: Padding(
                      padding: EdgeInsets.only(right: w * 0.035),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedFlag02,
                        color: AppColors.textHint,
                        size: w * 0.04,
                      ),
                    ),
                  ),
                  if (order.status.isActive)
                    GestureDetector(
                      onTap: onTap,
                      child: Text(
                        'Track →',
                        style: TextStyle(
                          fontSize: w * 0.033,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  if (!order.status.isActive &&
                      order.status != OrderStatus.cancelled)
                    GestureDetector(
                      onTap: onReorder,
                      child: Text(
                        'Reorder →',
                        style: TextStyle(
                          fontSize: w * 0.033,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
      case OrderStatus.onTheWay:
      case OrderStatus.pickedUp:
        return AppColors.info;
      default:
        return AppColors.accent;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
