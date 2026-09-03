import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/domain/entities/consumer_order.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/presentation/viewmodels/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/payment/model/payment_method.dart';
import 'package:bagyesrushappusernew/src/payment/model/payout_provider_model.dart';
import 'package:bagyesrushappusernew/src/payment/models/payment_channel.dart';
import 'package:bagyesrushappusernew/src/payment/repository/payment_repository.dart';
import 'package:bagyesrushappusernew/src/payment/views/screens/payment_webview_screen.dart';

/// Wraps a user-facing message so the catch-all in [_OrderTrackingViewState._payNow]
/// can distinguish an expected, already-worded failure from an unexpected one.
class _PayNowFailure implements Exception {
  final String message;
  const _PayNowFailure(this.message);
}

class OrderTrackingView extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingView({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingView> createState() => _OrderTrackingViewState();
}

class _OrderTrackingViewState extends ConsumerState<OrderTrackingView>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 15);
  Timer? _pollTimer;
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pollTimer?.cancel();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _poll();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  Future<void> _poll() async {
    final current = ref.read(orderByIdProvider(widget.orderId));
    if (current != null && !current.status.isActive) {
      _pollTimer?.cancel();
      return;
    }
    try {
      await ref.read(ordersProvider.notifier).trackOrder(widget.orderId);
    } catch (_) {
      // Transient blip on a background poll — keep the last-known-good
      // state and retry next tick, don't surface a SnackBar every 15s.
    }
  }

  /// Maps a saved payout/payment-method's provider record to the gateway's
  /// Matches free text (a provider's slug/name, or a saved method's label
  /// like "MTN 0987") against the gateway's [MobileMoneyProvider] enum.
  MobileMoneyProvider? _matchMobileMoneyProvider(String text) {
    final needle = text.toLowerCase();
    for (final p in MobileMoneyProvider.values) {
      if (needle.contains(p.apiValue)) return p;
    }
    if (needle.contains('airtel') || needle.contains('tigo')) {
      return MobileMoneyProvider.airtelTigo;
    }
    return null;
  }

  /// Resolves a saved payment method's mobile money network. The customer
  /// payment-methods list doesn't always embed the full `payout_provider`
  /// object (only `payout_provider_id`), so this tries, in order: the
  /// embedded provider's slug/name, the method's own label (often something
  /// like "MTN 0987"), then — only if neither matched — fetches the payout
  /// provider catalog and looks the id up there.
  Future<MobileMoneyProvider?> _resolveMobileMoneyProvider(PaymentMethod saved) async {
    final provider = saved.provider;
    if (provider != null) {
      final match =
          _matchMobileMoneyProvider('${provider.slug} ${provider.shortName} ${provider.name}');
      if (match != null) return match;
    }

    final byLabel = _matchMobileMoneyProvider(saved.label ?? '');
    if (byLabel != null) return byLabel;

    if (saved.payoutProviderId == 0) return null;
    final providers = await sl<PaymentRepository>().getPayoutProviders().then(
          (result) => result.fold((_) => const <PayoutProviderModel>[], (list) => list),
        );
    for (final p in providers) {
      if (p.id == saved.payoutProviderId) {
        return _matchMobileMoneyProvider('${p.slug} ${p.shortName} ${p.name}');
      }
    }
    return null;
  }

  /// Initiates payment for an order via the order-scoped endpoints
  /// (`POST customer/orders/:id/pay` → `POST customer/orders/:id/verify-payment`),
  /// using the customer's default saved mobile money method. Flow: fetch
  /// saved methods → hit `/pay` with phone + provider → (if a hosted
  /// checkout page comes back) show it in a WebView until the user is
  /// redirected away from the gateway → verify the charge by reference →
  /// refresh the order.
  ///
  /// Connection-level failures are already retried transparently inside the
  /// repository; anything that gets here (validation error, a timeout after
  /// the request reached the server, a 5xx, etc.) is ambiguous enough that
  /// we surface it and let the user decide to retry, rather than risk firing
  /// a second charge attempt automatically.
  Future<void> _payNow(String orderId, String paymentMethod) async {
    if (_isPaying) return;
    setState(() => _isPaying = true);
    try {
      if (paymentMethod != 'mobile_money') {
        throw const _PayNowFailure(
          'This payment method isn\'t supported yet. Please contact support.',
        );
      }

      final methods = await sl<PaymentRepository>().getCustomerPaymentMethods().then(
            (result) => result.fold(
              (failure) => throw _PayNowFailure(failure.message),
              (methods) => methods,
            ),
          );
      if (methods.isEmpty) {
        throw const _PayNowFailure(
          'No saved mobile money number. Add one under Payment Methods first.',
        );
      }
      final PaymentMethod saved =
          methods.firstWhere((m) => m.isDefault, orElse: () => methods.first);
      final mmProvider = await _resolveMobileMoneyProvider(saved);
      if (!mounted) return;
      if (mmProvider == null) {
        throw _PayNowFailure(
          'Couldn\'t match "${saved.displayTitle}" to a supported mobile money network.',
        );
      }

      final payResponse = await ref.read(ordersProvider.notifier).payOrder(
            orderId,
            paymentMethod: paymentMethod,
            phone: saved.phoneNumber,
            mobileMoneyProvider: mmProvider.apiValue,
          );

      if (!mounted) return;

      final paymentUrl =
          (payResponse['payment_url'] ?? payResponse['paymentUrl'])?.toString();
      if (paymentUrl != null && paymentUrl.isNotEmpty) {
        final leftGateway = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PaymentWebViewScreen(paymentUrl: paymentUrl),
          ),
        );
        // User closed the checkout page before the gateway redirected
        // anywhere — nothing to verify yet, so stop here without an error
        // toast.
        if (leftGateway != true) return;
      }

      if (!mounted) return;
      final reference = (payResponse['reference'] ?? payResponse['payment_reference'])?.toString();
      if (reference != null && reference.isNotEmpty) {
        await ref.read(ordersProvider.notifier).verifyPayment(orderId, reference: reference);
      } else {
        // No reference to verify against — just refresh right away so the
        // screen reflects whatever status the /pay call already produced,
        // without waiting for the next 15s poll tick.
        await ref.read(ordersProvider.notifier).trackOrder(orderId);
      }
    } catch (e) {
      if (!mounted) return;
      final message = e is _PayNowFailure ? e.message : 'Payment failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _payNow(orderId, paymentMethod),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderId;
    final order = ref.watch(orderByIdProvider(orderId));
    final w = MediaQuery.sizeOf(context).width;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Order')),
        body: const Center(child: Text('Order not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: Text('Order #${order.id.split('-').last}'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.06),
        children: [
          // ── Status banner ──
          _StatusBanner(order: order),
          SizedBox(height: w * 0.05),

          // ── Order timeline ──
          Text(
            'Order Progress',
            style: TextStyle(
              fontSize: w * 0.042,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.03),
          _OrderTimeline(currentStatus: order.status),
          SizedBox(height: w * 0.05),

          // ── Driver info (if picked up) ──
          if (order.driverName != null) ...[
            Text(
              'Your Driver',
              style: TextStyle(
                fontSize: w * 0.042,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.025),
            _DriverCard(order: order),
            SizedBox(height: w * 0.05),
          ],

          // ── Delivery address ──
          Text(
            'Delivery Address',
            style: TextStyle(
              fontSize: w * 0.042,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.025),
          Container(
            padding: EdgeInsets.all(w * 0.04),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(w * 0.035),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: AppColors.primary),
                SizedBox(width: w * 0.025),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    style: TextStyle(
                      fontSize: w * 0.035,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: w * 0.05),

          // ── Order items ──
          Text(
            'Items Ordered',
            style: TextStyle(
              fontSize: w * 0.042,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.025),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(w * 0.035),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: order.items
                  .map((item) => ListTile(
                        dense: true,
                        leading: Text(
                          '${item.quantity}×',
                          style: TextStyle(
                            fontSize: w * 0.035,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: TextStyle(fontSize: w * 0.035),
                        ),
                        trailing: Text(
                          'GHS ${item.lineTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: w * 0.033,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          SizedBox(height: w * 0.04),

          // ── Price summary ──
          Container(
            padding: EdgeInsets.all(w * 0.04),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(w * 0.035),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _PriceRow('Subtotal', order.subtotal),
                _PriceRow('Delivery fee', order.deliveryFee),
                _PriceRow('Service fee', order.serviceFee),
                if (order.discount > 0)
                  _PriceRow('Discount', -order.discount, color: AppColors.success),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: w * 0.015),
                  child: const Divider(color: AppColors.divider),
                ),
                _PriceRow('Total', order.total, isBold: true),
              ],
            ),
          ),
          SizedBox(height: w * 0.04),

          // ── Payment ──
          Container(
            padding: EdgeInsets.all(w * 0.04),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(w * 0.035),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.payment_rounded,
                    color: AppColors.textSecondary),
                SizedBox(width: w * 0.025),
                Text(
                  order.paymentStatus == PaymentStatus.pending
                      ? 'Payment pending — ${order.paymentMethod}'
                      : 'Paid via ${order.paymentMethod}',
                  style: TextStyle(
                    fontSize: w * 0.035,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          if (order.paymentStatus == PaymentStatus.pending) ...[
            SizedBox(height: w * 0.04),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPaying
                    ? null
                    : () => _payNow(orderId, order.paymentMethod),
                child: _isPaying
                    ? SizedBox(
                        width: w * 0.05,
                        height: w * 0.05,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Pay Now'),
              ),
            ),
          ],

          if (order.status == OrderStatus.pending ||
              order.status == OrderStatus.accepted ||
              order.status == OrderStatus.preparing) ...[
            SizedBox(height: w * 0.03),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => ref
                    .read(ordersProvider.notifier)
                    .cancelOrder(orderId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                child: const Text('Cancel Order'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final ConsumerOrder order;

  const _StatusBanner({required this.order});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isDelivered = order.status == OrderStatus.delivered;
    final isCancelled = order.status == OrderStatus.cancelled;
    final color = isCancelled
        ? AppColors.error
        : isDelivered
            ? AppColors.success
            : AppColors.primary;

    return Container(
      padding: EdgeInsets.all(w * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(w * 0.04),
      ),
      child: Row(
        children: [
          Icon(
            isDelivered
                ? Icons.check_circle_rounded
                : isCancelled
                    ? Icons.cancel_rounded
                    : Icons.delivery_dining_rounded,
            color: Colors.white,
            size: w * 0.12,
          ),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.status.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: w * 0.045,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (order.estimatedDelivery != null &&
                    order.status.isActive) ...[
                  SizedBox(height: w * 0.01),
                  Text(
                    'ETA: ${_etaLabel(order.estimatedDelivery!)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: w * 0.033,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _etaLabel(DateTime eta) {
    final remaining = eta.difference(DateTime.now());
    if (remaining.isNegative) return 'Any moment now';
    return '${remaining.inMinutes} min';
  }
}

class _OrderTimeline extends StatelessWidget {
  final OrderStatus currentStatus;

  const _OrderTimeline({required this.currentStatus});

  static const _steps = [
    (OrderStatus.pending, Icons.receipt_rounded, 'Order Placed'),
    (OrderStatus.accepted, Icons.check_rounded, 'Accepted'),
    (OrderStatus.preparing, Icons.restaurant_rounded, 'Preparing'),
    (OrderStatus.readyForPickup, Icons.room_service_rounded, 'Ready'),
    (OrderStatus.pickedUp, Icons.directions_bike_rounded, 'Picked Up'),
    (OrderStatus.onTheWay, Icons.delivery_dining_rounded, 'On the Way'),
    (OrderStatus.delivered, Icons.home_rounded, 'Delivered'),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final currentIndex =
        _steps.indexWhere((s) => s.$1 == currentStatus);

    return Column(
      children: List.generate(_steps.length, (i) {
        final step = _steps[i];
        final isDone = i <= currentIndex;
        final isCurrent = i == currentIndex;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: w * 0.1,
              child: Column(
                children: [
                  Container(
                    width: w * 0.08,
                    height: w * 0.08,
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDone
                            ? AppColors.primary
                            : AppColors.border,
                        width: isCurrent ? 2.5 : 1,
                      ),
                    ),
                    child: Icon(
                      step.$2,
                      size: w * 0.04,
                      color: isDone
                          ? Colors.white
                          : AppColors.textHint,
                    ),
                  ),
                  if (i < _steps.length - 1)
                    Container(
                      width: 2,
                      height: w * 0.08,
                      color: isDone && i < currentIndex
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                ],
              ),
            ),
            SizedBox(width: w * 0.02),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  top: w * 0.015,
                  bottom: w * 0.04,
                ),
                child: Text(
                  step.$3,
                  style: TextStyle(
                    fontSize: w * 0.035,
                    fontWeight: isCurrent
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: isDone
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final ConsumerOrder order;

  const _DriverCard({required this.order});

  bool get _canCall => (order.driverPhone ?? '').trim().isNotEmpty;

  Future<void> _callDriver(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: order.driverPhone!.replaceAll(' ', ''));
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start a call on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: w * 0.065,
            backgroundColor: AppColors.primary,
            child: Text(
              order.driverName![0],
              style: TextStyle(
                color: Colors.white,
                fontSize: w * 0.05,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: w * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.driverName!,
                  style: TextStyle(
                    fontSize: w * 0.038,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: w * 0.006),
                Text(
                  'Your delivery driver',
                  style: TextStyle(
                    fontSize: w * 0.03,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _canCall
                ? () {
                    HapticFeedback.lightImpact();
                    _callDriver(context);
                  }
                : null,
            child: Container(
              padding: EdgeInsets.all(w * 0.03),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.phone_rounded,
                  color: Colors.white, size: w * 0.045),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  final Color? color;

  const _PriceRow(this.label, this.value,
      {this.isBold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.01),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: w * 0.033,
              color: AppColors.textSecondary,
              fontWeight:
                  isBold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            'GHS ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isBold ? w * 0.038 : w * 0.033,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: color ??
                  (isBold ? AppColors.primary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
