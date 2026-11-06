import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:gopady/constant/app_theme.dart';
import 'package:gopady/constant/app_tokens.dart';
import 'package:gopady/resources/resources.dart';

/// The app's animated status vocabulary, each backed by a brand Lottie file
/// in `assets/lottie/`. One-shot statuses play once and hold their last
/// frame; [processing] and [searching] loop.
enum AppStatus {
  success(
    asset: LottieAssets.success,
    label: 'Success',
    fallbackIcon: Icons.check_circle_rounded,
    color: AppColors.success,
  ),
  error(
    asset: LottieAssets.error,
    label: 'Error',
    fallbackIcon: Icons.cancel_rounded,
    color: AppColors.error,
  ),
  warning(
    asset: LottieAssets.warning,
    label: 'Warning',
    fallbackIcon: Icons.error_rounded,
    color: AppColors.accentDark,
  ),
  info(
    asset: LottieAssets.info,
    label: 'Information',
    fallbackIcon: Icons.info_rounded,
    color: AppColors.info,
  ),
  processing(
    asset: LottieAssets.processing,
    label: 'Loading',
    fallbackIcon: Icons.hourglass_top_rounded,
    color: AppColors.primary,
    loops: true,
  ),
  searching(
    asset: LottieAssets.searching,
    label: 'Searching',
    fallbackIcon: Icons.radar_rounded,
    color: AppColors.primary,
    loops: true,
  );

  const AppStatus({
    required this.asset,
    required this.label,
    required this.fallbackIcon,
    required this.color,
    this.loops = false,
  });

  final String asset;
  final String label;
  final IconData fallbackIcon;
  final Color color;
  final bool loops;
}

/// Plays an [AppStatus] animation at a size that scales with the screen.
///
/// Give an explicit [size] when it must match surrounding UI; otherwise it
/// is [sizeFactor] of the screen's shortest side, clamped to
/// [minSize]–[maxSize] so it stays sensible on small phones, tablets and in
/// landscape. With the platform's reduce-motion setting on, one-shot
/// statuses jump to their final frame and loops hold still.
class AppStatusAnimation extends StatefulWidget {
  const AppStatusAnimation(
    this.status, {
    super.key,
    this.size,
    this.sizeFactor = 0.28,
    this.minSize = 24,
    this.maxSize = 200,
    this.delay = Duration.zero,
    this.semanticLabel,
    this.onCompleted,
  });

  final AppStatus status;
  final double? size;
  final double sizeFactor;
  final double minSize;
  final double maxSize;

  /// Wait before playing, e.g. until an entrance transition has finished.
  final Duration delay;
  final String? semanticLabel;

  /// Called once a one-shot status has finished playing.
  final VoidCallback? onCompleted;

  @override
  State<AppStatusAnimation> createState() => _AppStatusAnimationState();
}

class _AppStatusAnimationState extends State<AppStatusAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this)
    ..addStatusListener(_onStatus);

  /// Bumped on every (re)start so a stale delayed start is ignored.
  int _generation = 0;

  @override
  void didUpdateWidget(covariant AppStatusAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _generation++;
      _controller
        ..stop()
        ..value = 0;
      // The new composition's onLoaded restarts playback.
    }
  }

  @override
  void dispose() {
    _generation++;
    _controller.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !widget.status.loops) {
      widget.onCompleted?.call();
    }
  }

  void _onLoaded(LottieComposition composition) {
    if (!mounted) return;
    _controller.duration = composition.duration;
    _play(++_generation);
  }

  Future<void> _play(int generation) async {
    if (MediaQuery.disableAnimationsOf(context)) {
      // Landing on 1 reports `completed`, which notifies onCompleted.
      _controller.value = widget.status.loops ? 0 : 1;
      return;
    }
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
      if (!mounted || generation != _generation) return;
    }
    if (widget.status.loops) {
      _controller.repeat();
    } else {
      _controller.forward(from: 0);
    }
  }

  double _resolveSize(BuildContext context) {
    final explicit = widget.size;
    if (explicit != null) return explicit;
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    return (shortest * widget.sizeFactor).clamp(widget.minSize, widget.maxSize);
  }

  @override
  Widget build(BuildContext context) {
    final dimension = _resolveSize(context);
    final status = widget.status;

    return Semantics(
      label: widget.semanticLabel ?? status.label,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: dimension,
          child: Lottie.asset(
            status.asset,
            key: ValueKey(status),
            controller: _controller,
            width: dimension,
            height: dimension,
            fit: BoxFit.contain,
            onLoaded: _onLoaded,
            errorBuilder: (_, _, _) => Icon(
              status.fallbackIcon,
              size: dimension * 0.7,
              color: status.color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Centred brand loader with an optional message — the page-level
/// replacement for a bare [CircularProgressIndicator].
class AppLoader extends StatelessWidget {
  const AppLoader({
    super.key,
    this.message,
    this.status = AppStatus.processing,
    this.sizeFactor = 0.2,
  });

  final String? message;
  final AppStatus status;
  final double sizeFactor;

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final message = this.message;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(shortest * 0.06),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppStatusAnimation(
              status,
              sizeFactor: sizeFactor,
              maxSize: 140,
              semanticLabel: message ?? status.label,
            ),
            if (message != null) ...[
              SizedBox(height: shortest * 0.03),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: (shortest * 0.036).clamp(13.0, 18.0),
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-area status message: animation, title, supporting text and an
/// optional action — for error, empty-result and outcome states.
class AppStatusView extends StatelessWidget {
  const AppStatusView({
    super.key,
    required this.status,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final AppStatus status;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final message = this.message;
    final actionLabel = this.actionLabel;
    final onAction = this.onAction;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: shortest * 0.1,
          vertical: shortest * 0.06,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppStatusAnimation(status, sizeFactor: 0.3, maxSize: 160),
            SizedBox(height: shortest * 0.04),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: (shortest * 0.05).clamp(17.0, 24.0),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (message != null && message.isNotEmpty) ...[
              SizedBox(height: shortest * 0.02),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: (shortest * 0.036).clamp(13.0, 17.0),
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: shortest * 0.06),
              FilledButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
