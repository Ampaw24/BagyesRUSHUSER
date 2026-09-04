import 'package:bagyesrushappusernew/src/payment/model/payment_method.dart';

/// Sentinel distinguishing "leave unchanged" from "set to null" in
/// [CheckoutForm.copyWith] for genuinely-nullable fields.
const _unset = Object();

/// Holds the form inputs the user fills in during checkout.
class CheckoutForm {
  final String deliveryAddress;
  final String deliveryInstructions;

  /// The customer's chosen saved payment method. Null until the async list
  /// of saved methods has loaded and one has been picked (or auto-selected).
  final PaymentMethod? selectedPaymentMethod;

  /// Resolved from GPS or the map picker. Null when the user hand-typed the
  /// address instead — [deliveryAddress] is always required, these aren't.
  final double? deliveryLat;
  final double? deliveryLng;

  /// Live delivery-fee quote state (`GET /customer/delivery-quote`) — a
  /// display-only preview; the amount actually charged is always whatever
  /// the backend computes when the order is created, same as `cart.total`
  /// already isn't authoritative until then.
  final bool isFetchingDeliveryQuote;
  final String? deliveryQuoteError;
  final double? deliveryQuoteFee;
  final String? deliveryQuoteCurrency;

  /// `service_fee` from the same delivery-quote response, when present.
  final double? deliveryQuoteServiceFee;

  const CheckoutForm({
    this.deliveryAddress = '',
    this.deliveryInstructions = '',
    this.selectedPaymentMethod,
    this.deliveryLat,
    this.deliveryLng,
    this.isFetchingDeliveryQuote = false,
    this.deliveryQuoteError,
    this.deliveryQuoteFee,
    this.deliveryQuoteCurrency,
    this.deliveryQuoteServiceFee,
  });

  CheckoutForm copyWith({
    String? deliveryAddress,
    String? deliveryInstructions,
    PaymentMethod? selectedPaymentMethod,
    double? deliveryLat,
    double? deliveryLng,
    bool? isFetchingDeliveryQuote,
    Object? deliveryQuoteError = _unset,
    Object? deliveryQuoteFee = _unset,
    Object? deliveryQuoteCurrency = _unset,
    Object? deliveryQuoteServiceFee = _unset,
  }) {
    return CheckoutForm(
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
      isFetchingDeliveryQuote:
          isFetchingDeliveryQuote ?? this.isFetchingDeliveryQuote,
      deliveryQuoteError: identical(deliveryQuoteError, _unset)
          ? this.deliveryQuoteError
          : deliveryQuoteError as String?,
      deliveryQuoteFee: identical(deliveryQuoteFee, _unset)
          ? this.deliveryQuoteFee
          : deliveryQuoteFee as double?,
      deliveryQuoteCurrency: identical(deliveryQuoteCurrency, _unset)
          ? this.deliveryQuoteCurrency
          : deliveryQuoteCurrency as String?,
      deliveryQuoteServiceFee: identical(deliveryQuoteServiceFee, _unset)
          ? this.deliveryQuoteServiceFee
          : deliveryQuoteServiceFee as double?,
    );
  }
}
