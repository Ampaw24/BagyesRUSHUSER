import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'tracking_card.dart';
import 'tracking_reveal.dart';

enum _MilestoneState {
  done,
  current,
  upcoming,

  /// The request ended here without being fulfilled (cancelled / declined).
  failed,

  /// Money went back to the customer.
  refunded,
}

class _Milestone {
  const _Milestone({
    required this.icon,
    required this.title,
    required this.state,
    this.text,
    this.time,
  });

  final IconData icon;
  final String title;
  final _MilestoneState state;

  /// What happened / is happening; null for upcoming steps.
  final String? text;
  final DateTime? time;
}

/// Courier-style vertical timeline for parcel deliveries, driven by the
/// backend's parcel lifecycle:
///
/// `pending_payment → pending → accepted → out_for_delivery → delivered`,
/// with `cancelled` / `rejected` possible along the way and `refunded`
/// after delivery, cancellation or rejection. There is no separate
/// "picked up" status — pickup is described inside the rider's steps.
class ParcelTrackingTimeline extends StatelessWidget {
  const ParcelTrackingTimeline({super.key, required this.order});

  final ConsumerOrder order;

  // Furthest step of the four-step path.
  static const _placed = 0, _assigned = 1, _outForDelivery = 2, _delivered = 3;

  List<_Milestone> _milestones() {
    final status = order.status;
    final times = order.statusTimes;
    final ended =
        status.isCancelledOrDeclined || status == OrderStatus.refunded;

    final int reached;
    if (ended) {
      // A closed order stopped somewhere along the path; the timestamps (or
      // an assigned rider) tell us where.
      reached = times.containsKey(OrderStatus.delivered)
          ? _delivered
          : times.containsKey(OrderStatus.onTheWay)
          ? _outForDelivery
          : (times.containsKey(OrderStatus.accepted) ||
                order.driverName != null)
          ? _assigned
          : _placed;
    } else {
      reached = switch (status) {
        OrderStatus.delivered => _delivered,
        // `picked_up` isn't a parcel status, but if it ever arrives it
        // means the rider has the package.
        OrderStatus.onTheWay || OrderStatus.pickedUp => _outForDelivery,
        OrderStatus.pending => _placed,
        _ => _assigned,
      };
    }

    _MilestoneState stateOf(int i) {
      if (i < reached) return _MilestoneState.done;
      if (i > reached) return _MilestoneState.upcoming;
      // The furthest step is "done" once the order is closed or delivered.
      return ended || status == OrderStatus.delivered
          ? _MilestoneState.done
          : _MilestoneState.current;
    }

    final rider = order.driverName?.trim();
    final riderName = rider == null || rider.isEmpty ? 'Your rider' : rider;
    final pickupFrom = _firstNonEmpty([
      order.isReceiveParcel ? order.pickupContactName : null,
      order.pickupAddress,
    ]);
    final stops = order.stops;
    final dropOff = stops.length > 1
        ? '${stops.length} drop-offs'
        : _firstNonEmpty([
            stops.isEmpty ? null : stops.first.recipientName,
            stops.isEmpty ? null : stops.first.address,
            order.deliveryAddress,
          ]);
    final recipient = _firstNonEmpty([
      stops.length == 1 ? stops.first.recipientName : null,
    ]);

    final path = [
      _Milestone(
        icon: Icons.receipt_long_rounded,
        title: 'Request placed',
        state: stateOf(_placed),
        text: stateOf(_placed) == _MilestoneState.current
            ? (order.needsPayment
                  ? 'Complete payment to start matching a rider'
                  : 'Matching you with a nearby rider…')
            : 'We received your delivery request',
        time: times[OrderStatus.pending] ?? order.placedAt,
      ),
      _Milestone(
        icon: Icons.two_wheeler_rounded,
        title: 'Rider assigned',
        state: stateOf(_assigned),
        text: stateOf(_assigned) == _MilestoneState.current
            ? (pickupFrom == null
                  ? '$riderName is heading to the pickup point'
                  : '$riderName is heading to $pickupFrom')
            : '$riderName accepted your request',
        time: times[OrderStatus.accepted],
      ),
      _Milestone(
        icon: Icons.route_rounded,
        title: 'Out for delivery',
        state: stateOf(_outForDelivery),
        text: stateOf(_outForDelivery) == _MilestoneState.current
            ? (dropOff == null
                  ? 'Package collected — on the way to the drop-off'
                  : 'Package collected — on the way to $dropOff')
            : (pickupFrom == null
                  ? 'Package collected and on its way'
                  : 'Collected from $pickupFrom'),
        time:
            order.collection?.verifiedAt?.toLocal() ??
            times[OrderStatus.onTheWay],
      ),
      _Milestone(
        icon: Icons.task_alt_rounded,
        title: 'Delivered',
        state: stateOf(_delivered),
        text: recipient == null
            ? 'Package handed over'
            : 'Handed over to $recipient',
        time: times[OrderStatus.delivered],
      ),
    ];

    // Only show the steps the order actually got to, then how it ended.
    final trail = ended ? path.sublist(0, reached + 1) : path;
    final tail = <_Milestone>[
      if (status.isCancelledOrDeclined ||
          times.containsKey(OrderStatus.cancelled) ||
          times.containsKey(OrderStatus.rejected))
        _closedStep(status),
      if (status == OrderStatus.refunded)
        _Milestone(
          icon: Icons.currency_exchange_rounded,
          title: 'Refunded',
          state: _MilestoneState.refunded,
          text: 'Your payment has been returned',
          time: times[OrderStatus.refunded],
        ),
    ];
    return [...trail, ...tail];
  }

