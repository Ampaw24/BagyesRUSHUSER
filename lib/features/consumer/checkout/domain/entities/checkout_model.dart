import 'package:bagyesrushappusernew/src/payment/model/payment_method.dart';

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

  const CheckoutForm({
    this.deliveryAddress = '',
    this.deliveryInstructions = '',
    this.selectedPaymentMethod,
    this.deliveryLat,
    this.deliveryLng,
  });

  CheckoutForm copyWith({
    String? deliveryAddress,
    String? deliveryInstructions,
    PaymentMethod? selectedPaymentMethod,
    double? deliveryLat,
    double? deliveryLng,
  }) {
    return CheckoutForm(
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
    );
  }
}
