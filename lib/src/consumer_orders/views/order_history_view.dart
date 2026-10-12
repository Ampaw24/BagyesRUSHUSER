import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/core/utils/date_time_format.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_state.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/order_history_card.dart';

/// Every finished order — delivered, cancelled, declined or refunded — newest
/// first, grouped by month. Orders still in progress live under My Orders.
///
/// Reads the app-wide [OrdersViewModel], so it shares that list's paging and
/// refresh rather than loading its own copy.
class OrderHistoryView extends StatefulWidget {
  const OrderHistoryView({super.key});

  @override
  State<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<OrderHistoryView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreNearEnd);
    // Re-fetches after a sign-out/sign-in within the same app run; the
    // shared view model only loads by itself when first created.
    context.read<OrdersViewModel>().ensureLoaded();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMoreNearEnd() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      context.read<OrdersViewModel>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OrdersViewModel>().state;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Order History')),
      body: switch (state) {
        OrdersLoading() => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        OrdersError() => _MessageState(
          icon: Icons.wifi_off_rounded,
          title: "Couldn't load your orders",
          message: 'Check your connection and try again.',
          onRetry: context.read<OrdersViewModel>().refresh,
        ),
        OrdersLoaded() => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: context.read<OrdersViewModel>().refresh,
          child: state.past.isEmpty
              ? const _EmptyHistory()
              : _HistoryList(
                  orders: state.past,
                  isLoadingMore: state.isLoadingMore,
                  controller: _scrollController,
                ),
        ),
      },
    );
  }
}

/// A month heading or an order beneath it.
sealed class _HistoryRow {
  const _HistoryRow();
}

class _MonthRow extends _HistoryRow {
  const _MonthRow(this.label);
  final String label;
}

class _OrderRow extends _HistoryRow {
  const _OrderRow(this.order);
  final ConsumerOrder order;
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.orders,
    required this.isLoadingMore,
    required this.controller,
  });

  final List<ConsumerOrder> orders;
  final bool isLoadingMore;
  final ScrollController controller;

  /// Orders in feed order, with a heading wherever the month changes.
  List<_HistoryRow> _rows() {
    final rows = <_HistoryRow>[];
    String? currentMonth;
    for (final order in orders) {
      final month = formatMonthYear(order.placedAt);
      if (month != currentMonth) {
        currentMonth = month;
        rows.add(_MonthRow(month));
      }
      rows.add(_OrderRow(order));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final rows = _rows();

    return ListView.builder(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        w * 0.05,
        w * 0.02,
        w * 0.05,
        MediaQuery.paddingOf(context).bottom + w * 0.05,
      ),
      itemCount: rows.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= rows.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: w * 0.05),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          );
        }
        return switch (rows[index]) {
          _MonthRow(:final label) => _MonthHeading(label: label),
          _OrderRow(:final order) => OrderHistoryCard(
            order: order,
            onTap: () => context.push(AppRoutes.trackOrder, extra: order.id),
          ),
        };
      },
    );
  }
}

class _MonthHeading extends StatelessWidget {
  const _MonthHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.01, w * 0.03, 0, w * 0.025),
      child: Text(
        label,
        style: TextStyle(
          fontSize: w * 0.034,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Scrollable so the surrounding [RefreshIndicator] has something to pull.
class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: height * 0.7,
          child: const _MessageState(
            icon: Icons.receipt_long_rounded,
            title: 'No order history yet',
            message: 'Your delivered and cancelled orders will show up here.',
          ),
        ),
      ],
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: w * 0.18, color: AppColors.textHint),
            SizedBox(height: w * 0.04),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.044,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.015),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.033,
                color: AppColors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: w * 0.05),
              OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}
