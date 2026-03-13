import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/presentation/providers/cart_provider.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/presentation/providers/orders_provider.dart';

class CheckoutView extends ConsumerStatefulWidget {
  const CheckoutView({super.key});

  @override
  ConsumerState<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends ConsumerState<CheckoutView> {
  final _addressController = TextEditingController(
    text: '12 Osu Badu St, Accra',
  );
  final _instructionsController = TextEditingController();
  String _selectedPayment = 'Mobile Money';
  bool _isPlacing = false;

  static const _paymentMethods = [
    'Mobile Money',
    'Visa / Mastercard',
    'Cash on Delivery',
  ];

  @override
  void dispose() {
    _addressController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    setState(() => _isPlacing = true);
    try {
      final order = await ref.read(ordersProvider.notifier).placeOrder(
            cart: cart,
            deliveryAddress: _addressController.text.trim(),
            deliveryInstructions: _instructionsController.text.trim().isEmpty
                ? null
                : _instructionsController.text.trim(),
            paymentMethod: _selectedPayment,
          );
      ref.read(cartProvider.notifier).clear();
      if (mounted) {
        context.go(AppRoutes.trackOrder, extra: order.id);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to place order. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                w * 0.05, w * 0.03, w * 0.05, w * 0.04,
              ),
              children: [
                // ── Step 1: Delivery address ──
                _SectionHeader(
                  number: '1',
                  title: 'Delivery Address',
                ),
                SizedBox(height: w * 0.03),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: 'Enter delivery address',
                    prefixIcon: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: w * 0.025),
                TextField(
                  controller: _instructionsController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Delivery instructions (optional)',
                    prefixIcon: const Icon(
                      Icons.note_alt_outlined,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                SizedBox(height: w * 0.055),

                // ── Step 2: Payment method ──
                _SectionHeader(number: '2', title: 'Payment Method'),
                SizedBox(height: w * 0.03),
                ..._paymentMethods.map((method) => _PaymentOption(
                      method: method,
                      isSelected: _selectedPayment == method,
                      onTap: () =>
                          setState(() => _selectedPayment = method),
                    )),

                SizedBox(height: w * 0.055),

                // ── Step 3: Order summary ──
                _SectionHeader(number: '3', title: 'Order Summary'),
                SizedBox(height: w * 0.03),
                Container(
                  padding: EdgeInsets.all(w * 0.04),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(w * 0.035),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      ...cart.items.map((ci) => Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: w * 0.012),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: w * 0.02,
                                    vertical: w * 0.005,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${ci.quantity}×',
                                    style: TextStyle(
                                      fontSize: w * 0.03,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                SizedBox(width: w * 0.025),
                                Expanded(
                                  child: Text(
                                    ci.item.name,
                                    style: TextStyle(
                                      fontSize: w * 0.033,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  'GHS ${ci.lineTotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: w * 0.033,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const Divider(color: AppColors.divider),
                      _TotalRow(
                          label: 'Subtotal',
                          value: cart.subtotal),
                      _TotalRow(
                          label: 'Delivery fee',
                          value: cart.deliveryFee),
                      _TotalRow(
                          label: 'Service fee',
                          value: cart.serviceFee),
                      SizedBox(height: w * 0.01),
                      _TotalRow(
                        label: 'Total',
                        value: cart.total,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Place order button ──
          Container(
            padding: EdgeInsets.fromLTRB(
                w * 0.05, w * 0.03, w * 0.05, w * 0.06),
            decoration: const BoxDecoration(
              color: AppColors.scaffold,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: ElevatedButton(
              onPressed: _isPlacing ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, w * 0.13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(w * 0.035),
                ),
              ),
              child: _isPlacing
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Place Order · GHS ${cart.total.toStringAsFixed(2)}',
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

// ─── Helper widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String number;
  final String title;

  const _SectionHeader({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Row(
      children: [
        Container(
          width: w * 0.07,
          height: w * 0.07,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: w * 0.035,
            ),
          ),
        ),
        SizedBox(width: w * 0.025),
        Text(
          title,
          style: TextStyle(
            fontSize: w * 0.042,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String method;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  static IconData _icon(String method) {
    if (method.contains('Mobile')) return Icons.phone_android_rounded;
    if (method.contains('Visa')) return Icons.credit_card_rounded;
    return Icons.money_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.only(bottom: w * 0.025),
        padding: EdgeInsets.all(w * 0.04),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.07)
              : AppColors.card,
          borderRadius: BorderRadius.circular(w * 0.03),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(_icon(method),
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: w * 0.055),
            SizedBox(width: w * 0.03),
            Expanded(
              child: Text(
                method,
                style: TextStyle(
                  fontSize: w * 0.037,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.01),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: w * 0.033,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: isBold
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
          Text(
            'GHS ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isBold ? w * 0.038 : w * 0.033,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isBold ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
