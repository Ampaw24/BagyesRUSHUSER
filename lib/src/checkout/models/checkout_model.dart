import 'package:bagyesrushappusernew/src/consumer_orders/models/promo_code_result.dart';
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

  /// `id` off the same delivery-quote response — passed as the optional
  /// `delivery_quote_id` when validating a promo code, so the backend can
  /// price the discount against the same quote the screen is showing.
  final int? deliveryQuoteId;

  /// Promo-code apply/remove state — orthogonal to the delivery-quote
  /// fields above but follows the same "live on the form, mirror
  /// `fetchDeliveryQuote`" shape rather than a separate ViewModel, since it
  /// only ever mutates checkout's own totals display.
  final bool isApplyingPromo;
  final String? promoError;
  final PromoCodeResult? appliedPromo;

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
    this.deliveryQuoteId,
    this.isApplyingPromo = false,
    this.promoError,
    this.appliedPromo,
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
    Object? deliveryQuoteId = _unset,
    bool? isApplyingPromo,
    Object? promoError = _unset,
    Object? appliedPromo = _unset,
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
      deliveryQuoteId: identical(deliveryQuoteId, _unset)
          ? this.deliveryQuoteId
          : deliveryQuoteId as int?,
      isApplyingPromo: isApplyingPromo ?? this.isApplyingPromo,
      promoError: identical(promoError, _unset)
          ? this.promoError
          : promoError as String?,
      appliedPromo: identical(appliedPromo, _unset)
          ? this.appliedPromo
          : appliedPromo as PromoCodeResult?,
    );
  }
}
