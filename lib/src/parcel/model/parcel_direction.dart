/// Which way a parcel travels relative to the customer.
///
/// `send`: the customer is at pickup and hands the package over.
/// `receive`: a rider collects from someone else (the pickup contact) and
/// brings it to the customer's single drop-off.
enum ParcelDirection {
  send('send'),
  receive('receive');

  const ParcelDirection(this.apiValue);

  final String apiValue;

  bool get isReceive => this == ParcelDirection.receive;

  static ParcelDirection fromApi(String? value) => ParcelDirection.values
      .firstWhere((d) => d.apiValue == value, orElse: () => ParcelDirection.send);
}
