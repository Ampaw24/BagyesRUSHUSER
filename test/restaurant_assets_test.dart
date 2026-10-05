import 'dart:io';

import 'package:bagyesrushappusernew/resources/resources.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restaurant_assets assets test', () {
    expect(File(RestaurantAssets.X720ParcelDeliveryCopy).existsSync(), isTrue);
    expect(File(RestaurantAssets.X720StudentsCopy).existsSync(), isTrue);
    expect(File(RestaurantAssets.foodbanner).existsSync(), isTrue);
    expect(File(RestaurantAssets.restaurant1).existsSync(), isTrue);
    expect(File(RestaurantAssets.restaurant2).existsSync(), isTrue);
    expect(File(RestaurantAssets.restaurant3).existsSync(), isTrue);
    expect(File(RestaurantAssets.restaurant4).existsSync(), isTrue);
    expect(File(RestaurantAssets.restaurant5).existsSync(), isTrue);
  });
}
