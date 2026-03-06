import 'package:flutter/material.dart';
import '../../../../../../constant/app_theme.dart';

/// A pill-style animated tab switcher (Notifications | Messages).
/// Uses LayoutBuilder so tabWidth is derived from the actual available
/// space — no hard-coded or MediaQuery-relative widths that can overflow.
class AnimatedTabSwitcher extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final List<int> badgeCounts;
  final ValueChanged<int> onTabChanged;

  const AnimatedTabSwitcher({
    super.key,
    required this.selectedIndex,
    required this.labels,
    required this.badgeCounts,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    // inner padding: w*0.01 on each side of the pill container
    final innerPadding = w * 0.01 * 2;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          // Each tab occupies an equal slice of the inner area
          final tabWidth =
              (availableWidth - innerPadding) / labels.length;
          final pillHeight = w * 0.1;

          return Container(
            padding: EdgeInsets.all(w * 0.01),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(w * 0.05),
            ),
            child: Stack(
              children: [
                // ── Animated sliding pill ──────────────────────────
                AnimatedAlign(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  alignment: selectedIndex == 0
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    width: tabWidth,
                    height: pillHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(w * 0.04),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Tab labels (tightly bounded by tabWidth) ───────
                Row(
                  children: List.generate(labels.length, (i) {
                    final isSelected = i == selectedIndex;
                    final badge =
                        badgeCounts.length > i ? badgeCounts[i] : 0;

                    return GestureDetector(
                      onTap: () => onTabChanged(i),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: tabWidth,
                        height: pillHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            // Label — flexible so it never overflows
                            Flexible(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontFamily: 'Mukta',
                                  fontSize: w * 0.036,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                ),
                                child: Text(
                                  labels[i],
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),

                            // Badge — only rendered when count > 0
                            if (badge > 0) ...[
                              SizedBox(width: w * 0.012),
                              AnimatedScale(
                                scale: isSelected ? 1.0 : 0.85,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: w * 0.016,
                                    vertical: w * 0.004,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius:
                                        BorderRadius.circular(w * 0.03),
                                  ),
                                  child: Text(
                                    '$badge',
                                    style: TextStyle(
                                      fontFamily: 'Mukta',
                                      fontSize: w * 0.026,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
