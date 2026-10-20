import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gopady/resources/resources.dart';

void main() {
  test('brand_assets assets test', () {
    expect(File(BrandAssets.gopadyIconGreen).existsSync(), isTrue);
    expect(File(BrandAssets.gopadyIconYellow).existsSync(), isTrue);
    expect(File(BrandAssets.gopadyLogoLight).existsSync(), isTrue);
    expect(File(BrandAssets.gopadyLogoTransparentWhite).existsSync(), isTrue);
  });
}
