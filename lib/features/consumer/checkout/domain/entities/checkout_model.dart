/// Payment method options available at checkout.
enum PaymentMethod {
  mobileMoney('Mobile Money'),
  card('Visa / Mastercard'),
  cashOnDelivery('Cash on Delivery');

  final String label;
  const PaymentMethod(this.label);

  static PaymentMethod fromLabel(String label) {
    return PaymentMethod.values.firstWhere(
      (m) => m.label == label,
      orElse: () => PaymentMethod.mobileMoney,
    );
  }
}

/// Holds the form inputs the user fills in during checkout.
class CheckoutForm {
  final String deliveryAddress;
  final String deliveryInstructions;
  final PaymentMethod paymentMethod;

  /// Resolved from GPS or the map picker. Null when the user hand-typed the
  /// address instead — [deliveryAddress] is always required, these aren't.
  final double? deliveryLat;
  final double? deliveryLng;

  const CheckoutForm({
    this.deliveryAddress = '',
    this.deliveryInstructions = '',
    this.paymentMethod = PaymentMethod.mobileMoney,
    this.deliveryLat,
    this.deliveryLng,
  });

  CheckoutForm copyWith({
    String? deliveryAddress,
    String? deliveryInstructions,
    PaymentMethod? paymentMethod,
    double? deliveryLat,
    double? deliveryLng,
  }) {
    return CheckoutForm(
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
    );
  }
}
