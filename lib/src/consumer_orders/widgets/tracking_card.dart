import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';

/// Outlined white card shared by the order-tracking sections.
class TrackingCard extends StatelessWidget {
  const TrackingCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.05),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.04),
            blurRadius: w * 0.03,
            offset: Offset(0, w * 0.01),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Outlined (or [filled]) circular icon button used in the tracking header
/// and rider card.
class TrackingCircleButton extends StatelessWidget {
  const TrackingCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.background = AppColors.card,
    this.foreground = AppColors.textPrimary,
    this.bordered = true,
    this.sizeFactor = 0.11,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color background;
  final Color foreground;
  final bool bordered;

  /// Diameter as a fraction of screen width.
  final double sizeFactor;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final size = w * sizeFactor;
    final shape = CircleBorder(
      side: bordered
          ? const BorderSide(color: AppColors.border)
          : BorderSide.none,
    );

    final button = Material(
      color: background,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, size: size * 0.45, color: foreground),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
