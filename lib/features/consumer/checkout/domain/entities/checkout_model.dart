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

  const CheckoutForm({
    this.deliveryAddress = '',
    this.deliveryInstructions = '',
    this.paymentMethod = PaymentMethod.mobileMoney,
  });

  CheckoutForm copyWith({
    String? deliveryAddress,
    String? deliveryInstructions,
    PaymentMethod? paymentMethod,
  }) {
    return CheckoutForm(
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
