import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';

/// Status headline for the tracking screen: an animated illustration, a
/// status title, the ETA line and a "what happens next" hint, plus rider
/// distance / door-wait chips when the backend reports them.
class TrackingStatusHero extends StatelessWidget {
  const TrackingStatusHero({
    super.key,
    required this.order,
    this.isConfirmingPayment = false,
  });

  final ConsumerOrder order;
  final bool isConfirmingPayment;

  static const _onTheWayImage = 'assets/tracking.png';
  static const _findingRiderImage = 'assets/scooter_search.png';

  bool get _isParcel => order.isParcel;

  /// A paid parcel still waiting for a rider to accept it.
  bool get _isFindingRider =>
      _isParcel &&
      order.status == OrderStatus.pending &&
      !isConfirmingPayment &&
      !order.needsPayment;

  Color get _color => switch (order.status) {
    OrderStatus.cancelled || OrderStatus.rejected => AppColors.error,
    OrderStatus.delivered => AppColors.success,
    OrderStatus.refunded => AppColors.warning,
    _ => AppColors.primary,
  };

  IconData get _icon => switch (order.status) {
    OrderStatus.pending when order.needsPayment => Icons.payments_rounded,
    OrderStatus.pending =>
      _isParcel ? Icons.person_search_rounded : Icons.receipt_long_rounded,
    OrderStatus.accepted =>
      _isParcel ? Icons.two_wheeler_rounded : Icons.thumb_up_alt_rounded,
    OrderStatus.preparing =>
      _isParcel ? Icons.two_wheeler_rounded : Icons.restaurant_rounded,
    OrderStatus.readyForPickup =>
      _isParcel ? Icons.two_wheeler_rounded : Icons.room_service_rounded,
    OrderStatus.pickedUp ||
    OrderStatus.onTheWay => Icons.delivery_dining_rounded,
    OrderStatus.delivered => Icons.task_alt_rounded,
    OrderStatus.cancelled => Icons.cancel_rounded,
    OrderStatus.rejected => Icons.block_rounded,
    OrderStatus.refunded => Icons.currency_exchange_rounded,
  };

  /// Illustration shown instead of [_icon] once the rider has the order.
  String? get _image => switch (order.status) {
    OrderStatus.pickedUp || OrderStatus.onTheWay => _onTheWayImage,
    _ => null,
  };

  String get _title {
    final noun = _isParcel ? 'parcel' : 'order';
    return switch (order.status) {
      OrderStatus.pending when isConfirmingPayment => 'Confirming payment',
      OrderStatus.pending when order.needsPayment => 'Payment needed',
      OrderStatus.pending => _isParcel ? 'Finding you a rider' : 'Order placed',
      OrderStatus.accepted => _isParcel ? 'Rider assigned' : 'Order confirmed',
      OrderStatus.preparing =>
        _isParcel ? 'Rider heading to pickup' : 'Preparing your food',
      OrderStatus.readyForPickup =>
        _isParcel ? 'Rider heading to pickup' : 'Your food is ready',
      OrderStatus.pickedUp => 'Your $noun has been picked up',
      OrderStatus.onTheWay => 'Your $noun is on the way!',
      OrderStatus.delivered =>
        _isParcel ? 'Parcel delivered' : 'Order delivered',
      OrderStatus.cancelled =>
        _isParcel ? 'Parcel cancelled' : 'Order cancelled',
      OrderStatus.rejected => _isParcel ? 'Request declined' : 'Order declined',
      OrderStatus.refunded => _isParcel ? 'Parcel refunded' : 'Order refunded',
    };
  }

  /// One-line "what happens next" under the title, parcel-aware.
  String? get _hint => switch (order.status) {
    OrderStatus.pending when isConfirmingPayment =>
      'Hang tight while we confirm your payment.',
    OrderStatus.pending when order.needsPayment =>
      'Complete payment to confirm your order.',
    OrderStatus.pending =>
      _isParcel
          ? 'Finding a rider nearby…'
          : 'Waiting for the restaurant to confirm.',
    OrderStatus.accepted =>
      _isParcel
          ? 'Your rider is heading to the pickup point.'
          : 'The restaurant has confirmed your order.',
    OrderStatus.preparing || OrderStatus.readyForPickup =>
      _isParcel
          ? 'Your rider is heading to the pickup point.'
          : 'Your rider will pick it up shortly.',
    OrderStatus.pickedUp || OrderStatus.onTheWay =>
      _isParcel
          ? "We're almost there! Your parcel is on its way."
          : "We're almost there! Your food is on its way to your doorstep.",
    OrderStatus.delivered =>
      _isParcel ? 'Your parcel has been delivered.' : 'Enjoy your meal!',
    OrderStatus.cancelled => null,
    OrderStatus.rejected =>
      _isParcel
          ? "We couldn't find a rider for this request. Any payment "
                'will be refunded.'
          : "The restaurant couldn't take this order. Any payment "
                'will be refunded.',
    OrderStatus.refunded => 'Your refund is on its way back to you.',
  };

  String? get _etaLine {
    if (!order.status.isActive) return null;
    final eta = order.estimatedDelivery;
    if (eta != null) {
      final minutes = eta.difference(DateTime.now()).inMinutes;
      return minutes <= 0
          ? 'Arriving any moment now'
          : 'Arriving in $minutes min';
    }
    final prep = order.estimatedPrepMinutes;
    if (prep != null &&
        !_isParcel &&
        order.status.index <= OrderStatus.preparing.index) {
      return 'Estimated prep time · $prep min';
    }
    return null;
  }

