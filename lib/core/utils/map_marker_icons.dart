import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../constant/app_theme.dart';

/// A filled circular badge carrying [number], [size] logical px across.
///
/// Rendered at [devicePixelRatio] so it stays crisp, and tagged with the same
/// ratio so the map displays it at exactly [size] on every device. Returns
/// null if the image can't be encoded.
Future<BitmapDescriptor?> numberedMarkerIcon(
  int number, {
  required double size,
  required double devicePixelRatio,
}) async {
  final pixels = (size * devicePixelRatio).ceilToDouble();
  final center = Offset(pixels / 2, pixels / 2);
  final label = '$number';

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawCircle(center, pixels / 2, Paint()..color = Colors.white);
  canvas.drawCircle(
    center,
    pixels / 2 - pixels * 0.08,
    Paint()..color = AppColors.primary,
  );

  final text = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        color: Colors.white,
        fontSize: pixels * (label.length > 1 ? 0.4 : 0.52),
        fontWeight: FontWeight.w800,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  text.dispose();

  final image = await recorder.endRecording().toImage(
        pixels.toInt(),
        pixels.toInt(),
      );
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return null;
    return BitmapDescriptor.bytes(
      data.buffer.asUint8List(),
      imagePixelRatio: devicePixelRatio,
    );
  } finally {
    image.dispose();
  }
}

/// Marker anchors that keep markers sharing a position (to ~1 m) readable.
///
/// The first marker at a position is centred on it; each further one is
/// shifted sideways in screen space, so badges sit side by side while every
/// marker keeps its true coordinates.
List<Offset> stackedMarkerAnchors(List<LatLng> positions) {
  const sidewaysShift = 0.7;
  final seenAt = <(int, int), int>{};
  final anchors = <Offset>[];
  for (final p in positions) {
    final key = ((p.latitude * 1e5).round(), (p.longitude * 1e5).round());
    final index = seenAt.update(key, (n) => n + 1, ifAbsent: () => 0);
    anchors.add(Offset(0.5 - sidewaysShift * index, 0.5));
  }
  return anchors;
}
