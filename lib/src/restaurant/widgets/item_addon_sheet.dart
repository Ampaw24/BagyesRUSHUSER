import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/restaurant/models/addon.dart';
import 'package:bagyesrushappusernew/src/restaurant/models/menu_item.dart';

// ─── Result ───────────────────────────────────────────────────────────────────

class AddonSelectionResult {
  final int quantity;
  final List<SelectedAddon> selectedAddons;

  const AddonSelectionResult({
    required this.quantity,
    required this.selectedAddons,
  });
}

// ─── Sheet ────────────────────────────────────────────────────────────────────

class ItemAddonSheet extends StatefulWidget {
  final MenuItem item;
  final int initialQuantity;

  const ItemAddonSheet({
    super.key,
    required this.item,
    this.initialQuantity = 1,
  });

  static Future<AddonSelectionResult?> show(
    BuildContext context,
    MenuItem item, {
    int initialQuantity = 1,
  }) {
    return showModalBottomSheet<AddonSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ItemAddonSheet(
        item: item,
        initialQuantity: initialQuantity,
      ),
    );
  }

  @override
  State<ItemAddonSheet> createState() => _ItemAddonSheetState();
}

class _ItemAddonSheetState extends State<ItemAddonSheet> {
  // groupId → optionId → quantity chosen by user (0 means not selected)
  final Map<String, Map<String, int>> _quantities = {};
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = max(widget.item.minimumOrderQty, widget.initialQuantity);
    for (final group in widget.item.addonGroups) {
      _quantities[group.id] = {};
    }
  }

  int _groupTotal(String groupId) =>
      (_quantities[groupId] ?? {}).values.fold(0, (s, q) => s + q);

  double get _addonSubtotal {
    double total = 0;
    for (final group in widget.item.addonGroups) {
      final groupQtys = _quantities[group.id] ?? {};
      for (final option in group.options) {
        final qty = groupQtys[option.id] ?? 0;
        total += option.additionalPrice * qty;
      }
    }
    return total;
  }

  double get _lineTotal =>
      (widget.item.price + _addonSubtotal) * _quantity;

  bool get _isValid {
    for (final group in widget.item.addonGroups) {
      if (!group.isRequired) continue;
      if (_groupTotal(group.id) < 1) return false;
    }
    return true;
  }

  List<String> get _unsatisfiedGroups => widget.item.addonGroups
      .where((g) => g.isRequired && _groupTotal(g.id) < 1)
      .map((g) => g.name)
      .toList();

  void _setOptionQty(String groupId, String optionId, int qty) {
    setState(() {
      _quantities[groupId] ??= {};
      if (qty <= 0) {
        _quantities[groupId]!.remove(optionId);
      } else {
        _quantities[groupId]![optionId] = qty;
      }
    });
  }

  void _confirm() {
    final selected = <SelectedAddon>[];
    for (final group in widget.item.addonGroups) {
      final groupQtys = _quantities[group.id] ?? {};
      for (final option in group.options.where((o) => o.isAvailable)) {
        final qty = groupQtys[option.id] ?? 0;
        if (qty > 0) {
          selected.add(SelectedAddon(
            groupId: group.id,
            groupName: group.name,
            optionId: option.id,
            optionName: option.name,
            additionalPrice: option.additionalPrice,
            quantity: qty,
          ));
        }
      }
    }
    Navigator.of(context).pop(
      AddonSelectionResult(quantity: _quantity, selectedAddons: selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: AppColors.scaffold,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(w * 0.06)),
        ),
        child: Column(
          children: [
            // ── Drag handle ──
            Padding(
              padding: EdgeInsets.only(top: w * 0.035, bottom: w * 0.02),
              child: Container(
                width: w * 0.1,
                height: w * 0.01,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(w * 0.005),
                ),
              ),
            ),

            // ── Scrollable content ──
            Expanded(
              child: ListView(
                controller: controller,
                padding: EdgeInsets.zero,
                children: [
                  // Item image
                  SizedBox(
                    height: w * 0.5,
                    width: double.infinity,
                    child: Image.network(
                      widget.item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.shimmerBase,
                        child: const Icon(
                          Icons.fastfood,
                          color: AppColors.textHint,
                          size: 48,
                        ),
                      ),
                    ),
                  ),

                  // Item name + base price
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      w * 0.05, w * 0.04, w * 0.05, 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.name,
                          style: TextStyle(
                            fontSize: w * 0.048,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: w * 0.01),
                        Text(
                          widget.item.description,
                          style: TextStyle(
                            fontSize: w * 0.032,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: w * 0.015),
                        Text(
                          'GHS ${widget.item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: w * 0.042,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: w * 0.04),
                  const Divider(height: 1),

                  // ── Addon groups ──
                  ...widget.item.addonGroups.map(
                    (group) => _AddonGroupSection(
                      group: group,
                      quantities: _quantities[group.id] ?? {},
                      onSetQty: (optionId, qty) =>
                          _setOptionQty(group.id, optionId, qty),
                      w: w,
                    ),
                  ),

                  SizedBox(height: w * 0.02),
                  const Divider(height: 1),

                  // ── Quantity stepper (meal quantity) ──
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.05,
                      vertical: w * 0.04,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: w * 0.038,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        _QtyBtn(
                          icon: Icons.remove,
                          onTap: () {
                            if (_quantity > widget.item.minimumOrderQty) {
                              setState(() => _quantity--);
                            }
                          },
                          enabled: _quantity > widget.item.minimumOrderQty,
                          w: w,
                        ),
                        SizedBox(width: w * 0.04),
                        Text(
                          '$_quantity',
                          style: TextStyle(
                            fontSize: w * 0.042,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(width: w * 0.04),
                        _QtyBtn(
                          icon: Icons.add,
                          onTap: () {
                            final max = widget.item.maximumOrderQty ?? 99;
                            if (_quantity < max) setState(() => _quantity++);
                          },
                          enabled: _quantity < (widget.item.maximumOrderQty ?? 99),
                          w: w,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: w * 0.02),
                ],
              ),
            ),

            // ── Bottom confirm area ──
            Container(
              padding: EdgeInsets.fromLTRB(
                w * 0.05,
                w * 0.03,
                w * 0.05,
                w * 0.06 + MediaQuery.paddingOf(context).bottom,
              ),
              decoration: BoxDecoration(
                color: AppColors.scaffold,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.8),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isValid) ...[
                    Text(
                      'Please choose: ${_unsatisfiedGroups.join(', ')}',
                      style: TextStyle(
                        fontSize: w * 0.03,
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: w * 0.025),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: w * 0.135,
                    child: ElevatedButton(
                      onPressed: _isValid ? _confirm : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Add to Cart',
                            style: TextStyle(
                              fontSize: w * 0.042,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: w * 0.03),
                          Text(
                            '· GHS ${_lineTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: w * 0.038,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Addon group section ──────────────────────────────────────────────────────

class _AddonGroupSection extends StatelessWidget {
  final AddonGroup group;
  final Map<String, int> quantities; // optionId → qty
  final void Function(String optionId, int qty) onSetQty;
  final double w;

  const _AddonGroupSection({
    required this.group,
    required this.quantities,
    required this.onSetQty,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    final totalSelected =
        quantities.values.fold(0, (s, q) => s + q);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        Padding(
          padding: EdgeInsets.fromLTRB(
              w * 0.05, w * 0.04, w * 0.05, w * 0.015),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: TextStyle(
                        fontSize: w * 0.04,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: w * 0.005),
                    Text(
                      group.isRequired ? 'Required' : 'Optional',
                      style: TextStyle(
                        fontSize: w * 0.028,
                        color: group.isRequired
                            ? AppColors.primary
                            : AppColors.textHint,
                        fontWeight: group.isRequired
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (totalSelected > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.025,
                    vertical: w * 0.006,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalSelected selected',
                    style: TextStyle(
                      fontSize: w * 0.026,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Options — each with its own qty stepper
        ...group.options
            .where((o) => o.isAvailable)
            .map((option) {
          final qty = quantities[option.id] ?? 0;
          final isSelected = qty > 0;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.04)
                  : null,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.05,
              vertical: w * 0.028,
            ),
            child: Row(
              children: [
                // Option name + price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.name,
                        style: TextStyle(
                          fontSize: w * 0.036,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (option.additionalPrice > 0)
                        Text(
                          '+GHS ${option.additionalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: w * 0.03,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        )
                      else
                        Text(
                          'Free',
                          style: TextStyle(
                            fontSize: w * 0.03,
                            color: AppColors.textHint,
                          ),
                        ),
                    ],
                  ),
                ),

                // Qty stepper: [−] N [+]
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _OptionQtyBtn(
                      icon: Icons.remove,
                      enabled: qty > 0,
                      onTap: () => onSetQty(option.id, qty - 1),
                      w: w,
                      filled: false,
                    ),
                    SizedBox(
                      width: w * 0.09,
                      child: Text(
                        '$qty',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: w * 0.04,
                          fontWeight: FontWeight.w700,
                          color: qty > 0
                              ? AppColors.primary
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                    _OptionQtyBtn(
                      icon: Icons.add,
                      enabled: true,
                      onTap: () => onSetQty(option.id, qty + 1),
                      w: w,
                      filled: true,
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        SizedBox(height: w * 0.02),
        const Divider(height: 1),
      ],
    );
  }
}

// ─── Small qty button for per-option stepper ──────────────────────────────────

class _OptionQtyBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final double w;
  final bool filled;

  const _OptionQtyBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.w,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: w * 0.08,
        height: w * 0.08,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled
              ? (enabled ? AppColors.primary : AppColors.border)
              : Colors.transparent,
          border: filled
              ? null
              : Border.all(
                  color: enabled ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
        ),
        child: Icon(
          icon,
          size: w * 0.036,
          color: filled
              ? Colors.white
              : (enabled ? AppColors.primary : AppColors.border),
        ),
      ),
    );
  }
}

// ─── Meal-level qty button ────────────────────────────────────────────────────

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final double w;

  const _QtyBtn({
    required this.icon,
    required this.onTap,
    required this.enabled,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: w * 0.09,
        height: w * 0.09,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? AppColors.primary : AppColors.border,
        ),
        child: Icon(
          icon,
          size: w * 0.04,
          color: enabled ? Colors.white : AppColors.textHint,
        ),
      ),
    );
  }
}
