import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/presentation/providers/cart_provider.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/presentation/widgets/cart_item_tile.dart';

class CartView extends ConsumerWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.sizeOf(context).width;
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    if (cart.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(title: const Text('Your Cart')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart_outlined,
                  size: w * 0.2, color: AppColors.textHint),
              SizedBox(height: w * 0.04),
              Text(
                'Your cart is empty',
                style: TextStyle(
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: w * 0.015),
              Text(
                'Add items from a restaurant to get started',
                style: TextStyle(
                  fontSize: w * 0.033,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: w * 0.06),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Browse Restaurants'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear cart?'),
                  content: const Text(
                      'This will remove all items from your cart.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        notifier.clear();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                w * 0.05, w * 0.03, w * 0.05, w * 0.04,
              ),
              children: [
                // ── Restaurant info header ──
                Container(
                  padding: EdgeInsets.all(w * 0.04),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(w * 0.03),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(w * 0.02),
                        child: SizedBox(
                          width: w * 0.14,
                          height: w * 0.14,
                          child: Image.network(
                            cart.restaurantImageUrl ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: AppColors.shimmerBase,
                              child: const Icon(Icons.restaurant,
                                  color: AppColors.textHint),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: w * 0.03),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cart.restaurantName ?? '',
                            style: TextStyle(
                              fontSize: w * 0.04,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${cart.totalItems} item${cart.totalItems > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: w * 0.032,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: w * 0.04),

                // ── Cart items ──
                ...cart.items.map((ci) => CartItemTile(
                      cartItem: ci,
                      onIncrease: () =>
                          notifier.updateQuantity(ci.item.id, ci.quantity + 1),
                      onDecrease: () =>
                          notifier.updateQuantity(ci.item.id, ci.quantity - 1),
                      onRemove: () => notifier.removeItem(ci.item.id),
                    )),

                SizedBox(height: w * 0.02),

                // ── Special instructions ──
                Container(
                  padding: EdgeInsets.all(w * 0.04),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(w * 0.035),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.note_alt_outlined,
                          color: AppColors.textSecondary),
                      SizedBox(width: w * 0.025),
                      Text(
                        'Add note for restaurant',
                        style: TextStyle(
                          fontSize: w * 0.035,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right,
                          color: AppColors.textHint, size: w * 0.05),
                    ],
                  ),
                ),

                SizedBox(height: w * 0.05),

                // ── Order summary ──
                Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: w * 0.042,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: w * 0.03),
                _SummaryRow(
                    label: 'Subtotal',
                    value: 'GHS ${cart.subtotal.toStringAsFixed(2)}'),
                _SummaryRow(
                    label: 'Delivery fee',
                    value: 'GHS ${cart.deliveryFee.toStringAsFixed(2)}'),
                _SummaryRow(
                    label: 'Service fee (5%)',
                    value: 'GHS ${cart.serviceFee.toStringAsFixed(2)}'),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: w * 0.02),
                  child: const Divider(color: AppColors.divider),
                ),
                _SummaryRow(
                  label: 'Total',
                  value: 'GHS ${cart.total.toStringAsFixed(2)}',
                  isBold: true,
                ),
              ],
            ),
          ),

          // ── Checkout button ──
          Container(
            padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.06),
            decoration: const BoxDecoration(
              color: AppColors.scaffold,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: ElevatedButton(
              onPressed: () => context.push(AppRoutes.checkout),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, w * 0.13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(w * 0.035),
                ),
              ),
              child: Text(
                'Proceed to Checkout · GHS ${cart.total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: w * 0.038,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.012),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? w * 0.04 : w * 0.035,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color:
                  isBold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? w * 0.042 : w * 0.035,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isBold ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
