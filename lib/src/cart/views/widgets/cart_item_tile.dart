import 'package:flutter/material.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/cart/models/cart_item_model.dart';

class CartItemTile extends StatelessWidget {
  final CartItemModel cartItem;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;
  final VoidCallback onEditNote;

  const CartItemTile({
    super.key,
    required this.cartItem,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onEditNote,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      margin: EdgeInsets.only(bottom: w * 0.035),
      padding: EdgeInsets.all(w * 0.035),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(w * 0.025),
            child: SizedBox(
              width: w * 0.2,
              height: w * 0.2,
              child: Image.network(
                cartItem.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.shimmerBase,
                  child: const Icon(Icons.fastfood, color: AppColors.textHint),
                ),
              ),
            ),
          ),
          SizedBox(width: w * 0.03),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.name,
                  style: TextStyle(
                    fontSize: w * 0.037,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                // Selected addons
                if (cartItem.addonOptions.isNotEmpty) ...[
                  SizedBox(height: w * 0.006),
                  ...cartItem.addonOptions.map(
                    (addon) {
                      final qtyPrefix =
                          addon.quantity > 1 ? '${addon.quantity}× ' : '';
                      final priceStr = addon.additionalPrice > 0
                          ? ' (GHS ${(addon.additionalPrice * addon.quantity).toStringAsFixed(2)})'
                          : '';
                      return Text(
                        '+ $qtyPrefix${addon.optionName}$priceStr',
                        style: TextStyle(
                          fontSize: w * 0.027,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                ],
                SizedBox(height: w * 0.007),
                GestureDetector(
                  onTap: onEditNote,
                  child: Row(
                    children: [
                      Icon(
                        Icons.note_alt_outlined,
                        size: w * 0.032,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: w * 0.01),
                      Expanded(
                        child: Text(
                          (cartItem.notes?.trim().isNotEmpty ?? false)
                              ? cartItem.notes!
                              : 'Add note',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: w * 0.028,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: w * 0.015),
                Row(
                  children: [
                    Text(
                      cartItem.addonsUnitTotal > 0
                          ? 'GHS ${(cartItem.price + cartItem.addonsUnitTotal).toStringAsFixed(2)} each'
                          : 'GHS ${cartItem.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: w * 0.033,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    // Quantity control
                    _QuantityControl(
                      quantity: cartItem.quantity,
                      onDecrease: onDecrease,
                      onIncrease: onIncrease,
                    ),
                  ],
                ),
                SizedBox(height: w * 0.012),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GHS ${cartItem.lineTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    GestureDetector(
                      onTap: onRemove,
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                        size: w * 0.05,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Row(
      children: [
        _CircleBtn(
          icon: Icons.remove,
          onTap: onDecrease,
          filled: false,
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
        _CircleBtn(
          icon: Icons.add,
          onTap: onIncrease,
          filled: true,
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _CircleBtn({required this.icon, required this.onTap, required this.filled});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w * 0.07,
        height: w * 0.07,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: filled ? null : Border.all(color: AppColors.border, width: 1.2),
        ),
        child: Icon(
          icon,
          size: w * 0.038,
          color: filled ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}
