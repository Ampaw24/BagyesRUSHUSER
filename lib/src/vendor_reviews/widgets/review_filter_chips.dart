import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';

/// Horizontally-scrollable, mutually-exclusive filter tabs: All, Unanswered,
/// then 5★ down to 1★. [onSelect] receives the resulting (rating, unanswered)
/// pair for the tapped tab — the caller applies both to the viewmodel.
class ReviewFilterChips extends StatelessWidget {
  const ReviewFilterChips({
    super.key,
    required this.ratingFilter,
    required this.unansweredOnly,
    required this.onSelect,
  });

  final int? ratingFilter;
  final bool unansweredOnly;
  final void Function(int? rating, bool unanswered) onSelect;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isAllSelected = ratingFilter == null && !unansweredOnly;

    return SizedBox(
      height: w * 0.1,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: w * 0.04),
        children: [
          _FilterChip(
            label: 'All',
            selected: isAllSelected,
            onTap: () => onSelect(null, false),
            w: w,
          ),
          SizedBox(width: w * 0.02),
          _FilterChip(
            label: 'Unanswered',
            selected: unansweredOnly,
            onTap: () => onSelect(null, true),
            w: w,
          ),
          for (final star in [5, 4, 3, 2, 1]) ...[
            SizedBox(width: w * 0.02),
            _FilterChip(
              label: '$star★',
              selected: ratingFilter == star,
              onTap: () => onSelect(star, false),
              w: w,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.w,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(w * 0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(w * 0.05),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.04,
            vertical: w * 0.022,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: w * 0.033,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
              fontFamily: 'Mukta',
            ),
          ),
        ),
      ),
    );
  }
}
