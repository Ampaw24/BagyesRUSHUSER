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

// ─── Selection rules ──────────────────────────────────────────────────────────

extension AddonGroupSelectionRules on AddonGroup {
  List<AddonOption> get availableOptions =>
      options.where((o) => o.isAvailable).toList();

  /// Radio buttons when the customer may pick only one of several options.
  /// A lone option is always a checkbox so it reads as a simple "add this?".
  bool get isSingleChoice => maxSelections <= 1 && availableOptions.length > 1;

  /// How many options the customer must pick before the item can be added.
  int get requiredCount => max(minSelections, isRequired ? 1 : 0);

  /// Upper bound on picks, never more than the options actually on offer.
  int get selectionLimit => max(1, min(maxSelections, availableOptions.length));

  /// Subtitle under the group name, e.g. "Required · Choose 1".
  String get selectionHint {
    final prefix = requiredCount > 0 ? 'Required' : 'Optional';
    if (isSingleChoice) return '$prefix · Choose 1';
    if (selectionLimit >= availableOptions.length) {
      return requiredCount > 1
          ? '$prefix · Choose at least $requiredCount'
          : '$prefix · Choose any';
    }
    if (requiredCount > 1) {
      return '$prefix · Choose $requiredCount–$selectionLimit';
    }
    return '$prefix · Choose up to $selectionLimit';
  }
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
      builder: (_) =>
          ItemAddonSheet(item: item, initialQuantity: initialQuantity),
    );
  }

  @override
  State<ItemAddonSheet> createState() => _ItemAddonSheetState();
}

class _ItemAddonSheetState extends State<ItemAddonSheet> {
  // groupId → ids of the options ticked in that group
  final Map<String, Set<String>> _selected = {};
  late int _quantity;

  List<AddonGroup> get _groups => widget.item.addonGroups
      .where((g) => g.availableOptions.isNotEmpty)
      .toList();

  @override
  void initState() {
    super.initState();
    _quantity = max(widget.item.minimumOrderQty, widget.initialQuantity);
    for (final group in widget.item.addonGroups) {
      _selected[group.id] = {};
    }
  }

  int get _maxQuantity => widget.item.maximumOrderQty ?? 99;

  double get _addonSubtotal {
    double total = 0;
    for (final group in _groups) {
      final picked = _selected[group.id] ?? const {};
      for (final option in group.availableOptions) {
        if (picked.contains(option.id)) total += option.additionalPrice;
      }
    }
    return total;
  }

  double get _lineTotal => (widget.item.price + _addonSubtotal) * _quantity;

  List<String> get _unsatisfiedGroups => _groups
      .where((g) => (_selected[g.id]?.length ?? 0) < g.requiredCount)
      .map((g) => g.name)
      .toList();

  bool get _isValid => _unsatisfiedGroups.isEmpty;

  void _toggleOption(AddonGroup group, AddonOption option) {
    setState(() {
      final picked = _selected.putIfAbsent(group.id, () => {});
      if (picked.contains(option.id)) {
        // A required single-choice group always keeps one pick — tapping
        // the chosen radio again does nothing rather than clearing it.
        if (group.isSingleChoice && group.requiredCount > 0) return;
        picked.remove(option.id);
      } else if (group.isSingleChoice) {
        picked
          ..clear()
          ..add(option.id);
      } else if (picked.length < group.selectionLimit) {
        picked.add(option.id);
      }
    });
  }

