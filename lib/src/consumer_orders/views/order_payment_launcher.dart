import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/payment/model/payment_method.dart';
import 'package:bagyesrushappusernew/src/payment/model/payout_provider_model.dart';
import 'package:bagyesrushappusernew/src/payment/models/payment_channel.dart';
import 'package:bagyesrushappusernew/src/payment/repository/payment_repository.dart';
import 'package:bagyesrushappusernew/src/payment/views/screens/payment_webview_screen.dart';

/// An expected, already user-worded payment failure — callers show
/// [message] as-is instead of a generic error.
class OrderPaymentException implements Exception {
  final String message;
  const OrderPaymentException(this.message);
}

enum OrderPaymentOutcome {
  /// The charge was submitted and verified (or the order refreshed when the
  /// gateway returned no reference to verify against).
  completed,

  /// The customer closed the Paystack checkout before it redirected.
  dismissed,
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

    final paymentUrl = (payResponse['authorization_url'] ??
            payResponse['payment_url'] ??
            payResponse['paymentUrl'])
        ?.toString();
    if (paymentUrl != null && paymentUrl.isNotEmpty) {
      final leftGateway = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(paymentUrl: paymentUrl),
        ),
      );
      if (leftGateway != true) return OrderPaymentOutcome.dismissed;
    }

    final reference =
        (payResponse['reference'] ?? payResponse['payment_reference'])
            ?.toString();
    if (reference != null && reference.isNotEmpty) {
      await orders.verifyPayment(orderId, reference: reference);
    } else {
      await orders.trackOrder(orderId);
    }
    return OrderPaymentOutcome.completed;
  }

  static Future<PaymentMethod> _defaultSavedMethod() async {
    final methods = await sl<PaymentRepository>().getCustomerPaymentMethods().then(
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
