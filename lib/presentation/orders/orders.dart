import 'package:bagyesrushappusernew/constant/constant.dart';
import 'package:bagyesrushappusernew/core/router/router.dart';
import 'package:bagyesrushappusernew/src/orders/models/order.dart';
import 'package:bagyesrushappusernew/src/orders/viewmodels/orders_state.dart';
import 'package:bagyesrushappusernew/src/orders/viewmodels/orders_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

const _finalStatuses = {
  'delivered',
  'completed',
  'cancelled',
  'rejected',
  'failed',
};

class Orders extends StatefulWidget {
  @override
  _OrdersState createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  @override
  void initState() {
    super.initState();
    context.read<OrderViewModel>().getCustomerOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: scaffoldBgColor,
        automaticallyImplyLeading: false,
        elevation: 1.0,
        title: Text('Orders', style: appBarBlackTextStyle),
      ),
      body: Consumer<OrderViewModel>(
        builder: (context, viewModel, _) {
          final state = viewModel.state;
          return switch (state) {
            OrdersInitial() ||
            OrdersLoading() => Center(
              child: SpinKitCircle(size: 40.0, color: primaryColor),
            ),
            OrdersError(:final message) => _ErrorView(
              message: message,
              onRetry: () => viewModel.getCustomerOrders(),
            ),
            OrdersLoaded(:final orders) => _OrdersListView(orders: orders),
            OrderDetailsLoaded() || MenuLoadedState() => const SizedBox.shrink(),
          };
        },
      ),
    );
  }
}

class _OrdersListView extends StatelessWidget {
  const _OrdersListView({required this.orders});

  final List<Order> orders;

  bool _isActive(Order order) =>
      !_finalStatuses.contains(order.status.toLowerCase());

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _EmptyView(
        onRefresh: () => context.read<OrderViewModel>().getCustomerOrders(),
      );
    }

    final activeOrders = orders.where(_isActive).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    final pastOrders = orders.where((o) => !_isActive(o)).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () => context.read<OrderViewModel>().getCustomerOrders(),
      child: ListView(
        children: [
          if (activeOrders.isNotEmpty) ...[
            _sectionHeader('Active orders'),
            for (final order in activeOrders)
              _OrderCard(order: order, isActive: true),
          ],
          if (pastOrders.isNotEmpty) ...[
            _sectionHeader('Past orders'),
            for (final order in pastOrders)
              _OrderCard(order: order, isActive: false),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: fixPadding,
        bottom: fixPadding,
        right: fixPadding * 2.0,
        left: fixPadding * 2.0,
      ),
      color: Colors.grey[100],
      child: Text(title, style: blackSmallBoldTextStyle),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.isActive});

  final Order order;
  final bool isActive;

  String get _title {
    if (order.items.isEmpty) return 'Order #${order.id.substring(0, order.id.length < 8 ? order.id.length : 8)}';
    final first = order.items.first.name;
    final extra = order.items.length - 1;
    return extra > 0 ? '$first +$extra more' : first;
  }

  int get _itemCount => order.items.fold(0, (sum, item) => sum + item.quantity);

  Color get _statusColor {
    switch (order.status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
      case 'failed':
        return Colors.red;
      default:
        return primaryColor;
    }
  }

  String get _statusLabel {
    final normalized = order.status.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) return 'Pending';
    return normalized
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(fixPadding * 2.0),
      color: whiteColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44.0,
                    height: 44.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22.0),
                      color: primaryColor.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: primaryColor,
                      size: 24.0,
                    ),
                  ),
                  widthSpace,
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 160.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          style: blackLargeTextStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5.0),
                        Text(_formatDate(order.createdAt), style: greySmallTextStyle),
                      ],
                    ),
                  ),
                ],
              ),
              Icon(Icons.arrow_forward_ios, size: 18.0, color: greyColor),
            ],
          ),
          heightSpace,
          if (order.deliveryAddress.isNotEmpty) ...[
            Text(
              order.deliveryAddress,
              style: greySmallTextStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            heightSpace,
          ],
          Text(
            '$_itemCount item${_itemCount == 1 ? '' : 's'} · Paid: \$${order.totalAmount.toStringAsFixed(2)}',
            style: primaryColorSmallTextStyle,
          ),
          heightSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 10.0,
                    height: 10.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _statusColor,
                    ),
                  ),
                  widthSpace,
                  Text(_statusLabel, style: blackSmallBoldTextStyle),
                ],
              ),
              if (isActive)
                InkWell(
                  onTap: () => AppNavigator.toOrderTracking(context, order.id),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: fixPadding * 0.7,
                      bottom: fixPadding * 0.7,
                      right: fixPadding * 3.0,
                      left: fixPadding * 3.0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40.0),
                      color: primaryColor,
                    ),
                    child: Text('Track order', style: whiteBottonTextStyle),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour24 = date.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, $hour12:$minute $period';
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: primaryColor,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Icon(Icons.receipt_long_outlined, size: 70.0, color: greyColor),
          heightSpace,
          Center(child: Text('No orders yet', style: blackLargeTextStyle)),
          const SizedBox(height: 6.0),
          Center(
            child: Text(
              'Orders you place will show up here',
              style: greySmallTextStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(fixPadding * 2.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 50.0, color: greyColor),
            heightSpace,
            Text(
              message,
              style: greySmallTextStyle,
              textAlign: TextAlign.center,
            ),
            heightSpace,
            InkWell(
              onTap: onRetry,
              child: Container(
                padding: EdgeInsets.only(
                  top: fixPadding * 0.7,
                  bottom: fixPadding * 0.7,
                  right: fixPadding * 3.0,
                  left: fixPadding * 3.0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40.0),
                  color: primaryColor,
                ),
                child: Text('Try again', style: whiteBottonTextStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
