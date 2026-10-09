import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/core/router/app_navigator.dart';
import 'package:bagyesrushappusernew/core/services/realtime_service.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/payment_receipt.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/views/order_payment_launcher.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/views/payment_receipt_view.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/cancel_order_reason_sheet.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/order_codes_panel.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/order_tracking_placeholders.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/parcel_route_card.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/parcel_tracking_timeline.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/tracking_card.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/tracking_header.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/tracking_live_map.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/tracking_order_summary.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/tracking_progress_stepper.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/tracking_reveal.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/tracking_rider_card.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/tracking_status_hero.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/review_target.dart';
import 'package:bagyesrushappusernew/src/order_reviews/viewmodels/order_reviews_viewmodel.dart';
import 'package:bagyesrushappusernew/src/order_reviews/views/order_review_sheet.dart';
import 'package:bagyesrushappusernew/src/order_reviews/widgets/rate_order_card.dart';

class OrderTrackingView extends StatefulWidget {
  final String orderId;

  const OrderTrackingView({super.key, required this.orderId});

  @override
  State<OrderTrackingView> createState() => _OrderTrackingViewState();
}

class _OrderTrackingViewState extends State<OrderTrackingView>
    with WidgetsBindingObserver {
  bool _isPaying = false;
  bool _isCancelling = false;

  /// In flight / failed state of a fetch — only surfaced while no copy of
  /// the order is cached; once one is, stale data beats a blocking error.
  bool _isLoading = false;
  bool _loadFailed = false;
  StreamSubscription<RealtimeChannelError>? _channelErrorSub;

  /// Auto review prompt: fires once, only when this screen watches the order
  /// go from active to delivered — reopening a delivered order just shows
  /// the inline [RateOrderCard] instead of nagging.
  static const _reviewPromptDelay = Duration(milliseconds: 1200);
  late final OrdersViewModel _orders = context.read<OrdersViewModel>();
  OrderStatus? _lastSeenStatus;
  bool _reviewPrompted = false;
  Timer? _reviewPromptTimer;

  /// Polls while a payment the customer completed is still unconfirmed, so
  /// "Pay Now" comes back (or the order flips to paid) without a manual pull.
  static const _paymentPollInterval = Duration(seconds: 8);
  Timer? _paymentPoll;
  bool _wasAwaitingPayment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastSeenStatus = _orders.orderById(widget.orderId)?.status;
    _orders.addListener(_onOrdersChanged);
    context.read<OrderReviewsViewModel>().ensureLoaded();
    // One-shot REST fetch — covers a deep-linked cold start (e.g. from a
    // push notification) where this order isn't cached yet; realtime events
    // for an uncached order are dropped by OrdersViewModel, so this must
    // run regardless of the socket subscription below.
    _refresh();
    sl<RealtimeService>().subscribeToOrder(widget.orderId);
    _channelErrorSub = sl<RealtimeService>().channelErrors.listen(
      _onChannelError,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _orders.removeListener(_onOrdersChanged);
    _reviewPromptTimer?.cancel();
    _paymentPoll?.cancel();
    sl<RealtimeService>().unsubscribeFromOrder(widget.orderId);
    _channelErrorSub?.cancel();
    super.dispose();
  }

  void _onOrdersChanged() {
    _syncPaymentConfirmation();
    final status = _orders.orderById(widget.orderId)?.status;
    if (status == null) return;
    final previous = _lastSeenStatus;
    _lastSeenStatus = status;
    if (_reviewPrompted ||
        previous == null ||
        !previous.isActive ||
        status != OrderStatus.delivered) {
      return;
    }
    _reviewPrompted = true;
    _reviewPromptTimer = Timer(_reviewPromptDelay, _promptReview);
  }

  void _promptReview() {
    // Don't cover another route (e.g. chat) the customer has opened on top.
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    final order = _orders.orderById(widget.orderId);
    if (order == null ||
        context.read<OrderReviewsViewModel>().isReviewed(order.id)) {
      return;
    }
    OrderReviewSheet.show(context, target: ReviewTarget.fromOrder(order));
  }

  /// A 403 here means this account has no stake in this order's channel
  /// (wrong id, or genuinely not a participant) — shown distinctly from a
  /// generic connection failure. A session-expiry error needs no separate
  /// handling: the rest of the app's existing token-refresh/login-redirect
  /// flow already reacts to a cleared session.
  void _onChannelError(RealtimeChannelError error) {
    if (!mounted) return;
    if (error.channelName !=
        sl<RealtimeService>().orderChannelName(widget.orderId)) {
      return;
    }
    if (error.type != RealtimeChannelErrorType.forbidden) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Live tracking isn't available for this order."),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sl<RealtimeService>().subscribeToOrder(widget.orderId);
      _refresh(); // catch up on anything missed while backgrounded
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      sl<RealtimeService>().unsubscribeFromOrder(widget.orderId);
    }
  }

  /// Failures keep the last-known-good state — realtime updates or the next
  /// refresh catch up. [userInitiated] (pull-to-refresh) surfaces the
  /// failure; background refreshes stay silent unless nothing is cached.
  Future<void> _refresh({bool userInitiated = false}) async {
    if (!mounted || _isLoading) return;
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    var failed = false;
    try {
      await context.read<OrdersViewModel>().trackOrder(widget.orderId);
    } catch (_) {
      failed = true;
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _loadFailed = failed;
    });
    if (failed && userInitiated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn\'t refresh. Showing the latest we have.'),
        ),
      );
    }
  }

  /// Starts/stops polling for an unconfirmed payment, and celebrates when
  /// one this screen was waiting on comes through as paid.
  void _syncPaymentConfirmation() {
    final awaiting = _orders.isAwaitingPaymentConfirmation(widget.orderId);
    if (awaiting && _paymentPoll == null) {
      _paymentPoll = Timer.periodic(_paymentPollInterval, (_) => _refresh());
    } else if (!awaiting && _paymentPoll != null) {
      _paymentPoll!.cancel();
      _paymentPoll = null;
    }

    final nowPaid =
        _orders.orderById(widget.orderId)?.paymentStatus == PaymentStatus.paid;
    if (_wasAwaitingPayment &&
        !awaiting &&
        nowPaid &&
        mounted &&
        ModalRoute.of(context)?.isCurrent == true) {
      _openReceipt();
    }
    _wasAwaitingPayment = awaiting;
  }

  /// Shows the payment receipt for this order. Leaving it for "Home" is the
  /// only exit that moves off this screen — "track" is already where we are.
  Future<void> _openReceipt() async {
    final result = await PaymentReceiptView.open(
      context,
      PaymentReceiptArgs(orderId: widget.orderId, knownPaid: true),
    );
    if (mounted && result.exit == PaymentExit.home) {
      AppNavigator.toHome(context);
    }
  }

  /// Runs the shared Paystack flow ([OrderPaymentLauncher]). Failures are
  /// surfaced with a manual "Retry" rather than retried automatically, since
  /// a charge may already have been initiated.
  Future<void> _payNow(String orderId) async {
    if (_isPaying) return;
    setState(() => _isPaying = true);
    try {
      final result = await OrderPaymentLauncher.pay(context, orderId: orderId);
      if (mounted && result.exit == PaymentExit.home) {
        AppNavigator.toHome(context);
        return;
      }
      final message = result.outcome.followUpMessage;
      if (mounted && message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (!mounted) return;
      final message = e is OrderPaymentException
          ? e.message
          : 'Payment failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _payNow(orderId),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  /// Opens [CancelOrderReasonSheet] to collect a required cancellation
  /// reason, then cancels the order. Mirrors [_payNow]'s loading/error/retry
  /// shape: guarded by [_isCancelling]; failures surface a SnackBar with a
  /// "Retry" action that re-runs this method from the top (including
  /// re-prompting for the reason).
  Future<void> _cancelOrder(String orderId) async {
    if (_isCancelling) return;

    final reason = await CancelOrderReasonSheet.show(context);
    if (reason == null || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      await context.read<OrdersViewModel>().cancelOrder(
        orderId,
        reason: reason,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Couldn\'t cancel your order. Please try again.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _cancelOrder(orderId),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  void _openChat(ConsumerOrder order) => AppNavigator.showChatThread(
        context,
        orderId: order.id,
        peerName: order.driverName,
        peerPhone: order.driverPhone,
        peerPhotoUrl: order.driverPhotoUrl,
      );

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderId;
    final ordersVm = context.watch<OrdersViewModel>();
    final order = ordersVm.orderById(orderId);
    final isConfirmingPayment = ordersVm.isAwaitingPaymentConfirmation(orderId);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
          bottom: false,
          child: order == null
              ? Column(
                  children: [
                    const TrackingHeader(title: 'Track order'),
                    Expanded(
                      child: _loadFailed
                          ? OrderTrackingErrorView(
                              isRetrying: _isLoading,
                              onRetry: _refresh,
                              onExit: () => AppNavigator.toHome(context),
                            )
                          : const OrderTrackingSkeleton(),
                    ),
                  ],
                )
              : _buildTracking(order, isConfirmingPayment),
        ),
      ),
    );
  }

  Widget _buildTracking(ConsumerOrder order, bool isConfirmingPayment) {
    final w = MediaQuery.sizeOf(context).width;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isParcel = order.isParcel;
    final hasRider = order.driverName != null;
    // Chat is scoped to orders still in progress — gone once the order is
    // delivered, cancelled or refunded (as in the chat inbox).
    final canChat = order.status.isActive;
    final shortId = order.id.split('-').last;
    final vendorName = order.restaurantName.trim();

    // Parcel sections ease in one after another. Keyed so a section that
    // appears later (e.g. the rider card once one is assigned) animates on
    // its own instead of replaying its neighbours.
    Widget reveal(String name, int index, Widget child) => isParcel
        ? TrackingReveal(
            key: ValueKey('reveal-$name'),
            delay: TrackingReveal.stagger(index),
            child: child,
          )
        : child;

    return Column(
      children: [
        TrackingHeader(
          title: isParcel ? 'Track parcel' : 'Track order',
          subtitle: isParcel
              ? [
                  'Parcel #$shortId',
                  order.isReceiveParcel ? 'Receive' : 'Send',
                ].join(' · ')
              : [
                  'Order #$shortId',
                  if (vendorName.isNotEmpty) vendorName,
                ].join(' · '),
          actions: [
            // Once a rider is assigned, chat moves onto the rider card. A
            // parcel has no one to chat with until then.
            if (canChat && !hasRider && !isParcel)
              TrackingCircleButton(
                icon: Icons.chat_bubble_outline_rounded,
                tooltip: 'Chat',
                onTap: () => _openChat(order),
              ),
          ],
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _refresh(userInitiated: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                w * 0.05,
                w * 0.01,
                w * 0.05,
                w * 0.06 + bottomInset,
              ),
              children: [
                // ── Live rider location (once en route) ──
                if (order.riderLocation != null &&
                    _isEnRoute(order.status)) ...[
                  TrackingLiveMap(riderLocation: order.riderLocation!),
                  SizedBox(height: w * 0.06),
                ],

                // ── Status headline ──
                reveal(
                  'hero',
                  0,
                  TrackingStatusHero(
                    order: order,
                    isConfirmingPayment: isConfirmingPayment,
                  ),
                ),
                SizedBox(height: w * 0.07),

                // ── Progress ──
                // Parcels get a courier-style timeline; the food stepper's
                // "Preparing food" step means nothing for a package. The
                // timeline also shows how a parcel ended (cancelled,
                // declined, refunded); a food order's stepper just hides.
                if (isParcel ||
                    (!order.status.isCancelledOrDeclined &&
                        order.status != OrderStatus.refunded)) ...[
                  if (isParcel) ...[
                    SizedBox(height: w * 0.01),
                    reveal('timeline', 1, ParcelTrackingTimeline(order: order)),
                    SizedBox(height: w * 0.05),
                  ] else ...[
                    TrackingProgressStepper(
                      status: order.status,
                      isParcel: false,
                    ),
                    SizedBox(height: w * 0.07),
                  ],
                ],

                // ── Rate & review (once delivered) ──
                if (order.status == OrderStatus.delivered) ...[
                  reveal('rate', 2, RateOrderCard(order: order)),
                  SizedBox(height: w * 0.05),
                ],

                // ── Delivery PIN, or a receive parcel's pickup + drop-off codes ──
                reveal('codes', 2, OrderCodesPanel(order: order)),

                // ── Rider ──
                if (hasRider) ...[
                  reveal(
                    'rider',
                    3,
                    TrackingRiderCard(
                      order: order,
                      onChat: canChat ? () => _openChat(order) : null,
                    ),
                  ),
                  SizedBox(height: w * (isParcel ? 0.05 : 0.06)),
                ],

                // ── Pickup → drop-off route and package (parcels) ──
                if (isParcel) ...[
                  reveal('route', 4, ParcelRouteCard(order: order)),
                  SizedBox(height: w * 0.06),
                ],

                // ── Items, total and order details ──
                reveal(
                  'summary',
                  5,
                  TrackingOrderSummary(
                    order: order,
                    onViewReceipt: order.paymentStatus == PaymentStatus.paid
                        ? _openReceipt
                        : null,
                  ),
                ),

                if (order.needsPayment) ...[
                  SizedBox(height: w * 0.03),
                  _PayNowButton(
                    isPaying: _isPaying,
                    isConfirming: isConfirmingPayment,
                    onPressed: () => _payNow(order.id),
                  ),
                ],

                if (order.canCancel) ...[
                  SizedBox(height: w * 0.03),
                  _CancelOrderButton(
                    isCancelling: _isCancelling,
                    onPressed: () => _cancelOrder(order.id),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────

/// Whether a rider is plausibly out on the road for this order — the only
/// phase the live-location map section is worth showing for.
bool _isEnRoute(OrderStatus status) =>
    status == OrderStatus.pickedUp || status == OrderStatus.onTheWay;

/// "Pay Now", disabled while a charge is in flight or awaiting server
/// confirmation — the customer must never be able to pay the same order
/// twice.
class _PayNowButton extends StatelessWidget {
  const _PayNowButton({
    required this.isPaying,
    required this.isConfirming,
    required this.onPressed,
  });

  final bool isPaying;
  final bool isConfirming;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final busy = isPaying || isConfirming;
    final spinner = SizedBox(
      width: w * 0.045,
      height: w * 0.045,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: isConfirming ? AppColors.textSecondary : Colors.white,
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, w * 0.12),
        ),
        child: isConfirming
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  spinner,
                  SizedBox(width: w * 0.025),
                  const Text('Confirming payment…'),
                ],
              )
            : isPaying
            ? spinner
            : const Text('Pay Now'),
      ),
    );
  }
}

class _CancelOrderButton extends StatelessWidget {
  const _CancelOrderButton({
    required this.isCancelling,
    required this.onPressed,
  });

  final bool isCancelling;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return OutlinedButton.icon(
      onPressed: isCancelling ? null : onPressed,
      icon: isCancelling
          ? SizedBox(
              width: w * 0.04,
              height: w * 0.04,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.error,
              ),
            )
          : Icon(Icons.cancel_outlined, size: w * 0.045),
      label: Text(isCancelling ? 'Cancelling…' : 'Cancel Order'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
        minimumSize: Size(double.infinity, w * 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(w * 0.035),
        ),
      ),
    );
  }
}
