import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';

enum _StepState { done, current, upcoming }

/// Horizontal order-progress stepper: completed steps are green checks, the
/// step in progress pulses in the brand colour, upcoming steps are muted.
class TrackingProgressStepper extends StatelessWidget {
  const TrackingProgressStepper({
    super.key,
    required this.status,
    required this.isParcel,
  });

  final OrderStatus status;
  final bool isParcel;

  static const _foodSteps = [
    (OrderStatus.accepted, Icons.receipt_long_rounded, 'Order confirmed'),
    (OrderStatus.preparing, Icons.restaurant_rounded, 'Preparing food'),
    (OrderStatus.pickedUp, Icons.shopping_bag_rounded, 'Picked up'),
    (OrderStatus.onTheWay, Icons.delivery_dining_rounded, 'On the way'),
  ];

  static const _parcelSteps = [
    (OrderStatus.pending, Icons.receipt_long_rounded, 'Request placed'),
    (OrderStatus.accepted, Icons.person_pin_circle_rounded, 'Rider assigned'),
    (OrderStatus.pickedUp, Icons.inventory_2_rounded, 'Picked up'),
    (OrderStatus.onTheWay, Icons.delivery_dining_rounded, 'On the way'),
  ];

  @override
  Widget build(BuildContext context) {
    final steps = isParcel ? _parcelSteps : _foodSteps;
    // Furthest step reached — tolerates statuses a flow skips (e.g. a
    // parcel reported as `ready`).
    final reached = switch (status) {
      OrderStatus.cancelled => -1,
      OrderStatus.delivered => steps.length,
      _ => steps.lastIndexWhere((s) => s.$1.index <= status.index),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: _Step(
              icon: steps[i].$2,
              label: steps[i].$3,
              state: i < reached
                  ? _StepState.done
                  : i == reached
                      ? _StepState.current
                      : _StepState.upcoming,
              leftComplete: i == 0 ? null : i <= reached,
              rightComplete: i == steps.length - 1 ? null : i < reached,
            ),
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.label,
    required this.state,
    required this.leftComplete,
    required this.rightComplete,
  });

  final IconData icon;
  final String label;
  final _StepState state;

  /// Connector colour on each side; null draws no connector (row ends).
  final bool? leftComplete;
  final bool? rightComplete;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final dotSize = w * 0.09;
    final labelColor = switch (state) {
      _StepState.done => AppColors.success,
      _StepState.current => AppColors.primary,
      _StepState.upcoming => AppColors.textHint,
    };

    return Column(
      children: [
        SizedBox(
          height: dotSize,
          child: Row(
            children: [
              Expanded(child: _Connector(complete: leftComplete)),
              _StepDot(icon: icon, state: state, size: dotSize),
              Expanded(child: _Connector(complete: rightComplete)),
            ],
          ),
        ),
        SizedBox(height: w * 0.02),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.005),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: w * 0.029,
              height: 1.25,
              fontWeight: state == _StepState.upcoming
                  ? FontWeight.w400
                  : FontWeight.w600,
              color: labelColor,
            ),
            child: Text(label, textAlign: TextAlign.center, maxLines: 2),
          ),
        ),
      ],
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.complete});

  final bool? complete;

  @override
  Widget build(BuildContext context) {
    final complete = this.complete;
    if (complete == null) return const SizedBox.shrink();
    final w = MediaQuery.sizeOf(context).width;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: w * 0.005,
      margin: EdgeInsets.symmetric(horizontal: w * 0.012),
      decoration: BoxDecoration(
        color: complete ? AppColors.success : AppColors.border,
        borderRadius: BorderRadius.circular(w * 0.005),
      ),
    );
  }
}

/// Step circle. The current step gets an expanding, fading pulse ring —
/// drawn with a transform so it never affects layout.
class _StepDot extends StatefulWidget {
  const _StepDot({required this.icon, required this.state, required this.size});

  final IconData icon;
  final _StepState state;
  final double size;

  @override
  State<_StepDot> createState() => _StepDotState();
}

class _StepDotState extends State<_StepDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  bool get _isCurrent => widget.state == _StepState.current;

  @override
  void initState() {
    super.initState();
    if (_isCurrent) _pulse.repeat();
  }

  @override
  void didUpdateWidget(covariant _StepDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isCurrent && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!_isCurrent && _pulse.isAnimating) {
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final (fill, border, iconColor) = switch (widget.state) {
      _StepState.done => (AppColors.success, AppColors.success, Colors.white),
      _StepState.current => (
          AppColors.primary.withValues(alpha: 0.1),
          AppColors.primary,
          AppColors.primary,
        ),
      _StepState.upcoming => (
          AppColors.surfaceVariant,
          AppColors.border,
          AppColors.textHint,
        ),
    };

    final dot = AnimatedContainer(
      key: const ValueKey('dot'),
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: _isCurrent ? 1.5 : 1),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          widget.state == _StepState.done ? Icons.check_rounded : widget.icon,
          key: ValueKey(widget.state == _StepState.done),
          size: size * 0.5,
          color: iconColor,
        ),
      ),
    );

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (_isCurrent)
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) => Transform.scale(
              scale: 1 + 0.55 * _pulse.value,
              child: Opacity(opacity: 1 - _pulse.value, child: child),
            ),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
          ),
        dot,
      ],
    );
  }
}
