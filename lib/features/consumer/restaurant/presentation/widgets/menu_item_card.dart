import 'package:flutter/material.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/menu_item.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final int cartQuantity; // 0 = not in cart
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.cartQuantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      margin: EdgeInsets.only(bottom: w * 0.035),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        children: [
          // ── Image ──
          ClipRRect(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(w * 0.035)),
            child: SizedBox(
              width: w * 0.3,
              height: w * 0.28,
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.shimmerBase,
                  child: const Icon(Icons.fastfood,
                      color: AppColors.textHint),
                ),
              ),
            ),
          ),
          // ── Content ──
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(w * 0.035),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.isPopular)
                    Container(
                      margin: EdgeInsets.only(bottom: w * 0.012),
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.02,
                        vertical: w * 0.006,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Popular',
                        style: TextStyle(
                          fontSize: w * 0.025,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: w * 0.036,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: w * 0.008),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: w * 0.028,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: w * 0.02),
                  Row(
                    children: [
                      Text(
                        'GHS ${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: w * 0.036,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      if (!item.isAvailable)
                        Text(
                          'Unavailable',
                          style: TextStyle(
                            fontSize: w * 0.028,
                            color: AppColors.textHint,
                          ),
                        )
                      else if (cartQuantity == 0)
                        _AddButton(onAdd: onAdd)
                      else
                        _QuantityControl(
                          quantity: cartQuantity,
                          onAdd: onAdd,
                          onRemove: onRemove,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onAdd;
  const _AddButton({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        padding: EdgeInsets.all(w * 0.018),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.add, color: Colors.white, size: w * 0.04),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _QuantityControl({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Row(
      children: [
        GestureDetector(
          onTap: onRemove,
          child: Container(
            padding: EdgeInsets.all(w * 0.015),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.remove, color: AppColors.primary, size: w * 0.035),
          ),
        ),
        SizedBox(width: w * 0.025),
        Text(
          '$quantity',
          style: TextStyle(
            fontSize: w * 0.038,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(width: w * 0.025),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: EdgeInsets.all(w * 0.015),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, color: Colors.white, size: w * 0.035),
          ),
        ),
      ],
    );
  }
}
