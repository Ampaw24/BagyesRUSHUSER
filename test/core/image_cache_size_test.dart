import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/core/utils/image_cache_size.dart';

void main() {
  group('coverDecodeWidth', () {
    test('a small square thumbnail decodes at box size, not source size', () {
      // 60×60 box at 3x → needs 120 logical px of width for a 2:1 photo.
      expect(
        coverDecodeWidth(width: 60, height: 60, pixelRatio: 3),
        360,
      );
    });

    test('a wide box is sized by its width', () {
      expect(
        coverDecodeWidth(width: 360, height: 150, pixelRatio: 2),
        720,
      );
    });

    test('covers wide photos in a tall box without upscaling them', () {
      // Cover fills the HEIGHT with a 3:1 banner → its width overflows the
      // box; decoding at box width alone would stretch it 1.6x.
      final decoded = coverDecodeWidth(
        width: 324,
        height: 168,
        pixelRatio: 1,
        maxAspect: 3,
      )!;
      expect(decoded, greaterThanOrEqualTo(168 * 3));
    });

    test('never decodes smaller than the box needs, for any photo ≤ maxAspect',
        () {
      const width = 120.0, height = 80.0, dpr = 3.0, maxAspect = 2.0;
      final decoded = coverDecodeWidth(
        width: width,
        height: height,
        pixelRatio: dpr,
        maxAspect: maxAspect,
      )!;
      for (final aspect in [0.5, 1.0, 1.5, 2.0]) {
        final decodedHeight = decoded / aspect;
        expect(decoded, greaterThanOrEqualTo(width * dpr), reason: '$aspect');
        expect(decodedHeight, greaterThanOrEqualTo(height * dpr), reason: '$aspect');
      }
    });

    test('unbounded or empty boxes decode normally', () {
      expect(
        coverDecodeWidth(width: double.infinity, height: 100, pixelRatio: 3),
        isNull,
      );
      expect(coverDecodeWidth(width: 0, height: 100, pixelRatio: 3), isNull);
    });
  });

  testWidgets('fullWidthCacheWidth is screen width × pixel ratio, so the card '
      'and the detail hero share one cache entry', (tester) async {
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(390 * 3, 844 * 3);
    addTearDown(tester.view.reset);
    late int fromCard, fromDetail;

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            Builder(builder: (c) {
              fromCard = fullWidthCacheWidth(c);
              return const SizedBox.shrink();
            }),
            Builder(builder: (c) {
              fromDetail = fullWidthCacheWidth(c);
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );

    expect(fromCard, 1170);
    expect(fromDetail, fromCard);
  });
}
