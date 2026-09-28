import 'package:bagyesrushappusernew/src/consumer_orders/models/delivery_quote.dart';
import 'package:bagyesrushappusernew/src/customer_address/models/customer_address.dart';
import 'package:bagyesrushappusernew/src/payment/model/payment_method.dart';

/// Sentinel distinguishing "leave unchanged" from "set to null" in
/// [CheckoutForm.copyWith] for genuinely-nullable fields.
const _unset = Object();

/// Holds the form inputs the user fills in during checkout.
class CheckoutForm {
  /// Saved address whose id is sent as `customer_address_id`.
  final CustomerAddress? selectedAddress;

  /// Sent as the order's `notes`.
  final String deliveryInstructions;

  /// The customer's chosen saved payment method. Null until the async list
  /// of saved methods has loaded and one has been picked (or auto-selected).
  final PaymentMethod? selectedPaymentMethod;

  /// Quote for a non-default [selectedAddress]. The default address's quote
  /// is embedded in the cart, so this stays null for it.
  final bool isFetchingDeliveryQuote;
  final String? deliveryQuoteError;
  final DeliveryQuote? deliveryQuote;

  /// Sent as the `use_wallet` flag — the backend decides the amount.
  final bool useWallet;

  const CheckoutForm({
    this.selectedAddress,
    this.deliveryInstructions = '',
    this.selectedPaymentMethod,
    this.isFetchingDeliveryQuote = false,
    this.deliveryQuoteError,
    this.deliveryQuote,
    this.useWallet = false,
  });

  /// True when the cart's embedded quote and totals apply to the selected
  /// address (it is the customer's default).
  bool get usesCartQuote => selectedAddress?.isDefault ?? false;

  CheckoutForm copyWith({
    Object? selectedAddress = _unset,
    String? deliveryInstructions,
    PaymentMethod? selectedPaymentMethod,
    bool? isFetchingDeliveryQuote,
    Object? deliveryQuoteError = _unset,
    Object? deliveryQuote = _unset,
    bool? useWallet,
  }) {
    return CheckoutForm(
      selectedAddress: identical(selectedAddress, _unset)
          ? this.selectedAddress
          : selectedAddress as CustomerAddress?,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      isFetchingDeliveryQuote:
          isFetchingDeliveryQuote ?? this.isFetchingDeliveryQuote,
      deliveryQuoteError: identical(deliveryQuoteError, _unset)
          ? this.deliveryQuoteError
          : deliveryQuoteError as String?,
      deliveryQuote: identical(deliveryQuote, _unset)
          ? this.deliveryQuote
          : deliveryQuote as DeliveryQuote?,
      useWallet: useWallet ?? this.useWallet,
    );
  }
}
