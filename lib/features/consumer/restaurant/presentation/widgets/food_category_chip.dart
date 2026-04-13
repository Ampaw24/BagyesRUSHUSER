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
    final iconSize = w * 0.055;
    final hasImage = category.imageUrl != null && category.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.04,
          vertical: w * 0.025,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.06),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(iconSize),
                child: Image.network(
                  // force HTTPS — iOS ATS blocks plain HTTP URLs silently
                  category.imageUrl!.replaceFirst('http://', 'https://'),
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.cover,
                  // show emoji while the image is fetching
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: Center(
                        child: Text(
                          category.emoji,
                          style: TextStyle(fontSize: w * 0.038),
                        ),
                      ),
                    );
                  },
                  // show emoji if the image fails (bad URL, 404, etc.)
                  errorBuilder: (context, error, stackTrace) => Text(
                    category.emoji,
                    style: TextStyle(fontSize: w * 0.038),
                  ),
                ),
              )
            else
              Text(
                category.emoji,
                style: TextStyle(fontSize: w * 0.038),
              ),
            SizedBox(width: w * 0.015),
            Text(
              category.label,
              style: TextStyle(
                fontSize: w * 0.032,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
