import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gopady/resources/resources.dart';

void main() {
  test('lottie_assets assets test', () {
    expect(File(LottieAssets.error).existsSync(), isTrue);
    expect(File(LottieAssets.info).existsSync(), isTrue);
    expect(File(LottieAssets.processing).existsSync(), isTrue);
    expect(File(LottieAssets.searching).existsSync(), isTrue);
    expect(File(LottieAssets.success).existsSync(), isTrue);
    expect(File(LottieAssets.warning).existsSync(), isTrue);
  });
}
