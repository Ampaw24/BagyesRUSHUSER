import 'dart:io';

import 'package:bagyesrushappusernew/resources/resources.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('grocery_assets assets test', () {
    expect(File(GroceryAssets.grocery1).existsSync(), isTrue);
    expect(File(GroceryAssets.grocery2).existsSync(), isTrue);
    expect(File(GroceryAssets.grocery3).existsSync(), isTrue);
    expect(File(GroceryAssets.grocery4).existsSync(), isTrue);
  });
}
