import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';

// ─── Loading skeleton ────────────────────────────────────────────────────────

/// Pulsing card-shaped placeholders shown on first load.
class NotificationsSkeleton extends StatefulWidget {
  const NotificationsSkeleton({super.key});

  static const int _itemCount = 6;

  @override
  State<NotificationsSkeleton> createState() => _NotificationsSkeletonState();
}

class _NotificationsSkeletonState extends State<NotificationsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = _pulse.drive(
    Tween<double>(begin: 0.45, end: 1)
        .chain(CurveTween(curve: Curves.easeInOut)),
  );

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return FadeTransition(
      opacity: _opacity,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: w * 0.04),
        itemCount: NotificationsSkeleton._itemCount,
        itemBuilder: (_, _) => const _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      margin: EdgeInsets.only(bottom: w * 0.025),
      padding: EdgeInsets.all(w * 0.035),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.045),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: w * 0.115,
            height: w * 0.115,
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(w * 0.032),
            ),
          ),
          SizedBox(width: w * 0.032),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bar(widthFactor: 0.55, height: w * 0.035),
                SizedBox(height: w * 0.02),
                _Bar(widthFactor: 1, height: w * 0.026),
                SizedBox(height: w * 0.012),
                _Bar(widthFactor: 0.75, height: w * 0.026),
                SizedBox(height: w * 0.025),
                _Bar(widthFactor: 0.28, height: w * 0.035),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.widthFactor, required this.height});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(height),
        ),
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

/// Centered illustration + copy that scales in once when shown.
class NotificationsEmptyState extends StatelessWidget {
  const NotificationsEmptyState({super.key, required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (_, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: w * 0.26,
                height: w * 0.26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  width: w * 0.17,
                  height: w * 0.17,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedNotification02,
                    size: w * 0.08,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: w * 0.05),
              Text(
                'No notifications yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: w * 0.012),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: w * 0.033,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
