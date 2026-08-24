import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/presentation/viewmodels/cart_viewmodel.dart';
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
              HapticFeedback.mediumImpact();
              CustomDialog.showConfirmation(
                context: context,
                title: 'Clear cart?',
                subtitle: 'This will remove all items from your cart.',
                confirmText: 'Clear',
                onConfirm: notifier.clear,
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
                      onIncrease: () {
                        HapticFeedback.lightImpact();
                        notifier.updateQuantity(ci.item.id, ci.quantity + 1);
                      },
                      onDecrease: () {
                        HapticFeedback.lightImpact();
                        notifier.updateQuantity(ci.item.id, ci.quantity - 1);
                      },
                      onRemove: () => notifier.removeItem(ci.item.id),
                    )),

                SizedBox(height: w * 0.02),

                // ── Special instructions (functional) ──
                _SpecialInstructionsSection(
                  currentNote: cart.specialInstructions,
                  onNoteSaved: notifier.updateSpecialInstructions,
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
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.push(AppRoutes.checkout);
              },
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

// ─── Special Instructions Section ─────────────────────────────────────────

/// An interactive section that displays the current restaurant-level note
/// and opens a modal dialog for editing.
class _SpecialInstructionsSection extends StatelessWidget {
  final String currentNote;
  final ValueChanged<String> onNoteSaved;

  const _SpecialInstructionsSection({
    required this.currentNote,
    required this.onNoteSaved,
  });

  void _openNoteDialog(BuildContext context) {
    final controller = TextEditingController(text: currentNote);
    final w = MediaQuery.sizeOf(context).width;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            w * 0.05, w * 0.05, w * 0.05, w * 0.06,
          ),
          decoration: BoxDecoration(
            color: AppColors.scaffold,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(w * 0.06),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle bar ──
              Center(
                child: Container(
                  width: w * 0.1,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: w * 0.04),
              Text(
                'Note for Restaurant',
                style: TextStyle(
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: w * 0.01),
              Text(
                'Allergies, special requests, or preparation notes',
                style: TextStyle(
                  fontSize: w * 0.032,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: w * 0.04),
              TextField(
                controller: controller,
                maxLines: 3,
                maxLength: 500,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'e.g. No onions, extra spicy, nut allergy...',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(w * 0.03),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(w * 0.03),
                    borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5,
                    ),
                  ),
                ),
              ),
              SizedBox(height: w * 0.04),
              Row(
                children: [
                  // Clear button
                  if (currentNote.isNotEmpty)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          onNoteSaved('');
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Clear Note'),
                      ),
                    ),
                  if (currentNote.isNotEmpty) SizedBox(width: w * 0.03),
                  // Save button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onNoteSaved(controller.text);
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, w * 0.12),
                      ),
                      child: const Text('Save Note'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final hasNote = currentNote.trim().isNotEmpty;

    return GestureDetector(
      onTap: () => _openNoteDialog(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(w * 0.04),
        decoration: BoxDecoration(
          color: hasNote
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.card,
          borderRadius: BorderRadius.circular(w * 0.035),
          border: Border.all(
            color: hasNote ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasNote ? Icons.note_alt_rounded : Icons.note_alt_outlined,
              color: hasNote ? AppColors.primary : AppColors.textSecondary,
            ),
            SizedBox(width: w * 0.025),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasNote ? 'Restaurant note' : 'Add note for restaurant',
                    style: TextStyle(
                      fontSize: w * 0.035,
                      fontWeight: hasNote ? FontWeight.w600 : FontWeight.w400,
                      color: hasNote
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (hasNote) ...[
                    SizedBox(height: w * 0.005),
                    Text(
                      currentNote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: w * 0.03,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              hasNote ? Icons.edit_rounded : Icons.chevron_right,
              color: hasNote ? AppColors.primary : AppColors.textHint,
              size: w * 0.05,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Summary Row ──────────────────────────────────────────────────────────

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
