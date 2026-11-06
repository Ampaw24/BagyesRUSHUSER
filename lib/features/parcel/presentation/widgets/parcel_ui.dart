import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import 'package:gopady/constant/app_tokens.dart';

/// Shared visual primitives for the parcel wizard so every step reads as
/// one system: same header rhythm, card surface, section labels and notes.

/// Title + supporting line at the top of each step.
class ParcelStepHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const ParcelStepHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: w * 0.06,
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: -0.4,
            color: AppColors.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: w * 0.015),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: w * 0.035,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Small section heading with an optional trailing widget (count, badge…).
class ParcelSectionLabel extends StatelessWidget {
  final String label;
  final String? caption;
  final Widget? trailing;

  const ParcelSectionLabel({
    super.key,
    required this.label,
    this.caption,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: w * 0.042,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (caption != null) ...[
                SizedBox(height: w * 0.006),
                Text(
                  caption!,
                  style: TextStyle(
                    fontSize: w * 0.031,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// White rounded surface with a hairline border — the base card of the flow.
class ParcelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool highlighted;

  const ParcelCard({
    super.key,
    required this.child,
    this.padding,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.outExpo,
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(w * 0.04),
      decoration: parcelCardDecoration(w, highlighted: highlighted),
      child: child,
    );
  }
}

BoxDecoration parcelCardDecoration(double w, {bool highlighted = false}) =>
    BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(w * 0.045),
      border: Border.all(
        color: highlighted ? AppColors.primary : AppColors.border,
        width: highlighted ? 1.5 : 1,
      ),
      boxShadow: AppShadows.card,
    );

enum ParcelNoteTone { neutral, info, warning, error }

/// Compact inline note with an icon, used for tips and constraints.
class ParcelNote extends StatelessWidget {
  final String message;
  final ParcelNoteTone tone;
  final List<List<dynamic>>? icon;

  const ParcelNote({
    super.key,
    required this.message,
    this.tone = ParcelNoteTone.neutral,
    this.icon,
  });

  Color get _ink => switch (tone) {
    ParcelNoteTone.neutral => AppColors.textSecondary,
    ParcelNoteTone.info => AppColors.info,
    ParcelNoteTone.warning => AppColors.accentInk,
    ParcelNoteTone.error => AppColors.error,
  };

  Color get _fill => switch (tone) {
    ParcelNoteTone.neutral => AppColors.surface,
    ParcelNoteTone.info => AppColors.info.withValues(alpha: 0.06),
    ParcelNoteTone.warning => AppColors.accent.withValues(alpha: 0.14),
    ParcelNoteTone.error => AppColors.error.withValues(alpha: 0.06),
  };

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.03),
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(w * 0.03),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(
            icon: icon ?? HugeIcons.strokeRoundedInformationCircle,
            color: _ink,
            size: w * 0.042,
          ),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: w * 0.031, height: 1.45, color: _ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Round tinted icon container used as a leading visual in list rows.
class ParcelIconBadge extends StatelessWidget {
  final List<List<dynamic>> icon;
  final bool active;
  final Color? color;
  final double sizeFactor;

  const ParcelIconBadge({
    super.key,
    required this.icon,
    this.active = false,
    this.color,
    this.sizeFactor = 0.11,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final tint = color ?? AppColors.primary;
    final size = w * sizeFactor;
    return AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.outExpo,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: active ? tint : AppColors.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: HugeIcon(
          icon: icon,
          color: active ? Colors.white : AppColors.textSecondary,
          size: size * 0.48,
        ),
      ),
    );
  }
}

/// Radio-style selection indicator (filled check when selected).
class ParcelSelectionDot extends StatelessWidget {
  final bool selected;

  const ParcelSelectionDot({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final size = w * 0.055;
    return AnimatedContainer(
      duration: AppMotion.micro,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.fieldBorder,
          width: 1.5,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, color: Colors.white, size: size * 0.7)
          : null,
    );
  }
}

/// Vertical spacing helper scaled to screen width.
class ParcelGap extends StatelessWidget {
  final double factor;
  const ParcelGap(this.factor, {super.key});

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: MediaQuery.sizeOf(context).width * factor);
}
