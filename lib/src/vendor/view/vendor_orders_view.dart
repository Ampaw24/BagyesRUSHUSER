import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constant/app_theme.dart';
import '../../../core/utils/active_poller.dart';
import 'package:bagyesrushappusernew/src/report/model/report.dart';
import 'package:bagyesrushappusernew/src/report/views/report_flow_args.dart';
import 'package:bagyesrushappusernew/src/report/widgets/report_quick_action_sheet.dart';
import '../model/vendor_order.dart';
import '../viewmodel/orders_viewmodel.dart';
import 'widgets/accept_order_dialog.dart';
import 'widgets/order_card.dart';
import 'widgets/order_reason_sheet.dart';

class VendorOrdersView extends StatefulWidget {
  /// Whether this tab is the one on screen — VendorHome's [IndexedStack]
  /// keeps it alive while hidden, so it has to be told. Becoming active
  /// refreshes the list, so an order accepted from the dashboard (or one
  /// that arrived meanwhile) shows without a manual pull-to-refresh.
  final bool isActive;

  const VendorOrdersView({super.key, this.isActive = true});

  @override
  State<VendorOrdersView> createState() => _VendorOrdersViewState();
}

class _VendorOrdersViewState extends State<VendorOrdersView> {
  static const _searchDebounce = Duration(milliseconds: 350);

  // Same cadence as the dashboard's poll, so order status changes made
  // elsewhere (customer cancels, rider picks up) show up without a pull.
  static const _pollInterval = Duration(seconds: 15);

  OrderStatus? _activeFilter;
  final _searchController = TextEditingController();
  Timer? _searchDebounceTimer;

  // Polls only while this tab is on screen and the app is in the
  // foreground; showing the tab again polls immediately.
  late final _poller = ActivePoller(
    interval: _pollInterval,
    onPoll: _backgroundRefresh,
  );

  @override
  void initState() {
    super.initState();
    _poller.attach(active: widget.isActive);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OrdersViewModel>().loadOrders(search: _searchQuery);
    });
  }

  @override
  void didUpdateWidget(covariant VendorOrdersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _poller.setActive(widget.isActive);
  }

  @override
  void dispose() {
    _poller.dispose();
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String? get _searchQuery {
    final query = _searchController.text.trim();
    return query.isEmpty ? null : query;
  }

  /// Refreshes without a spinner and keeps the current search, so the
  /// list updates in place. Skipped while a foreground load (first load,
  /// search, pull-to-refresh) is already fetching.
  void _backgroundRefresh() {
    if (!mounted) return;
    final vm = context.read<OrdersViewModel>();
    if (vm.state.status == OrdersStatus.loading) return;
    vm.loadOrders(search: _searchQuery, silent: true);
  }

  void _setFilter(OrderStatus? status) {
    setState(() => _activeFilter = status);
  }

  void _onSearchChanged(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      context.read<OrdersViewModel>().loadOrders(search: _searchQuery);
    });
  }

  Future<void> _handleAccept(VendorOrder order) {
    return showAcceptOrderDialog(
      context,
      onAccept: (minutes) => context.read<OrdersViewModel>().accept(
        order.id,
        estimatedPrepMinutes: minutes,
      ),
    );
  }

  Future<void> _handleReject(VendorOrder order) async {
    final reason = await OrderReasonSheet.show(
      context,
      title: 'Reject Order',
      confirmLabel: 'Reject Order',
    );
    if (reason == null || !mounted) return;
    context.read<OrdersViewModel>().reject(order.id, reason: reason);
  }

  Future<void> _handleCancel(VendorOrder order) async {
    final reason = await OrderReasonSheet.show(
      context,
      title: 'Cancel Order',
      confirmLabel: 'Cancel Order',
    );
    if (reason == null || !mounted) return;
    context.read<OrdersViewModel>().cancel(order.id, reason: reason);
  }

  Future<void> _handleRefresh() {
    return context.read<OrdersViewModel>().loadOrders(search: _searchQuery);
  }

  /// Makes [child] fill and scroll within the available height, so
  /// [RefreshIndicator] still has a scrollable to detect the pull gesture
  /// against even when showing the loading spinner or empty state instead
  /// of the order list.
  Widget _scrollableFill(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final horizontalPad = w * 0.05;
    final vm = context.watch<OrdersViewModel>();
    final allOrders = vm.state.orders;
    final orders = _activeFilter == null
        ? allOrders
        : allOrders.where((o) => o.status == _activeFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header with order count ──
        Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPad,
            w * 0.03,
            horizontalPad,
            0,
          ),
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

        // ── Search ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPad),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search orders...',
              prefixIcon: Icon(
                Icons.search,
                size: w * 0.05,
                color: AppColors.textHint,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(vertical: w * 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(w * 0.03),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(w * 0.03),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
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
                count: allOrders.length,
                selected: _activeFilter == null,
                onTap: () => _setFilter(null),
              ),
              for (final status in OrderStatus.values) ...[
                SizedBox(width: w * 0.02),
                _FilterChip(
                  label: status.label,
                  count: allOrders.where((o) => o.status == status).length,
                  color: status.color,
                  selected: _activeFilter == status,
                  onTap: () => _setFilter(status),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: w * 0.035),

        // ── Order list ──
        Expanded(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.primary,
            child: vm.state.status == OrdersStatus.loading && allOrders.isEmpty
                ? _scrollableFill(
                    const Center(child: CircularProgressIndicator()),
                  )
                : orders.isEmpty
                ? _scrollableFill(
                    _EmptyView(w: w, filter: _activeFilter?.label),
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPad,
                      0,
                      horizontalPad,
                      w * 0.25,
                    ),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => SizedBox(height: w * 0.03),
                    itemBuilder: (_, index) {
                      final order = orders[index];
                      return OrderCard(
                        order: order,
                        onTap: () {},
                        onAccept: () => _handleAccept(order),
                        onDecline: () => _handleReject(order),
                        onMarkPreparing: () => vm.markPreparing(order.id),
                        onMarkReady: () => vm.markReady(order.id),
                        onMarkOutForDelivery: () =>
                            vm.markOutForDelivery(order.id),
                        onMarkDelivered: (pin) =>
                            vm.markDelivered(order.id, deliveryPin: pin),
                        onCancel: () => _handleCancel(order),
                        onReport: () => ReportQuickActionSheet.show(
                          context,
                          role: ReportRole.vendor,
                          orderId: order.id,
                          primaryTarget: order.customerName.isEmpty
                              ? null
                              : ReportFlowArgs(
                                  role: ReportRole.vendor,
                                  targetType: ReportTargetType.customer,
                                  orderId: order.id,
                                  targetName: order.customerName,
                                  targetPhone: order.customerPhone,
                                ),
                          riderTarget:
                              order.driverName != null &&
                                  order.driverName!.isNotEmpty
                              ? ReportFlowArgs(
                                  role: ReportRole.vendor,
                                  targetType: ReportTargetType.rider,
                                  orderId: order.id,
                                  targetName: order.driverName!,
                                  targetPhone: order.driverPhone,
                                )
                              : null,
                        ),
                      );
                    },
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
          border: Border.all(color: selected ? chipColor : AppColors.border),
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
            style: TextStyle(fontSize: w * 0.03, color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
