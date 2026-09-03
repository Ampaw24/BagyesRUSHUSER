import 'package:flutter/material.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';

class FoodCategory {
  final String label;
  final String emoji;
  final String? imageUrl;

  const FoodCategory({
    required this.label,
    required this.emoji,
    this.imageUrl,
  });

  static const List<FoodCategory> all = [
    FoodCategory(label: 'All', emoji: '🍽️'),
    FoodCategory(label: 'Ghanaian', emoji: '🇬🇭'),
    FoodCategory(label: 'Fast Food', emoji: '🍔'),
    FoodCategory(label: 'Pizza', emoji: '🍕'),
    FoodCategory(label: 'Chinese', emoji: '🥢'),
    FoodCategory(label: 'Healthy', emoji: '🥗'),
    FoodCategory(label: 'Chicken', emoji: '🍗'),
    FoodCategory(label: 'Desserts', emoji: '🍰'),
    FoodCategory(label: 'Drinks', emoji: '🥤'),
  ];
}

class FoodCategoryChip extends StatelessWidget {
  final FoodCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const FoodCategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.035,
          vertical: w * 0.014,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.06),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Text(
          category.label,
          style: TextStyle(
            fontSize: w * 0.032,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