  /// The red "it stopped here" step. For a refunded order, the timestamps
  /// say whether it was declined or cancelled before the money came back.
  _Milestone _closedStep(OrderStatus status) {
    final times = order.statusTimes;
    final declined =
        status == OrderStatus.rejected ||
        (status == OrderStatus.refunded &&
            times.containsKey(OrderStatus.rejected));
    final at = declined
        ? times[OrderStatus.rejected]
        : times[OrderStatus.cancelled];
    return _Milestone(
      icon: declined ? Icons.block_rounded : Icons.close_rounded,
      title: declined ? 'Request declined' : 'Cancelled',
      state: _MilestoneState.failed,
      text: declined
          ? "We couldn't find a rider. Any payment will be refunded."
          : 'This delivery was cancelled',
      time: at,
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final milestones = _milestones();
    final trackingNumber = order.trackingNumber?.trim() ?? '';

    return TrackingCard(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.045, w * 0.05, w * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Delivery progress',
                  style: TextStyle(
                    fontSize: w * 0.042,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trackingNumber.isNotEmpty)
                _TrackingNumberChip(value: trackingNumber),
            ],
          ),
          SizedBox(height: w * 0.04),
          for (var i = 0; i < milestones.length; i++)
            _MilestoneRow(
              // Position-keyed so a step that appears later (a new status
              // arriving live) animates in without replaying the others.
              key: ValueKey('milestone-$i'),
              index: i,
              milestone: milestones[i],
              isLast: i == milestones.length - 1,
              nextState: i + 1 < milestones.length
                  ? milestones[i + 1].state
                  : null,
            ),
        ],
      ),
    );
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      final t = v?.trim();
      if (t != null && t.isNotEmpty) return t;
    }
    return null;
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    super.key,
    required this.index,
    required this.milestone,
    required this.isLast,
    required this.nextState,
  });

  final int index;
  final _Milestone milestone;
  final bool isLast;

  /// State of the row below, which colours the connector leading to it.
  final _MilestoneState? nextState;

  Color get _connectorColor => switch (nextState) {
    _MilestoneState.done || _MilestoneState.current => AppColors.success,
    _MilestoneState.failed => AppColors.error.withValues(alpha: 0.5),
    _MilestoneState.refunded => AppColors.warning.withValues(alpha: 0.6),
    _ => AppColors.border,
  };

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final dot = w * 0.075;
    final state = milestone.state;
    final isUpcoming = state == _MilestoneState.upcoming;
    final titleColor = switch (state) {
      _MilestoneState.upcoming => AppColors.textHint,
      _MilestoneState.current => AppColors.primary,
      _MilestoneState.failed => AppColors.error,
      _MilestoneState.refunded => AppColors.warning,
      _MilestoneState.done => AppColors.textPrimary,
    };
    final time = milestone.time;
    final text = milestone.text;

    return TrackingReveal(
      delay: TrackingReveal.stagger(index, stepMs: 110),
      rise: 12,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: dot,
              child: Column(
                children: [
                  _MilestoneDot(icon: milestone.icon, state: state, size: dot),
                  if (!isLast)
                    Expanded(
                      child: _GrowLine(
                        color: _connectorColor,
                        delay:
                            TrackingReveal.stagger(index, stepMs: 110) +
                            const Duration(milliseconds: 220),
                        margin: EdgeInsets.symmetric(vertical: w * 0.008),
                        thickness: w * 0.006,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: w * 0.035),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  top: w * 0.008,
                  bottom: isLast ? w * 0.03 : w * 0.05,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            milestone.title,
                            style: TextStyle(
                              fontSize: w * 0.037,
                              fontWeight: isUpcoming
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: titleColor,
                            ),
                          ),
                        ),
                        if (time != null && !isUpcoming)
                          Text(
                            _formatTime(time),
                            style: TextStyle(
                              fontSize: w * 0.029,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    if (!isUpcoming && text != null) ...[
                      SizedBox(height: w * 0.008),
                      // Cross-fades when a live status change rewrites the line.
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.topLeft,
                          children: [...previous, ?current],
                        ),
                        child: Text(
                          text,
                          key: ValueKey(text),
                          style: TextStyle(
                            fontSize: w * 0.031,
                            height: 1.35,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "2:45 PM" today, "Mon 2:45 PM" this week, otherwise "12 Oct, 2:45 PM".
  static String _formatTime(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final clock =
        '$hour:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final daysAgo = today.difference(day).inDays;
    if (daysAgo == 0) return clock;
    if (daysAgo > 0 && daysAgo < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[t.weekday - 1]} $clock';
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${t.day} ${months[t.month - 1]}, $clock';
  }
}

/// Milestone circle; the current one pulses like the food stepper's.
class _MilestoneDot extends StatefulWidget {
  const _MilestoneDot({
    required this.icon,
    required this.state,
    required this.size,
  });

  final IconData icon;
  final _MilestoneState state;
  final double size;

  @override
  State<_MilestoneDot> createState() => _MilestoneDotState();
}

class _MilestoneDotState extends State<_MilestoneDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  bool get _isCurrent => widget.state == _MilestoneState.current;

  @override
  void initState() {
    super.initState();
    if (_isCurrent) _pulse.repeat();
  }

  @override
  void didUpdateWidget(covariant _MilestoneDot oldWidget) {
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
      _MilestoneState.done => (
        AppColors.success,
        AppColors.success,
        Colors.white,
      ),
      _MilestoneState.current => (
        AppColors.primary,
        AppColors.primary,
        Colors.white,
      ),
      _MilestoneState.upcoming => (
        AppColors.surfaceVariant,
        AppColors.border,
        AppColors.textHint,
      ),
      _MilestoneState.failed => (
        AppColors.error,
        AppColors.error,
        Colors.white,
      ),
      _MilestoneState.refunded => (
        AppColors.warning,
        AppColors.warning,
        Colors.white,
      ),
    };

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (_isCurrent)
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) => Transform.scale(
              scale: 1 + 0.6 * _pulse.value,
              child: Opacity(opacity: 1 - _pulse.value, child: child),
            ),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: border),
          ),
          // Pops when a step flips state (e.g. current → done check).
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.elasticOut,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              widget.state == _MilestoneState.done
                  ? Icons.check_rounded
                  : widget.icon,
              key: ValueKey(widget.state),
              size: size * 0.52,
              color: iconColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackingNumberChip extends StatelessWidget {
  const _TrackingNumberChip({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return InkWell(
      borderRadius: BorderRadius.circular(w),
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tracking number copied')));
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.025,
          vertical: w * 0.012,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: w * 0.029,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: w * 0.012),
            Icon(
              Icons.copy_rounded,
              size: w * 0.033,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical connector that draws itself downward after [delay], and
/// cross-fades its colour when the next step's state changes. Painted
/// rather than composed from sized boxes so it adds no intrinsic height —
/// the timeline rows measure themselves with [IntrinsicHeight].
class _GrowLine extends StatelessWidget {
  const _GrowLine({
    required this.color,
    required this.delay,
    required this.margin,
    required this.thickness,
  });

  final Color color;
  final Duration delay;
  final EdgeInsets margin;
  final double thickness;

  static const _draw = Duration(milliseconds: 450);

  @override
  Widget build(BuildContext context) {
    final instant = MediaQuery.disableAnimationsOf(context);
    final total = _draw + delay;

    return Padding(
      padding: margin,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(begin: color, end: color),
        duration: instant ? Duration.zero : const Duration(milliseconds: 400),
        builder: (_, animatedColor, _) => TweenAnimationBuilder<double>(
          tween: Tween(begin: instant ? 1 : 0, end: 1),
          duration: instant ? Duration.zero : total,
          curve: Interval(
            delay.inMilliseconds / total.inMilliseconds,
            1,
            curve: Curves.easeOutCubic,
          ),
          builder: (_, progress, _) => CustomPaint(
            size: Size(thickness, double.infinity),
            painter: _LinePainter(
              color: animatedColor ?? color,
              progress: progress,
            ),
          ),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height * progress;
    if (height <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, height),
        Radius.circular(size.width),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.color != color || old.progress != progress;
}
