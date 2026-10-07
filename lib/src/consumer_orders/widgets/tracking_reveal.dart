import 'package:flutter/material.dart';

/// Fades and slides [child] up into place once, after [delay]. Stagger a
/// column of these by giving each a larger delay. Shows instantly when the
/// device has animations turned off.
///
/// Driven by one controller with the delay baked into an [Interval], so no
/// timers are involved.
class TrackingReveal extends StatefulWidget {
  const TrackingReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.rise = 18,
  });

  final Widget child;
  final Duration delay;

  /// How far (logical px) the child travels up while fading in.
  final double rise;

  /// Delay for the [index]th item of a staggered list.
  static Duration stagger(int index, {int stepMs = 80}) =>
      Duration(milliseconds: index * stepMs);

  @override
  State<TrackingReveal> createState() => _TrackingRevealState();
}

class _TrackingRevealState extends State<TrackingReveal>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 480);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration + widget.delay,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMilliseconds / (_duration + widget.delay).inMilliseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _curve.value) * widget.rise),
          child: child,
        ),
      ),
    );
  }
}
