import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gopady/resources/resources.dart';

void main() {
  test('icon_assets assets test', () {
    expect(File(IconAssets.atbanner).existsSync(), isTrue);
    expect(File(IconAssets.mtnbanner).existsSync(), isTrue);
    expect(File(IconAssets.rebrandFilter).existsSync(), isTrue);
    expect(File(IconAssets.telecelIcon).existsSync(), isTrue);
    expect(File(IconAssets.userLogin).existsSync(), isTrue);
    expect(File(IconAssets.vendor).existsSync(), isTrue);
  });
}
