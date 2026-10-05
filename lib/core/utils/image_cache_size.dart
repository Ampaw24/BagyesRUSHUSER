import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Decode width for a `BoxFit.cover` network image shown in a [width] ×
/// [height] box, so a large source photo isn't decoded at full resolution
/// just to fill a small box. Null (decode normally) for unbounded boxes.
///
/// Cover scales the image until BOTH box dimensions are filled, so a photo
/// wider than the box overflows it sideways and needs more decoded width
/// than the box has — [maxAspect] (the widest photo expected, width ÷
/// height) accounts for that, so nothing is ever stretched blurry.
/// Sources smaller than the result are never upscaled.
int? coverCacheWidth(
  BuildContext context, {
  required double width,
  required double height,
  double maxAspect = 2,
}) => coverDecodeWidth(
  width: width,
  height: height,
  pixelRatio: MediaQuery.devicePixelRatioOf(context),
  maxAspect: maxAspect,
);

@visibleForTesting
int? coverDecodeWidth({
  required double width,
  required double height,
  required double pixelRatio,
  double maxAspect = 2,
}) {
  if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
    return null;
  }
  return (math.max(width, height * maxAspect) * pixelRatio).ceil();
}

/// One decode width for every cover image of the same restaurant (cards,
/// the list tile, the detail screen's hero): the full screen width fills any
/// of those boxes, and identical sizes share a single image-cache entry, so
/// the card → detail `Hero` transition never reloads the picture.
int fullWidthCacheWidth(BuildContext context) =>
    (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context))
        .ceil();
