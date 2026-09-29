import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/core/router/app_navigator.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/order_payment_outcome.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/payment_confirmation_dialog.dart';
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
/// in [PaymentWebViewScreen] → `POST customer/orders/:id/verify-payment`.
///
/// Connection-level failures are retried inside the repository; anything
/// that reaches the caller is ambiguous enough (a charge may already have
/// been initiated) that it's surfaced for a manual retry, never retried
/// automatically.
class OrderPaymentLauncher {
  const OrderPaymentLauncher._();

  /// Pays [orderId] with [savedMethod], or the customer's default saved
  /// mobile money method when none is given.
  static Future<OrderPaymentOutcome> pay(
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
    if (!context.mounted) return OrderPaymentOutcome.dismissed;

    final orders = context.read<OrdersViewModel>();
    final payResponse = await orders.payOrder(
      orderId,
      paymentMethod: paymentMethod,
      phone: saved.phoneNumber,
      mobileMoneyProvider: provider.apiValue,
    );
    if (!context.mounted) return OrderPaymentOutcome.dismissed;

    final reference =
        (payResponse['reference'] ?? payResponse['payment_reference'])
            ?.toString();
    final paymentUrl =
        (payResponse['authorization_url'] ??
                payResponse['payment_url'] ??
                payResponse['paymentUrl'])
            ?.toString();
    if (paymentUrl != null && paymentUrl.isNotEmpty) {
      final leftGateway = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(paymentUrl: paymentUrl),
        ),
      );
      if (!context.mounted) return OrderPaymentOutcome.dismissed;
      if (leftGateway != true) {
        return _checkAfterDismissal(context, orders, orderId, reference);
      }
    }

    final outcome = await PaymentConfirmationDialog.show(
      context,
      verification: _verify(orders, orderId, reference),
    );
    if (outcome == OrderPaymentOutcome.processing) {
      orders.markAwaitingPaymentConfirmation(orderId);
    }
    return outcome;
  }

  /// Pays for a just-created order (skipped when nothing is due), then
  /// replaces the checkout flow with tracking so back can't return to — and
  /// resubmit — it. Any follow-up (payment not finished, failed, still
  /// confirming) is shown as a snackbar on the tracking screen.
  static Future<void> payThenTrack(
    BuildContext context, {
    required String orderId,
    required bool requiresPayment,
    PaymentMethod? savedMethod,
    String settledMessage = 'Order confirmed.',
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    String? message = settledMessage;
    if (requiresPayment) {
      try {
        final outcome = await pay(
          context,
          orderId: orderId,
          paymentMethod: 'mobile_money',
          savedMethod: savedMethod,
        );
        message = outcome.followUpMessage;
      } on OrderPaymentException catch (e) {
        message = e.message;
      } catch (_) {
        message = 'Payment failed. You can retry from the tracking screen.';
      }
    }
    if (!context.mounted) return;
    AppNavigator.goToOrderTracking(context, orderId);
    if (message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// The customer is back from the gateway: confirm with the server. A
  /// definitive rejection (422) is surfaced as-is; a connection problem
  /// leaves the charge unknown, so it's treated as still processing rather
  /// than inviting a second payment.
  static Future<bool> _verify(
    OrdersViewModel orders,
    String orderId,
    String? reference,
  ) async {
    try {
      if (reference != null && reference.isNotEmpty) {
        final result = await orders.verifyPayment(
          orderId,
          reference: reference,
        );
        if (result.isFailed) {
          throw const OrderPaymentException(
            'Your payment didn\'t go through. Please try again.',
          );
        }
        return result.isPaid;
      }
      await orders.trackOrder(orderId);
      return orders.orderById(orderId)?.paymentStatus == PaymentStatus.paid;
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw OrderPaymentException(
          NetworkUtils.handleDioException(e).value.message,
        );
      }
      return false;
    }
  }

  /// Closing the gateway before its redirect doesn't prove nothing was paid
  /// (e.g. closed on Paystack's own success screen) — check quietly first so
  /// a completed charge still shows as paid instead of offering "Pay Now".
  static Future<OrderPaymentOutcome> _checkAfterDismissal(
    BuildContext context,
    OrdersViewModel orders,
    String orderId,
    String? reference,
  ) async {
    if (reference == null || reference.isEmpty) {
      return OrderPaymentOutcome.dismissed;
    }
    var isPaid = false;
    try {
      isPaid = (await orders.verifyPayment(
        orderId,
        reference: reference,
      )).isPaid;
    } catch (_) {
      // Unpaid (or unreachable) — the customer simply closed the checkout.
    }
    if (!isPaid) return OrderPaymentOutcome.dismissed;
    if (!context.mounted) return OrderPaymentOutcome.paid;
    return PaymentConfirmationDialog.show(
      context,
      verification: Future.value(true),
    );
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
