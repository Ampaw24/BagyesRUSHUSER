import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/review_tag.dart';

/// Five tappable stars with a springy pop on the chosen star and an
/// optional live caption ("Good", "Excellent!"). [starSizeFactor] is a
/// fraction of the screen width so it scales across devices.
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.starSizeFactor = 0.11,
    this.showCaption = true,
    this.enabled = true,
  });

  final int rating;
  final ValueChanged<int> onChanged;
  final double starSizeFactor;
  final bool showCaption;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final size = w * starSizeFactor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final value = i + 1;
            return _Star(
              key: ValueKey(value),
              filled: value <= rating,
              isSelected: value == rating,
              size: size,
              semanticsLabel: '$value star${value > 1 ? 's' : ''}',
              onTap: enabled
                  ? () {
                      HapticFeedback.selectionClick();
                      onChanged(value);
                    }
                  : null,
            );
          }),
        ),
        if (showCaption) ...[
          SizedBox(height: w * 0.02),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween(begin: 0.9, end: 1.0).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              ratingCaption(rating),
              key: ValueKey(rating),
              style: TextStyle(
                fontSize: w * 0.04,
                fontWeight: rating > 0 ? FontWeight.w700 : FontWeight.w500,
                color: rating > 0 ? AppColors.textPrimary : AppColors.textHint,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Star extends StatefulWidget {
  const _Star({
    super.key,
    required this.filled,
    required this.isSelected,
    required this.size,
    required this.semanticsLabel,
    this.onTap,
  });

  final bool filled;
  final bool isSelected;
  final double size;
  final String semanticsLabel;
  final VoidCallback? onTap;

  @override
  State<_Star> createState() => _StarState();
}

class _StarState extends State<_Star> with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.3), weight: 40),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.3,
        end: 1,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 60,
    ),
  ]).animate(_pop);

  @override
  void didUpdateWidget(covariant _Star oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.filled,
      label: widget.semanticsLabel,
      child: InkResponse(
        onTap: widget.onTap,
        radius: widget.size * 0.6,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.size * 0.08),
          child: ScaleTransition(
            scale: _scale,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                widget.filled ? Icons.star_rounded : Icons.star_outline_rounded,
                key: ValueKey(widget.filled),
                size: widget.size,
                color: widget.filled ? AppColors.accent : AppColors.border,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
