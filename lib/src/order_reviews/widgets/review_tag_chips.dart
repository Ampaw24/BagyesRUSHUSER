import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';

/// Multi-select quick-feedback pills. Keyed by the tag set so switching
/// between praise and complaint chips cross-fades instead of snapping.
class ReviewTagChips extends StatelessWidget {
  const ReviewTagChips({
    super.key,
    required this.tags,
    required this.selected,
    required this.onToggle,
  });

  final List<String> tags;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Wrap(
        key: ValueKey(tags.first),
        spacing: w * 0.02,
        runSpacing: w * 0.02,
        children: [
          for (final tag in tags)
            _TagPill(
              label: tag,
              isSelected: selected.contains(tag),
              onTap: () {
                HapticFeedback.selectionClick();
                onToggle(tag);
              },
            ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final radius = BorderRadius.circular(w * 0.06);

    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.035,
              vertical: w * 0.022,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.surfaceVariant,
              borderRadius: radius,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.2 : 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: isSelected
                      ? Padding(
                          padding: EdgeInsets.only(right: w * 0.012),
                          child: Icon(
                            Icons.check_rounded,
                            size: w * 0.04,
                            color: AppColors.primary,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: w * 0.033,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
