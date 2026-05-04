import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/core/widgets/map_location_picker_sheet.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/presentation/viewmodels/cart_viewmodel.dart';
import 'package:bagyesrushappusernew/features/consumer/checkout/domain/entities/checkout_model.dart';
import 'package:bagyesrushappusernew/features/consumer/checkout/presentation/states/checkout_state.dart';
import 'package:bagyesrushappusernew/features/consumer/checkout/presentation/viewmodels/checkout_viewmodel.dart';

class CheckoutView extends ConsumerStatefulWidget {
  const CheckoutView({super.key});

  @override
  ConsumerState<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends ConsumerState<CheckoutView> {
  // Address starts empty — user MUST provide an address before placing order.
  final _addressController = TextEditingController();
  final _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Sync address controller with checkout state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(checkoutProvider);
      final form = switch (state) {
        CheckoutIdle(:final form) => form,
        CheckoutPlacing(:final form) => form,
        CheckoutError(:final form) => form,
        _ => const CheckoutForm(),
      };
      if (form.deliveryAddress.isNotEmpty) {
        _addressController.text = form.deliveryAddress;
      }
      if (form.deliveryInstructions.isNotEmpty) {
        _instructionsController.text = form.deliveryInstructions;
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final address =
          _buildAddressString(placemarks.isNotEmpty ? placemarks.first : null, pos);
      _addressController.text = address;
      ref.read(checkoutProvider.notifier).updateAddress(address);
    } catch (_) {}
  }

  void _openMapPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MapLocationPickerSheet(
        title: 'Delivery Address',
        onConfirm: (LatLng _, String address) {
          _addressController.text = address;
          ref.read(checkoutProvider.notifier).updateAddress(address);
          Navigator.pop(context);
        },
      ),
    );
  }

  String _buildAddressString(Placemark? p, Position pos) {
    if (p != null) {
      final street = p.street?.isNotEmpty == true ? p.street : null;
      final sub = p.subLocality?.isNotEmpty == true ? p.subLocality : null;
      final locality = p.locality?.isNotEmpty == true ? p.locality : null;
      if (street != null && locality != null) return '$street, $locality';
      if (street != null) return street;
      if (sub != null && locality != null) return '$sub, $locality';
      if (locality != null) return locality;
    }
    return '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cart = ref.watch(cartProvider);
    final checkoutState = ref.watch(checkoutProvider);

    // React to success → navigate to tracking
    ref.listen<CheckoutState>(checkoutProvider, (_, next) {
      if (next is CheckoutSuccess) {
        context.go(AppRoutes.trackOrder, extra: next.orderId);
      } else if (next is CheckoutError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message)),
        );
        ref.read(checkoutProvider.notifier).resetAfterError();
      }
    });

    final isPlacing = checkoutState is CheckoutPlacing;
    final form = switch (checkoutState) {
      CheckoutIdle(:final form) => form,
      CheckoutPlacing(:final form) => form,
      CheckoutError(:final form) => form,
      _ => const CheckoutForm(),
    };

    final hasValidAddress = form.deliveryAddress.trim().length >= 5;

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
                _SectionHeader(number: '1', title: 'Delivery Address'),
                SizedBox(height: w * 0.03),

                // Address selector tile
                _AddressSelectorTile(
                  controller: _addressController,
                  hasValidAddress: hasValidAddress,
                  onChanged: (v) =>
                      ref.read(checkoutProvider.notifier).updateAddress(v),
                  onUseCurrentLocation: _useCurrentLocation,
                  onPickOnMap: _openMapPicker,
                ),

                SizedBox(height: w * 0.025),
                TextField(
                  controller: _instructionsController,
                  maxLines: 2,
                  onChanged: (v) => ref
                      .read(checkoutProvider.notifier)
                      .updateInstructions(v),
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

                // ── Cart note preview ──
                if (cart.hasSpecialInstructions) ...[
                  SizedBox(height: w * 0.025),
                  Container(
                    padding: EdgeInsets.all(w * 0.035),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(w * 0.025),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.note_alt_rounded,
                            color: AppColors.primary, size: w * 0.045),
                        SizedBox(width: w * 0.02),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Restaurant note',
                                style: TextStyle(
                                  fontSize: w * 0.03,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                cart.specialInstructions,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: w * 0.028,
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: w * 0.055),

                // ── Step 2: Payment method ──
                _SectionHeader(number: '2', title: 'Payment Method'),
                SizedBox(height: w * 0.03),
                ...PaymentMethod.values.map((method) => _PaymentOption(
                      method: method,
                      isSelected: form.paymentMethod == method,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(checkoutProvider.notifier)
                            .selectPaymentMethod(method);
                      },
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
                      _TotalRow(label: 'Subtotal', value: cart.subtotal),
                      _TotalRow(
                          label: 'Delivery fee', value: cart.deliveryFee),
                      _TotalRow(label: 'Service fee', value: cart.serviceFee),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Address validation warning
                if (!hasValidAddress)
                  Padding(
                    padding: EdgeInsets.only(bottom: w * 0.025),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppColors.warning, size: w * 0.045),
                        SizedBox(width: w * 0.02),
                        Expanded(
                          child: Text(
                            'Please enter a valid delivery address to continue',
                            style: TextStyle(
                              fontSize: w * 0.03,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ElevatedButton(
                  onPressed: (isPlacing || !hasValidAddress)
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          ref.read(checkoutProvider.notifier).placeOrder(cart);
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, w * 0.13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(w * 0.035),
                    ),
                  ),
                  child: isPlacing
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Address Selector Tile ────────────────────────────────────────────────

class _AddressSelectorTile extends StatelessWidget {
  final TextEditingController controller;
  final bool hasValidAddress;
  final ValueChanged<String> onChanged;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onPickOnMap;

  const _AddressSelectorTile({
    required this.controller,
    required this.hasValidAddress,
    required this.onChanged,
    required this.onUseCurrentLocation,
    required this.onPickOnMap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(
          color: hasValidAddress
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
          width: hasValidAddress ? 1.5 : 0.8,
        ),
      ),
      child: Column(
        children: [
          // ── Address text field ──
          TextField(
            controller: controller,
            onChanged: onChanged,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Enter your delivery address',
              prefixIcon: Icon(
                Icons.location_on_rounded,
                color: hasValidAddress ? AppColors.success : AppColors.primary,
              ),
              suffixIcon: hasValidAddress
                  ? Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: w * 0.05)
                  : null,
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: w * 0.04,
                vertical: w * 0.04,
              ),
            ),
          ),

          // ── Quick actions ──
          Container(
            padding: EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, w * 0.03),
            child: Row(
              children: [
                _QuickAddressChip(
                  icon: Icons.my_location_rounded,
                  label: 'Use current location',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onUseCurrentLocation();
                  },
                ),
                SizedBox(width: w * 0.02),
                _QuickAddressChip(
                  icon: Icons.map_rounded,
                  label: 'Pick on map',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onPickOnMap();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAddressChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAddressChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.025,
          vertical: w * 0.015,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(w * 0.02),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: w * 0.035, color: AppColors.primary),
            SizedBox(width: w * 0.015),
            Text(
              label,
              style: TextStyle(
                fontSize: w * 0.028,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
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
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  static IconData _icon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mobileMoney:
        return Icons.phone_android_rounded;
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
      case PaymentMethod.cashOnDelivery:
        return Icons.money_rounded;
    }
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
                method.label,
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
