import 'dart:io';

import 'package:bagyesrushappusernew/resources/resources.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('icon_assets assets test', () {
    expect(File(IconAssets.courier).existsSync(), isTrue);
    expect(File(IconAssets.documentType).existsSync(), isTrue);
    expect(File(IconAssets.food).existsSync(), isTrue);
    expect(File(IconAssets.grocery).existsSync(), isTrue);
    expect(File(IconAssets.icon10).existsSync(), isTrue);
    expect(File(IconAssets.icon11).existsSync(), isTrue);
    expect(File(IconAssets.icon9).existsSync(), isTrue);
    expect(File(IconAssets.parcelType).existsSync(), isTrue);
    expect(File(IconAssets.wallet).existsSync(), isTrue);
  });
}