  String? get _distanceLabel {
    final metres = order.arrivalDistanceMetres;
    if (metres == null) return null;
    if (metres >= 1000) return '${(metres / 1000).toStringAsFixed(1)} km away';
    return '${metres.round()} m away';
  }

  /// How much longer the rider waits at the door before the backend treats
  /// the customer as unreachable.
  String? get _waitLabel {
    final expires = order.waitExpiresAt;
    if (expires == null) return null;
    final remaining = expires.difference(DateTime.now());
    if (remaining.isNegative) return 'Wait time has expired';
    if (remaining.inMinutes < 1) return 'Rider waiting · under a minute left';
    return 'Rider waiting · ${remaining.inMinutes} min left';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final color = _color;
    final eta = _etaLine;
    final hint = _hint;
    final distance = _distanceLabel;
    final wait = _waitLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (_isFindingRider)
              _FindingRiderIllustration(
                imageAsset: _findingRiderImage,
                color: color,
              )
            else
              _HeroIllustration(
                icon: _icon,
                imageAsset: _image,
                color: color,
                animate: order.status.isActive,
              ),
            SizedBox(width: w * 0.045),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Slides/fades to the new headline when the status changes.
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.25),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topLeft,
                      children: [...previous, ?current],
                    ),
                    child: Text(
                      _title,
                      key: ValueKey(_title),
                      style: TextStyle(
                        fontSize: w * 0.047,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (eta != null) ...[
                    SizedBox(height: w * 0.012),
                    Text(
                      eta,
                      style: TextStyle(
                        fontSize: w * 0.037,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                  if (hint != null) ...[
                    SizedBox(height: w * 0.012),
                    Text(
                      hint,
                      style: TextStyle(
                        fontSize: w * 0.032,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (distance != null || wait != null) ...[
          SizedBox(height: w * 0.04),
          Wrap(
            spacing: w * 0.02,
            runSpacing: w * 0.02,
            children: [
              if (distance != null)
                _InfoChip(
                  icon: Icons.social_distance_rounded,
                  label: distance,
                  color: AppColors.primary,
                ),
              if (wait != null)
                _InfoChip(
                  icon: Icons.timer_outlined,
                  label: wait,
                  color: AppColors.warning,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Tinted circle holding the status icon (or [imageAsset] when given); bobs
/// gently while the order is active and cross-fades when the status changes.
class _HeroIllustration extends StatefulWidget {
  const _HeroIllustration({
    required this.icon,
    required this.color,
    required this.animate,
    this.imageAsset,
  });

  final IconData icon;
  final String? imageAsset;
  final Color color;
  final bool animate;

  @override
  State<_HeroIllustration> createState() => _HeroIllustrationState();
}

class _HeroIllustrationState extends State<_HeroIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _bob.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _HeroIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate == oldWidget.animate) return;
    widget.animate ? _bob.repeat(reverse: true) : _bob.animateTo(0);
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width * 0.26;
    final color = widget.color;
    final asset = widget.imageAsset;
    final icon = Icon(
      widget.icon,
      key: ValueKey(widget.icon),
      size: size * 0.48,
      color: color,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _bob,
        builder: (_, child) => Transform.translate(
          offset: Offset(
            0,
            -size * 0.04 * Curves.easeInOut.transform(_bob.value),
          ),
          child: child,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: asset == null
              ? icon
              : Image.asset(
                  asset,
                  key: ValueKey(asset),
                  width: size * 0.56,
                  height: size * 0.56,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => icon,
                ),
        ),
      ),
    );
  }
}

/// "Finding a rider" illustration: the rider rides gently in place while two
/// soft rings ripple out from behind, like a radar sweep.
class _FindingRiderIllustration extends StatefulWidget {
  const _FindingRiderIllustration({
    required this.imageAsset,
    required this.color,
  });

  final String imageAsset;
  final Color color;

  @override
  State<_FindingRiderIllustration> createState() =>
      _FindingRiderIllustrationState();
}

class _FindingRiderIllustrationState extends State<_FindingRiderIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width * 0.26;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final imageWidth = size * 0.68;
    final color = widget.color;

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _loop,
        builder: (_, _) {
          final t = _loop.value;
          // Two bobs and one slow drift per cycle keep the ride lively
          // without ever leaving the circle.
          final bob = math.sin(t * math.pi * 4) * size * 0.018;
          final drift = math.sin(t * math.pi * 2) * size * 0.03;

          return Stack(
            alignment: Alignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: 0.14),
                      color.withValues(alpha: 0.04),
                    ],
                  ),
                ),
                child: SizedBox.square(dimension: size * 0.8),
              ),
              _Ripple(progress: t, size: size, color: color),
              _Ripple(progress: (t + 0.5) % 1, size: size, color: color),
              Transform.translate(
                offset: Offset(drift, bob),
                child: Image.asset(
                  widget.imageAsset,
                  width: imageWidth,
                  cacheWidth: (imageWidth * pixelRatio).round(),
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.person_search_rounded,
                    size: size * 0.48,
                    color: color,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One expanding, fading ring; [progress] runs 0 → 1 over its lifetime.
class _Ripple extends StatelessWidget {
  const _Ripple({
    required this.progress,
    required this.size,
    required this.color,
  });

  final double progress;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOut.transform(progress);
    return Container(
      width: size * (0.5 + 0.5 * eased),
      height: size * (0.5 + 0.5 * eased),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.35 * (1 - progress)),
          width: 1.5,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: w * 0.018),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: w * 0.04, color: color),
          SizedBox(width: w * 0.015),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: w * 0.031,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
