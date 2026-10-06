import 'package:bagyesrushappusernew/src/consumer_orders/models/delivery_quote.dart';
import 'package:bagyesrushappusernew/src/customer_address/models/customer_address.dart';
import 'package:bagyesrushappusernew/src/customer_address/models/delivery_location.dart';

/// Sentinel distinguishing "leave unchanged" from "set to null" in
/// [CheckoutForm.copyWith] for genuinely-nullable fields.
const _unset = Object();

/// Holds the form inputs the user fills in during checkout.
class CheckoutForm {
  /// Saved address whose id is sent as `customer_address_id`. Mutually
  /// exclusive with [pickedLocation].
  final CustomerAddress? selectedAddress;

  /// Unsaved GPS / map-picked drop-off, sent as coordinates instead of an
  /// address id. Mutually exclusive with [selectedAddress].
  final DeliveryLocation? pickedLocation;

  /// Sent as the order's `notes`.
  final String deliveryInstructions;

  /// Quote for a non-default [selectedAddress] or a [pickedLocation]. The
  /// default address's quote is embedded in the cart, so this stays null
  /// for it.
  final bool isFetchingDeliveryQuote;
  final String? deliveryQuoteError;
  final DeliveryQuote? deliveryQuote;

  /// Sent as the `use_wallet` flag — the backend decides the amount.
  final bool useWallet;

  const CheckoutForm({
    this.selectedAddress,
    this.pickedLocation,
    this.deliveryInstructions = '',
    this.isFetchingDeliveryQuote = false,
    this.deliveryQuoteError,
    this.deliveryQuote,
    this.useWallet = false,
  });

  /// True when the cart's embedded quote and totals apply to the selected
  /// address (it is the customer's default).
  bool get usesCartQuote => selectedAddress?.isDefault ?? false;

  bool get hasDestination => selectedAddress != null || pickedLocation != null;

  CheckoutForm copyWith({
    Object? selectedAddress = _unset,
    Object? pickedLocation = _unset,
    String? deliveryInstructions,
    bool? isFetchingDeliveryQuote,
    Object? deliveryQuoteError = _unset,
    Object? deliveryQuote = _unset,
    bool? useWallet,
  }) {
    return CheckoutForm(
      selectedAddress: identical(selectedAddress, _unset)
          ? this.selectedAddress
          : selectedAddress as CustomerAddress?,
      pickedLocation: identical(pickedLocation, _unset)
          ? this.pickedLocation
          : pickedLocation as DeliveryLocation?,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
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
