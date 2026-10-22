import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the system share sheet for [text].
///
/// iPad presents the sheet as a popover and `share_plus` throws without an
/// anchor, so the origin is taken from [context]'s render box.
Future<void> shareText(BuildContext context, String text) {
  final box = context.findRenderObject() as RenderBox?;
  final origin = box != null && box.hasSize
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
  return SharePlus.instance.share(
    ShareParams(text: text, sharePositionOrigin: origin),
  );
}
