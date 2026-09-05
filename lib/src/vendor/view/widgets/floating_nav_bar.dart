import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../constant/app_theme.dart';

class NavItem {
  final List<List<dynamic>> icon;
  final String label;

  const NavItem({required this.icon, required this.label});
}

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  // Fractions (of screen width) that make up this bar's own height, kept as
  // named constants so `reservedHeight` below can't drift out of sync with
  // the layout actually drawn in `build`.
  static const double _bottomMarginFraction = 0.04;
  static const double _verticalPaddingFraction = 0.03;
  static const double _iconSizeFraction = 0.06;
  static const double _iconLabelGapFraction = 0.015;
  static const double _labelDotFraction = 0.013;

  /// Total vertical space this bar occupies from the bottom of the screen —
  /// its bottom margin, internal padding, and content height combined.
  ///
  /// This bar floats in a [Stack] above whatever tab is showing (it's not a
  /// real [Scaffold.bottomNavigationBar]), so scrollable content in those
  /// tabs never gets the usual automatic bottom inset — pass this as extra
  /// bottom padding on that content so its last item can scroll clear of
  /// the bar instead of ending up hidden behind it.
  static double reservedHeight(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final bottomSafeArea = MediaQuery.viewPaddingOf(context).bottom;
    final contentHeight =
        w * (_iconSizeFraction + _iconLabelGapFraction + _labelDotFraction);
    return bottomSafeArea +
        w * _bottomMarginFraction +
        w * _verticalPaddingFraction * 2 +
        contentHeight;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(
        w * 0.06,
        0,
        w * 0.06,
        bottomPadding + w * _bottomMarginFraction,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(w * 0.08),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.02,
              vertical: w * _verticalPaddingFraction,
            ),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(w * 0.08),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final selected = i == currentIndex;
                return GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: w * 0.14,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: selected ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          child: HugeIcon(
                            icon: items[i].icon,
                            size: w * _iconSizeFraction,
                            color: selected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.45),
                            strokeWidth: selected ? 1.8 : 1.4,
                          ),
                        ),
                        SizedBox(height: w * _iconLabelGapFraction),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          height: w * _labelDotFraction,
                          width: selected ? w * _labelDotFraction : 0,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