  void _confirm() {
    final selected = <SelectedAddon>[];
    for (final group in _groups) {
      final picked = _selected[group.id] ?? const {};
      for (final option in group.availableOptions) {
        if (!picked.contains(option.id)) continue;
        selected.add(
          SelectedAddon(
            groupId: group.id,
            groupName: group.name,
            optionId: option.id,
            optionName: option.name,
            additionalPrice: option.additionalPrice,
          ),
        );
      }
    }
    Navigator.of(
      context,
    ).pop(AddonSelectionResult(quantity: _quantity, selectedAddons: selected));
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.06)),
        child: Container(
          color: AppColors.surfaceVariant,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      controller: controller,
                      padding: EdgeInsets.only(bottom: w * 0.04),
                      children: [
                        _ItemHeader(item: widget.item, w: w),
                        ..._groups.map(
                          (group) => _AddonGroupCard(
                            group: group,
                            selected: _selected[group.id] ?? const {},
                            onToggle: (option) => _toggleOption(group, option),
                            w: w,
                          ),
                        ),
                      ],
                    ),

                    // ── Close button ──
                    Positioned(
                      top: w * 0.04,
                      right: w * 0.04,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: EdgeInsets.all(w * 0.022),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: w * 0.05,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _BottomBar(
                quantity: _quantity,
                canDecrement: _quantity > widget.item.minimumOrderQty,
                canIncrement: _quantity < _maxQuantity,
                onDecrement: () => setState(() => _quantity--),
                onIncrement: () => setState(() => _quantity++),
                lineTotal: _lineTotal,
                unsatisfiedGroups: _unsatisfiedGroups,
                onConfirm: _isValid ? _confirm : null,
                w: w,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Item header ──────────────────────────────────────────────────────────────

class _ItemHeader extends StatelessWidget {
  final MenuItem item;
  final double w;

  const _ItemHeader({required this.item, required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(bottom: w * 0.025),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: w * 0.55,
            width: double.infinity,
            child: Image.network(
              item.imageUrl,
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
          Padding(
            padding: EdgeInsets.fromLTRB(
              w * 0.05,
              w * 0.04,
              w * 0.05,
              w * 0.05,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: w * 0.052,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  SizedBox(height: w * 0.012),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: w * 0.033,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                SizedBox(height: w * 0.02),
                Text(
                  'GHS ${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: w * 0.044,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
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

// ─── Addon group card ─────────────────────────────────────────────────────────

class _AddonGroupCard extends StatelessWidget {
  final AddonGroup group;
  final Set<String> selected;
  final ValueChanged<AddonOption> onToggle;
  final double w;

  const _AddonGroupCard({
    required this.group,
    required this.selected,
    required this.onToggle,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    final options = group.availableOptions;
    final atLimit =
        !group.isSingleChoice && selected.length >= group.selectionLimit;
    final satisfied = selected.length >= group.requiredCount;

    return Container(
      margin: EdgeInsets.fromLTRB(w * 0.03, 0, w * 0.03, w * 0.025),
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.05, w * 0.05, w * 0.02),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Group header ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: TextStyle(
                        fontSize: w * 0.048,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: w * 0.008),
                    Text(
                      group.selectionHint,
                      style: TextStyle(
                        fontSize: w * 0.03,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (group.requiredCount > 0)
                _RequirementPill(satisfied: satisfied, w: w),
            ],
          ),
          SizedBox(height: w * 0.02),

          // ── Options ──
          ...options.asMap().entries.map((entry) {
            final option = entry.value;
            final isSelected = selected.contains(option.id);
            return _OptionRow(
              option: option,
              isSelected: isSelected,
              isSingleChoice: group.isSingleChoice,
              enabled: isSelected || !atLimit,
              showDivider: entry.key < options.length - 1,
              onTap: () => onToggle(option),
              w: w,
            );
          }),
        ],
      ),
    );
  }
}

class _RequirementPill extends StatelessWidget {
  final bool satisfied;
  final double w;

  const _RequirementPill({required this.satisfied, required this.w});

  @override
  Widget build(BuildContext context) {
    final color = satisfied ? AppColors.success : AppColors.textSecondary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: w * 0.01),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (satisfied) ...[
            Icon(Icons.check_rounded, size: w * 0.032, color: color),
            SizedBox(width: w * 0.008),
          ],
          Text(
            'Required',
            style: TextStyle(
              fontSize: w * 0.027,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Option row ───────────────────────────────────────────────────────────────

class _OptionRow extends StatelessWidget {
  final AddonOption option;
  final bool isSelected;
  final bool isSingleChoice;
  final bool enabled;
  final bool showDivider;
  final VoidCallback onTap;
  final double w;

  const _OptionRow({
    required this.option,
    required this.isSelected,
    required this.isSingleChoice,
    required this.enabled,
    required this.showDivider,
    required this.onTap,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = enabled ? AppColors.textPrimary : AppColors.textHint;

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: w * 0.042),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: AppColors.divider))
              : null,
        ),
        child: Row(
          children: [
            _SelectionIndicator(
              isSelected: isSelected,
              isSingleChoice: isSingleChoice,
              enabled: enabled,
              w: w,
            ),
            SizedBox(width: w * 0.04),
            Expanded(
              child: Text(
                option.name,
                style: TextStyle(
                  fontSize: w * 0.04,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: textColor,
                ),
              ),
            ),
            SizedBox(width: w * 0.03),
            Text(
              '+GHS ${option.additionalPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: w * 0.038,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Checkbox (multi-select) or radio (single choice) drawn to match the
/// rounded-square / circle style of the add-on sheet design.
class _SelectionIndicator extends StatelessWidget {
  final bool isSelected;
  final bool isSingleChoice;
  final bool enabled;
  final double w;

  const _SelectionIndicator({
    required this.isSelected,
    required this.isSingleChoice,
    required this.enabled,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    final size = w * 0.06;
    final borderColor = isSelected
        ? AppColors.primary
        : (enabled ? AppColors.textHint : AppColors.border);

    if (isSingleChoice) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
        ),
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: isSelected ? size * 0.5 : 0,
          height: isSelected ? size * 0.5 : 0,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(w * 0.012),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: isSelected
          ? Icon(Icons.check_rounded, size: size * 0.75, color: Colors.white)
          : null,
    );
  }
}

// ─── Bottom bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int quantity;
  final bool canDecrement;
  final bool canIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final double lineTotal;
  final List<String> unsatisfiedGroups;
  final VoidCallback? onConfirm;
  final double w;

  const _BottomBar({
    required this.quantity,
    required this.canDecrement,
    required this.canIncrement,
    required this.onDecrement,
    required this.onIncrement,
    required this.lineTotal,
    required this.unsatisfiedGroups,
    required this.onConfirm,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    final height = w * 0.15;

    return Container(
      padding: EdgeInsets.fromLTRB(
        w * 0.05,
        w * 0.03,
        w * 0.05,
        w * 0.04 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (unsatisfiedGroups.isNotEmpty) ...[
            Text(
              'Please choose: ${unsatisfiedGroups.join(', ')}',
              style: TextStyle(fontSize: w * 0.03, color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: w * 0.025),
          ],
          Row(
            children: [
              // ── Meal quantity pill ──
              Container(
                height: height,
                padding: EdgeInsets.symmetric(horizontal: w * 0.015),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _QtyIcon(
                      icon: Icons.remove_rounded,
                      enabled: canDecrement,
                      onTap: onDecrement,
                      w: w,
                    ),
                    SizedBox(
                      width: w * 0.08,
                      child: Text(
                        '$quantity',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: w * 0.045,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _QtyIcon(
                      icon: Icons.add_rounded,
                      enabled: canIncrement,
                      onTap: onIncrement,
                      w: w,
                    ),
                  ],
                ),
              ),
              SizedBox(width: w * 0.04),

              // ── Add button ──
              Expanded(
                child: SizedBox(
                  height: height,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Add',
                          style: TextStyle(
                            fontSize: w * 0.04,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'GHS ${lineTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: w * 0.04,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyIcon extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final double w;

  const _QtyIcon({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: enabled ? onTap : null,
      radius: w * 0.06,
      child: Padding(
        padding: EdgeInsets.all(w * 0.02),
        child: Icon(
          icon,
          size: w * 0.06,
          color: enabled ? AppColors.textPrimary : AppColors.border,
        ),
      ),
    );
  }
}
