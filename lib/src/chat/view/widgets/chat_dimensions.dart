import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Widest width the chat UI scales from. Beyond it (tablets, landscape,
/// split-screen on large devices) type and bubbles stay phone-sized instead
/// of growing with the screen.
const double _maxChatScaleWidth = 480;

/// The width every chat widget derives its sizes from.
double chatScaleWidth(BuildContext context) =>
    math.min(MediaQuery.sizeOf(context).width, _maxChatScaleWidth);
