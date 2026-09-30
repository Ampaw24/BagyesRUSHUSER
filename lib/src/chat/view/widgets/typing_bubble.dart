import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'chat_dimensions.dart';

/// Peer-side bubble with three bouncing dots, shown while the other
/// participant is typing.
class TypingBubble extends StatefulWidget {
  const TypingBubble({super.key});

  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  static const _dotCount = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = chatScaleWidth(context);
    final dot = w * 0.016;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.032),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(w * 0.045),
          topRight: Radius.circular(w * 0.045),
          bottomRight: Radius.circular(w * 0.045),
          bottomLeft: Radius.circular(w * 0.012),
        ),
        border: Border.all(color: AppColors.divider),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _dotCount; i++) ...[
              if (i > 0) SizedBox(width: dot * 0.7),
              _Dot(size: dot, phase: _phaseFor(i)),
            ],
          ],
        ),
      ),
    );
  }

  /// 0→1→0 wave, each dot a third of a cycle behind the previous one.
  double _phaseFor(int index) {
    final t = (_controller.value - index / _dotCount) % 1.0;
    return math.sin(t * math.pi).clamp(0.0, 1.0);
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.phase});

  final double size;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -size * 0.6 * phase),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Color.lerp(AppColors.textHint, AppColors.primary, phase),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
