import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/domain/entities/consumer_order.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/presentation/providers/orders_provider.dart';

class ConsumerOrdersView extends ConsumerWidget {
  const ConsumerOrdersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeOrdersProvider);
    final past = ref.watch(pastOrdersProvider);

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
            tabs: const [Tab(text: 'Active'), Tab(text: 'Past')],
          ),
        ),
        body: TabBarView(
          children: [
            _OrderList(orders: active, isActive: true),
            _OrderList(orders: past, isActive: false),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<ConsumerOrder> orders;
  final bool isActive;

  const _OrderList({required this.orders, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    if (orders.isEmpty) {
      return Center(
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
            if (isActive) ...[
              SizedBox(height: w * 0.06),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Browse Restaurants'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
          w * 0.05, w * 0.04, w * 0.05, w * 0.05),
      itemCount: orders.length,
      itemBuilder: (ctx, i) => _OrderCard(
        order: orders[i],
        onTap: () => context.push(
          AppRoutes.trackOrder,
          extra: orders[i].id,
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final ConsumerOrder order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

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
                          child: const Icon(Icons.restaurant,
                              color: AppColors.textHint),
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
                  if (order.status.isActive)
                    Text(
                      'Track →',
                      style: TextStyle(
                        fontSize: w * 0.033,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  if (!order.status.isActive &&
                      order.status != OrderStatus.cancelled)
                    Text(
                      'Reorder →',
                      style: TextStyle(
                        fontSize: w * 0.033,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
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
