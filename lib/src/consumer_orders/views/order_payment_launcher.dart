import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/core/router/app_navigator.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/order_payment_outcome.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/order_payment_verification.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/payment_receipt.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/views/payment_receipt_view.dart';
import 'package:bagyesrushappusernew/src/payment/model/payment_method.dart';
import 'package:bagyesrushappusernew/src/payment/model/payout_provider_model.dart';
import 'package:bagyesrushappusernew/src/payment/models/payment_channel.dart';
import 'package:bagyesrushappusernew/src/payment/repository/payment_repository.dart';
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

  /// Pays [orderId] with [savedMethod], or the customer's default saved
  /// mobile money method when none is given. Once the customer is back from
  /// the gateway the payment is checked and shown as a receipt; the result
  /// says how it ended and where the customer asked to go next.
  static Future<OrderPaymentResult> pay(
    BuildContext context, {
    required String orderId,
    required String paymentMethod,
    PaymentMethod? savedMethod,
  }) async {
    if (paymentMethod != 'mobile_money') {
      throw const OrderPaymentException(
        'This payment method isn\'t supported yet. Please contact support.',
      );
    }

    final saved = savedMethod ?? await _defaultSavedMethod();
    final provider = await _resolveMobileMoneyProvider(saved);
    if (provider == null) {
      throw OrderPaymentException(
        'Couldn\'t match "${saved.displayTitle}" to a supported mobile money network.',
      );
    }
    if (!context.mounted) return _dismissed;

    final orders = context.read<OrdersViewModel>();
    final payResponse = await orders.payOrder(
      orderId,
      paymentMethod: paymentMethod,
      phone: saved.phoneNumber,
      mobileMoneyProvider: provider.apiValue,
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
      return pay(
        context,
        orderId: orderId,
        paymentMethod: paymentMethod,
        savedMethod: savedMethod,
      );
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
    PaymentMethod? savedMethod,
    String settledMessage = 'Order confirmed.',
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    String? message = settledMessage;
    var exit = PaymentExit.track;
    if (requiresPayment) {
      try {
        final result = await pay(
          context,
          orderId: orderId,
          paymentMethod: 'mobile_money',
          savedMethod: savedMethod,
        );
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

  static Future<PaymentMethod> _defaultSavedMethod() async {
    final methods = await sl<PaymentRepository>()
        .getCustomerPaymentMethods()
        .then(
          (result) => result.fold(
            (failure) => throw OrderPaymentException(failure.message),
            (methods) => methods,
          ),
        );
    if (methods.isEmpty) {
      throw const OrderPaymentException(
        'No saved mobile money number. Add one under Payment Methods first.',
      );
    }
    return methods.firstWhere((m) => m.isDefault, orElse: () => methods.first);
  }

  /// Matches free text (a provider's slug/name, or a saved method's label
  /// like "MTN 0987") against the gateway's [MobileMoneyProvider] enum.
  static MobileMoneyProvider? _matchMobileMoneyProvider(String text) {
    final needle = text.toLowerCase();
    for (final p in MobileMoneyProvider.values) {
      if (needle.contains(p.apiValue)) return p;
    }
    if (needle.contains('airtel') || needle.contains('tigo')) {
      return MobileMoneyProvider.airtelTigo;
    }
    return null;
  }

  /// The customer payment-methods list doesn't always embed the full
  /// `payout_provider` object (only `payout_provider_id`), so this tries the
  /// embedded provider, then the method's own label, then — only if neither
  /// matched — the payout provider catalog.
  static Future<MobileMoneyProvider?> _resolveMobileMoneyProvider(
    PaymentMethod saved,
  ) async {
    final provider = saved.provider;
    if (provider != null) {
      final match = _matchMobileMoneyProvider(
        '${provider.slug} ${provider.shortName} ${provider.name}',
      );
      if (match != null) return match;
    }

    final byLabel = _matchMobileMoneyProvider(saved.label ?? '');
    if (byLabel != null) return byLabel;

    if (saved.payoutProviderId == 0) return null;
    final providers = await sl<PaymentRepository>().getPayoutProviders().then(
      (result) =>
          result.fold((_) => const <PayoutProviderModel>[], (list) => list),
    );
    for (final p in providers) {
      if (p.id == saved.payoutProviderId) {
        return _matchMobileMoneyProvider('${p.slug} ${p.shortName} ${p.name}');
      }
    }
    return null;
  }
}
