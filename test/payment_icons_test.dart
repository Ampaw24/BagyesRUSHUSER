import 'dart:io';

import 'package:bagyesrushappusernew/resources/resources.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('payment_icons assets test', () {
    expect(File(PaymentIcons.amazonPay).existsSync(), isTrue);
    expect(File(PaymentIcons.card).existsSync(), isTrue);
    expect(File(PaymentIcons.cashOnDelivery).existsSync(), isTrue);
    expect(File(PaymentIcons.paypal).existsSync(), isTrue);
    expect(File(PaymentIcons.skrill).existsSync(), isTrue);
  });
}
