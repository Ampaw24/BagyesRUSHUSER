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

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(
        w * 0.06,
        0,
        w * 0.06,
        bottomPadding + w * 0.04,
      ),
      padding: EdgeInsets.symmetric(horizontal: w * 0.02, vertical: w * 0.03),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(w * 0.06),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: w * 0.06,
            spreadRadius: 0,
            offset: Offset(0, w * 0.02),
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
                      size: w * 0.06,
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      strokeWidth: selected ? 1.8 : 1.4,
                    ),
                  ),
                  SizedBox(height: w * 0.015),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    height: w * 0.013,
                    width: selected ? w * 0.013 : 0,
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
    );
  }
}
