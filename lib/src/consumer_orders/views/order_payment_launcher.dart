import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/core/router/app_navigator.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/order_payment_outcome.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/order_payment_verification.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/payment_receipt.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/views/payment_receipt_view.dart';
import 'package:bagyesrushappusernew/src/payment/views/screens/payment_webview_screen.dart';

export 'package:bagyesrushappusernew/src/consumer_orders/models/order_payment_outcome.dart';

/// An expected, already user-worded payment failure — callers show
/// [message] as-is instead of a generic error.
class OrderPaymentException implements Exception {
  final String message;
  const OrderPaymentException(this.message);
}

/// Runs the Paystack payment for any customer order (food or parcel) via the
/// order-scoped endpoints: `POST customer/orders/:id/pay` → hosted checkout
/// in [PaymentWebViewScreen] → `POST customer/orders/:id/verify-payment`,
/// presented as a [PaymentReceiptView].
///
/// Connection-level failures are retried inside the repository; anything
/// that reaches the caller is ambiguous enough (a charge may already have
/// been initiated) that it's surfaced for a manual retry, never retried
/// automatically.
class OrderPaymentLauncher {
  const OrderPaymentLauncher._();

  /// The backend's `payment_method` for [OrdersViewModel.payOrder]. Nothing
  /// else is sent: Paystack's hosted page is where the customer picks how to
  /// pay, so no saved number or network is looked up or forwarded.
  static const _paymentMethod = 'mobile_money';

  /// Starts the Paystack payment for [orderId]: `POST customer/orders/:id/pay`
  /// → hosted checkout → once the customer is back from the gateway the
  /// payment is checked and shown as a receipt. The result says how it ended
  /// and where the customer asked to go next.
  static Future<OrderPaymentResult> pay(
    BuildContext context, {
    required String orderId,
  }) async {
    final orders = context.read<OrdersViewModel>();
    final payResponse = await orders.payOrder(
      orderId,
      paymentMethod: _paymentMethod,
    );
    if (!context.mounted) return _dismissed;

    final reference =
        (payResponse['reference'] ?? payResponse['payment_reference'])
            ?.toString();
    final paymentUrl =
        (payResponse['authorization_url'] ??
                payResponse['payment_url'] ??
                payResponse['paymentUrl'])
            ?.toString();

    OrderPaymentVerification? initialCheck;
    if (paymentUrl != null && paymentUrl.isNotEmpty) {
      final leftGateway = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(paymentUrl: paymentUrl),
        ),
      );
      if (!context.mounted) return _dismissed;
      if (leftGateway != true) {
        initialCheck = await _checkAfterDismissal(orders, orderId, reference);
        if (initialCheck == null) return _dismissed;
        if (!context.mounted) {
          return OrderPaymentResult(
            initialCheck.isPaid
                ? OrderPaymentOutcome.paid
                : OrderPaymentOutcome.failed,
          );
        }
      }
    }

    final result = await PaymentReceiptView.open(
      context,
      PaymentReceiptArgs(
        orderId: orderId,
        reference: reference,
        initialCheck: initialCheck,
      ),
    );
    if (result.outcome == OrderPaymentOutcome.processing) {
      orders.markAwaitingPaymentConfirmation(orderId);
    }
    if (result.exit == PaymentExit.retry && context.mounted) {
      return pay(context, orderId: orderId);
    }
    return result;
  }

  static const _dismissed = OrderPaymentResult(OrderPaymentOutcome.dismissed);

  /// Pays for a just-created order (skipped when nothing is due), then
  /// replaces the checkout flow with tracking — or home, if that's where the
  /// customer left the receipt for — so back can't return to, and resubmit,
  /// checkout. Any follow-up (payment not finished, failed, still
  /// confirming) is shown as a snackbar on the destination screen.
  static Future<void> payThenTrack(
    BuildContext context, {
    required String orderId,
    required bool requiresPayment,
    String settledMessage = 'Order confirmed.',
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    String? message = settledMessage;
    var exit = PaymentExit.track;
    if (requiresPayment) {
      try {
        final result = await pay(context, orderId: orderId);
        message = result.outcome.followUpMessage;
        exit = result.exit;
      } on OrderPaymentException catch (e) {
        message = e.message;
      } catch (_) {
        message = 'Payment failed. You can retry from the tracking screen.';
      }
    }
    if (!context.mounted) return;
    if (exit == PaymentExit.home) {
      AppNavigator.toHome(context);
    } else {
      AppNavigator.goToOrderTracking(context, orderId);
    }
    if (message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// Closing the gateway before its redirect doesn't prove nothing was paid
  /// (e.g. closed on Paystack's own success screen) — check quietly first.
  /// Returns the check when it settled (paid or failed) so the customer sees
  /// a receipt, or null when nothing was charged / it can't be told, in which
  /// case the customer simply closed the checkout and "Pay Now" stays on
  /// offer.
  static Future<OrderPaymentVerification?> _checkAfterDismissal(
    OrdersViewModel orders,
    String orderId,
    String? reference,
  ) async {
    if (reference == null || reference.isEmpty) return null;
    final check = await orders.checkPayment(orderId, reference: reference);
    return check.isPending ? null : check;
  }
}
