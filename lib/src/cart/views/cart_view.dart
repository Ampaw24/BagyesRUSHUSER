import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:bagyesrushappusernew/src/cart/models/cart_item_model.dart';
import 'package:bagyesrushappusernew/src/cart/viewmodels/cart_state.dart';
import 'package:bagyesrushappusernew/src/cart/viewmodels/cart_viewmodel.dart';
import 'package:bagyesrushappusernew/src/cart/views/widgets/cart_item_tile.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  CartViewModel? _vm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm = context.read<CartViewModel>();
      _vm!.addListener(_onCartChanged);
    });
  }

  @override
  void dispose() {
    _vm?.removeListener(_onCartChanged);
    super.dispose();
  }

  /// A mutation (quantity change, remove, note edit) failed — the cart
  /// already rolled back to its last known-good state, this just surfaces
  /// why.
  void _onCartChanged() {
    final message = _vm?.errorMessage;
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    _vm!.clearError();
  }

  void _editNote(BuildContext context, CartItemModel item) {
    final controller = TextEditingController(text: item.notes ?? '');
    final w = MediaQuery.sizeOf(context).width;
    final vm = context.read<CartViewModel>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.05, w * 0.05, w * 0.06),
          decoration: BoxDecoration(
            color: AppColors.scaffold,
            borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.06)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  'Note for ${item.name}',
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
                  maxLength: 255,
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
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: w * 0.04),
                SizedBox(
                  width: double.infinity,
                  height: w * 0.12,
                  child: ElevatedButton(
                    onPressed: () {
                      vm.updateItemNotes(item.id, controller.text);
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Save Note'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final vm = context.watch<CartViewModel>();
    final state = vm.state;

    if (state is CartLoading || state is CartInitial) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (state is CartError) {
      return Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(title: const Text('Your Cart')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(w * 0.08),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: w * 0.14,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: w * 0.04),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: w * 0.035,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: w * 0.04),
                ElevatedButton(
                  onPressed: () => vm.refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final cart = vm.cart;

    if (cart == null || cart.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(title: const Text('Your Cart')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: w * 0.2,
                color: AppColors.textHint,
              ),
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
                onConfirm: vm.clearCart,
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
                w * 0.05,
                w * 0.03,
                w * 0.05,
                w * 0.04,
              ),
              children: [
                // ── Vendor info header ──
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
                          child: GestureDetector(
                            onTap: () {
                              // Handle vendor image tap
                              print(
                                'Vendor image tapped: ${cart.vendorImageUrl}',
                              );
                            },
                            child: Image.network(
                              cart.vendorImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: AppColors.shimmerBase,
                                child: const Icon(
                                  Icons.restaurant,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: w * 0.03),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cart.vendorName,
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
                ...cart.items.map(
                  (ci) => CartItemTile(
                    cartItem: ci,
                    onIncrease: () {
                      HapticFeedback.lightImpact();
                      vm.updateItemQuantity(ci.id, ci.quantity + 1);
                    },
                    onDecrease: () {
                      HapticFeedback.lightImpact();
                      vm.updateItemQuantity(ci.id, ci.quantity - 1);
                    },
                    onRemove: () => vm.removeItem(ci.id),
                    onEditNote: () => _editNote(context, ci),
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
                  value: 'GHS ${cart.subtotal.toStringAsFixed(2)}',
                ),
                if (cart.deliveryFee != null)
                  _SummaryRow(
                    label: 'Delivery fee',
                    value: 'GHS ${cart.deliveryFee!.toStringAsFixed(2)}',
                  ),
                if (cart.serviceFee != null && cart.serviceFee! > 0)
                  _SummaryRow(
                    label: 'Service fee',
                    value: 'GHS ${cart.serviceFee!.toStringAsFixed(2)}',
                  ),
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
            padding: EdgeInsets.fromLTRB(
              w * 0.05,
              w * 0.03,
              w * 0.05,
              w * 0.06,
            ),
            decoration: const BoxDecoration(
              color: AppColors.scaffold,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: ElevatedButton(
              onPressed: vm.isMutating
                  ? null
                  : () {
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
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
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
