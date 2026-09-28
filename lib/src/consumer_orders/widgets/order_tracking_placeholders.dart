import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';

/// Skeleton shown while an order that isn't cached yet is being fetched —
/// mirrors the tracking layout (banner, codes, timeline, cards) so the
/// content settles in place instead of popping in from a blank screen.
class OrderTrackingSkeleton extends StatefulWidget {
  const OrderTrackingSkeleton({super.key});

  @override
  State<OrderTrackingSkeleton> createState() => _OrderTrackingSkeletonState();
}

class _OrderTrackingSkeletonState extends State<OrderTrackingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    Widget block(double height, {double widthFactor = 1}) => Padding(
          padding: EdgeInsets.only(bottom: w * 0.04),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: widthFactor,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(w * 0.04),
              ),
            ),
          ),
        );

    return Semantics(
      label: 'Loading your order',
      child: FadeTransition(
        opacity: _pulse,
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.06),
          children: [
            block(w * 0.24),
            block(w * 0.2),
            block(w * 0.05, widthFactor: 0.4),
            for (var i = 0; i < 4; i++) block(w * 0.07, widthFactor: 0.6),
            block(w * 0.05, widthFactor: 0.45),
            block(w * 0.16),
            block(w * 0.3),
          ],
        ),
      ),
    );
  }
}

/// Recoverable failure state for the tracking screen: explains what went
/// wrong and always offers a way forward (retry, or leave to a safe place)
/// instead of a dead end.
class OrderTrackingErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onExit;
  final bool isRetrying;

  const OrderTrackingErrorView({
    super.key,
    required this.onRetry,
    required this.onExit,
    this.isRetrying = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: w * 0.08),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.06),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_tethering_error_rounded,
                  size: w * 0.14,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: w * 0.06),
              Text(
                'We couldn\'t load your order',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: w * 0.05,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: w * 0.025),
              Text(
                'Your order is safe — this is just a connection hiccup. '
                'Check your internet and try again, or find it later under My Orders.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: w * 0.036,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: w * 0.08),
              ElevatedButton.icon(
                onPressed: isRetrying ? null : onRetry,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, w * 0.12),
                ),
                icon: isRetrying
                    ? SizedBox(
                        width: w * 0.045,
                        height: w * 0.045,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.refresh_rounded, size: w * 0.05),
                label: Text(isRetrying ? 'Retrying…' : 'Try again'),
              ),
              SizedBox(height: w * 0.03),
              TextButton(
                onPressed: onExit,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  minimumSize: Size(double.infinity, w * 0.12),
                ),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
