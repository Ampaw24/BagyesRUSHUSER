import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/core/router/app_navigator.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
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
  ///
  /// With [stayOnFailure], a payment that couldn't even be started (the
  /// server refused it, or no connection) does not navigate: unless the
  /// order turns out to be paid already (e.g. the wallet settled it), the
  /// server's reason is returned and the caller keeps the customer where
  /// they can try again. Returns null whenever it navigated.
  static Future<String?> payThenTrack(
    BuildContext context, {
    required String orderId,
    required bool requiresPayment,
    String settledMessage = 'Order confirmed.',
    bool stayOnFailure = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final orders = context.read<OrdersViewModel>();
    String? message = settledMessage;
    var exit = PaymentExit.track;
    if (requiresPayment) {
      String? failure;
      try {
        final result = await pay(context, orderId: orderId);
        message = result.outcome.followUpMessage;
        exit = result.exit;
      } on OrderPaymentException catch (e) {
        failure = e.message;
      } catch (e) {
        failure = _requestFailureMessage(e);
      }
      if (failure != null) {
        if (stayOnFailure) {
          // "Failed" can mean already settled (a wallet covering the whole
          // charge) — only an unpaid order keeps the customer here.
          final check = await orders.checkPayment(orderId);
          if (!check.isPaid) return failure;
          message = settledMessage;
        } else {
          message = '$failure You can retry from the tracking screen.';
        }
      }
    }
    if (!context.mounted) return null;
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
    return null;
  }

  /// The server's own reason when it refused the request, else a generic one.
  static String _requestFailureMessage(Object error) {
    if (error is DioException && error.response != null) {
      return NetworkUtils.handleDioException(error).value.message;
    }
    return 'Payment couldn\'t be started.';
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
