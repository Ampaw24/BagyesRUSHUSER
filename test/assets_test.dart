import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gopady/resources/resources.dart';

void main() {
  test('assets assets test', () {
    expect(File(Assets.dDeliveryBoxParcel).existsSync(), isTrue);
    expect(File(Assets.deliveryMarker).existsSync(), isTrue);
    expect(File(Assets.mapmarker).existsSync(), isTrue);
    expect(File(Assets.pickupMarker).existsSync(), isTrue);
    expect(File(Assets.scooterSearch).existsSync(), isTrue);
    expect(File(Assets.tracking).existsSync(), isTrue);
  });
}
