import 'dart:io';

import 'package:bagyesrushappusernew/resources/resources.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assets assets test', () {
    expect(File(Assets.bagyesLogo).existsSync(), isTrue);
    expect(File(Assets.banner).existsSync(), isTrue);
    expect(File(Assets.coin).existsSync(), isTrue);
    expect(File(Assets.customize).existsSync(), isTrue);
    expect(File(Assets.deliveryBoy).existsSync(), isTrue);
    expect(File(Assets.deliveryMarker).existsSync(), isTrue);
    expect(File(Assets.icon).existsSync(), isTrue);
    expect(File(Assets.pickupMarker).existsSync(), isTrue);
    expect(File(Assets.user).existsSync(), isTrue);
  });
}
