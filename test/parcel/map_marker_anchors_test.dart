import 'package:bagyesrushappusernew/core/utils/map_marker_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  const center = Offset(0.5, 0.5);
  const accra = LatLng(5.6037, -0.1870);
  const kumasi = LatLng(6.6885, -1.6244);

  group('stackedMarkerAnchors', () {
    test('returns nothing for no positions', () {
      expect(stackedMarkerAnchors(const []), isEmpty);
    });

    test('centres every marker when all positions differ', () {
      final anchors = stackedMarkerAnchors(const [accra, kumasi]);
      expect(anchors, [center, center]);
    });

    test('fans out markers that share a position', () {
      final anchors = stackedMarkerAnchors(const [accra, accra, accra]);
      expect(anchors.first, center);
      expect(anchors.toSet(), hasLength(3));
    });

    test('only shifts the repeats, not other positions', () {
      final anchors = stackedMarkerAnchors(const [accra, kumasi, accra]);
      expect(anchors[0], center);
      expect(anchors[1], center);
      expect(anchors[2], isNot(center));
    });

    test('treats positions within ~1 m as the same spot', () {
      final anchors = stackedMarkerAnchors(const [
        LatLng(5.603700, -0.187000),
        LatLng(5.603702, -0.187001),
      ]);
      expect(anchors[1], isNot(anchors[0]));
    });
  });
}
