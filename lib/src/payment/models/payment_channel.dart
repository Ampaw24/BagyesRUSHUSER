/// Paystack charge channel — only the two methods Paystack itself processes.
/// Cash-on-delivery is handled entirely by the orders feature and never
/// reaches this API.
enum PaymentChannel {
  mobileMoney('mobileMoney'),
  card('card');

  final String apiValue;
  const PaymentChannel(this.apiValue);
}

enum MobileMoneyProvider {
  mtn('mtn'),
  vodafone('vodafone'),
  airtelTigo('airteltigo');

  final String apiValue;
  const MobileMoneyProvider(this.apiValue);
}
