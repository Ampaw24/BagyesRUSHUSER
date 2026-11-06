import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../constant/app_theme.dart';
import 'package:gopady/constant/app_tokens.dart';
import 'parcel_ui.dart';

// 5 MB size cap per image
const _maxFileSizeBytes = 5 * 1024 * 1024;
const _maxWeightKg = 20.0;

// ── Size category model ───────────────────────────────────────────────────────

class _WCategory {
  final String id;
  final String label;
  final String range;
  final String examples;
  final String defaultKg;
  final List<List<dynamic>> icon;
  final double min;
  final double max;

  const _WCategory({
    required this.id,
    required this.label,
    required this.range,
    required this.examples,
    required this.defaultKg,
    required this.icon,
    required this.min,
    required this.max,
  });

  bool matches(double kg) =>
      kg >= min && (max == _maxWeightKg ? kg <= max : kg < max);
}

const _categories = [
  _WCategory(
    id: 'small',
    label: 'Small',
    range: 'Up to 3 kg',
    examples: 'Phone, books, shoes, a small gift',
    defaultKg: '1.5',
    icon: HugeIcons.strokeRoundedMail01,
    min: 0,
    max: 3,
  ),
  _WCategory(
    id: 'medium',
    label: 'Medium',
    range: '3–8 kg',
    examples: 'Clothes, a food box, small electronics',
    defaultKg: '5.0',
    icon: HugeIcons.strokeRoundedShoppingBag01,
    min: 3,
    max: 8,
  ),
  _WCategory(
    id: 'large',
    label: 'Large',
    range: '8–15 kg',
    examples: 'Appliances, big boxes, groceries',
    defaultKg: '11.0',
    icon: HugeIcons.strokeRoundedPackage,
    min: 8,
    max: 15,
  ),
  _WCategory(
    id: 'heavy',
    label: 'Heavy',
    range: '15–20 kg',
    examples: 'Furniture parts, heavy equipment',
    defaultKg: '17.0',
    icon: HugeIcons.strokeRoundedDeliveryBox02,
    min: 15,
    max: _maxWeightKg,
  ),
];

_WCategory? _categoryFor(double kg) =>
    _categories.where((c) => c.matches(kg)).firstOrNull;

// ── Main widget ───────────────────────────────────────────────────────────────

class PackageDetailsStep extends StatefulWidget {
  final List<File> images;
  final String weightText;
  final void Function(List<File> files, List<String> base64List) onImagesAdded;
  final ValueChanged<int> onImageRemoved;
  final ValueChanged<String> onWeightChanged;
  final int maxImages;
  final bool fragile;
  final ValueChanged<bool> onFragileChanged;

  /// Currently selected backend size category id (e.g. 'small'), sent as
  /// `size` on every stop when the parcel is created.
  final String selectedSize;
  final ValueChanged<String> onSizeChanged;

  const PackageDetailsStep({
    super.key,
    required this.images,
    required this.weightText,
    required this.onImagesAdded,
    required this.onImageRemoved,
    required this.onWeightChanged,
    required this.maxImages,
    required this.fragile,
    required this.onFragileChanged,
    required this.selectedSize,
    required this.onSizeChanged,
  });

  @override
  State<PackageDetailsStep> createState() => _PackageDetailsStepState();
}

class _PackageDetailsStepState extends State<PackageDetailsStep> {
  late final TextEditingController _weightCtrl;
  bool _isPicking = false;
  String? _selectedCategoryId;
  bool _overLimit = false;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: widget.weightText);

    // Restore the selection when returning to this step — prefer the
    // explicitly selected size over re-deriving it from the weight.
    if (_categories.any((c) => c.id == widget.selectedSize)) {
      _selectedCategoryId = widget.selectedSize;
    } else {
      final kg = double.tryParse(widget.weightText);
      if (kg != null) {
        _selectedCategoryId = _categoryFor(kg)?.id;
        _overLimit = kg > _maxWeightKg;
      }
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  _WCategory? get _selectedCategory =>
      _categories.where((c) => c.id == _selectedCategoryId).firstOrNull;

  // ── Image picking ─────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    final remaining = widget.maxImages - widget.images.length;
    if (remaining <= 0) return;

    setState(() => _isPicking = true);
    try {
      final picked = await ImagePicker().pickMultiImage(
        maxWidth: 1200,
        imageQuality: 80,
        limit: remaining,
      );
      if (picked.isEmpty) return;

      final validFiles = <File>[];
      final validBase64 = <String>[];
      final oversized = <String>[];

      for (final xFile in picked) {
        final bytes = await xFile.readAsBytes();
        if (bytes.length > _maxFileSizeBytes) {
          oversized.add(xFile.name);
          continue;
        }
        validFiles.add(File(xFile.path));
        validBase64.add(base64.encode(bytes));
      }

      if (validFiles.isNotEmpty) widget.onImagesAdded(validFiles, validBase64);
      if (oversized.isNotEmpty && mounted) _showSizeError(oversized.length);
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _showSizeError(int count) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$count image${count > 1 ? 's' : ''} skipped — '
          'each photo must be under 5 MB.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Weight selection ──────────────────────────────────────────────────────

  void _selectCategory(_WCategory category) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategoryId = category.id;
      _overLimit = false;
    });
    _weightCtrl.text = category.defaultKg;
    widget.onWeightChanged(category.defaultKg);
    widget.onSizeChanged(category.id);
  }

  void _onWeightTyped(String value) {
    final kg = double.tryParse(value);
    final match = kg == null ? null : _categoryFor(kg);
    setState(() {
      _overLimit = kg != null && kg > _maxWeightKg;
      // Typing a weight live-highlights the size it falls into.
      _selectedCategoryId = match?.id;
    });
    widget.onWeightChanged(value);
    if (match != null) widget.onSizeChanged(match.id);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return ListView(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.02, w * 0.05, w * 0.08),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        const ParcelStepHeader(
          title: 'Tell us about it',
          subtitle: 'Size and weight help us match the right rider and price.',
        ),
        const ParcelGap(0.065),

        // ── Size ───────────────────────────────────────────────────────────
        ParcelSectionLabel(
          label: 'Package size',
          caption: 'Pick the closest match · max 20 kg',
          trailing: widget.weightText.isNotEmpty && !_overLimit
              ? _WeightBadge(weightText: widget.weightText)
              : null,
        ),
        const ParcelGap(0.035),
        _SizeSelector(
          selectedId: _selectedCategoryId,
          onSelected: _selectCategory,
        ),
        const ParcelGap(0.03),
        _FitsHint(category: _selectedCategory),
        const ParcelGap(0.03),
        _ExactWeightRow(
          controller: _weightCtrl,
          onChanged: _onWeightTyped,
          hasError: _overLimit,
        ),
        AnimatedSize(
          duration: AppMotion.standard,
          curve: AppMotion.outExpo,
          child: _overLimit
              ? Padding(
                  padding: EdgeInsets.only(top: w * 0.025),
                  child: const ParcelNote(
                    tone: ParcelNoteTone.error,
                    message:
                        'That\'s over 20 kg — we can\'t deliver items '
                        'above this limit.',
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),

        const ParcelGap(0.07),

        // ── Handling ───────────────────────────────────────────────────────
        const ParcelSectionLabel(label: 'Handling'),
        const ParcelGap(0.03),
        _FragileToggle(
          fragile: widget.fragile,
          onChanged: widget.onFragileChanged,
        ),

        const ParcelGap(0.07),

        // ── Photos ─────────────────────────────────────────────────────────
        ParcelSectionLabel(
          label: 'Photos',
          caption: 'Optional · up to ${widget.maxImages}, 5 MB each',
          trailing: widget.images.isEmpty
              ? null
              : _CountPill(count: widget.images.length, max: widget.maxImages),
        ),
        const ParcelGap(0.035),
        _PhotoStrip(
          images: widget.images,
          canAddMore: widget.images.length < widget.maxImages,
          isPicking: _isPicking,
          onAdd: _pickImages,
          onRemove: widget.onImageRemoved,
        ),
        if (widget.images.isNotEmpty) ...[
          const ParcelGap(0.03),
          const ParcelNote(
            tone: ParcelNoteTone.info,
            icon: HugeIcons.strokeRoundedIdea01,
            message:
                'Sending to several places? Add a photo per item — '
                'you can tag them to each stop next.',
          ),
        ],
      ],
    );
  }
}

// ── Size selector ─────────────────────────────────────────────────────────────

class _SizeSelector extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<_WCategory> onSelected;

  const _SizeSelector({required this.selectedId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _categories.length; i++) ...[
            if (i > 0) SizedBox(width: w * 0.022),
            Expanded(
              child: _SizeTile(
                category: _categories[i],
                isSelected: selectedId == _categories[i].id,
                onTap: () => onSelected(_categories[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SizeTile extends StatelessWidget {
  final _WCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _SizeTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final radius = BorderRadius.circular(w * 0.04);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${category.label}, ${category.range}',
      child: AnimatedContainer(
        duration: AppMotion.standard,
        curve: AppMotion.outExpo,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.card,
          borderRadius: radius,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.015,
                vertical: w * 0.035,
              ),
              child: Column(
                children: [
                  ParcelIconBadge(
                    icon: category.icon,
                    active: isSelected,
                    sizeFactor: 0.105,
                  ),
                  SizedBox(height: w * 0.025),
                  Text(
                    category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: w * 0.034,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: w * 0.006),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      category.range,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: w * 0.027,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Fits: Phone, books…" for the selected size, or a prompt when none is.
class _FitsHint extends StatelessWidget {
  final _WCategory? category;

  const _FitsHint({required this.category});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final selected = category;
    return AnimatedSwitcher(
      duration: AppMotion.standard,
      child: Row(
        key: ValueKey(selected?.id),
        children: [
          HugeIcon(
            icon: selected == null
                ? HugeIcons.strokeRoundedTouch01
                : HugeIcons.strokeRoundedCheckmarkCircle02,
            color: selected == null ? AppColors.textHint : AppColors.primary,
            size: w * 0.04,
          ),
          SizedBox(width: w * 0.02),
          Expanded(
            child: Text.rich(
              selected == null
                  ? const TextSpan(text: 'Tap a size to estimate the weight')
                  : TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Fits  ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextSpan(text: selected.examples),
                      ],
                    ),
              style: TextStyle(
                fontSize: w * 0.031,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Exact weight ──────────────────────────────────────────────────────────────

class _ExactWeightRow extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool hasError;

  const _ExactWeightRow({
    required this.controller,
    required this.onChanged,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final fieldRadius = BorderRadius.circular(w * 0.025);

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: color, width: width),
        );

    return ParcelCard(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedWeightScale,
            color: AppColors.textSecondary,
            size: w * 0.05,
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Know the exact weight?',
                  style: TextStyle(
                    fontSize: w * 0.034,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: w * 0.004),
                Text(
                  'Optional · more accurate pricing',
                  style: TextStyle(
                    fontSize: w * 0.028,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: w * 0.02),
          SizedBox(
            width: w * 0.26,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textAlign: TextAlign.end,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{0,3}\.?\d{0,2}'),
                ),
              ],
              style: TextStyle(
                fontSize: w * 0.04,
                fontWeight: FontWeight.w700,
                color: hasError ? AppColors.error : AppColors.textPrimary,
                fontFamily: AppFonts.body,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: '0.0',
                suffixText: ' kg',
                suffixStyle: TextStyle(
                  fontSize: w * 0.034,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: w * 0.03,
                  vertical: w * 0.028,
                ),
                border: border(Colors.transparent),
                enabledBorder: border(
                  hasError ? AppColors.error : Colors.transparent,
                ),
                focusedBorder: border(
                  hasError ? AppColors.error : AppColors.primary,
                  1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightBadge extends StatelessWidget {
  final String weightText;

  const _WeightBadge({required this.weightText});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return AnimatedSwitcher(
      duration: AppMotion.micro,
      child: Container(
        key: ValueKey(weightText),
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.028,
          vertical: w * 0.01,
        ),
        decoration: const ShapeDecoration(
          color: AppColors.surfaceVariant,
          shape: StadiumBorder(),
        ),
        child: Text(
          '≈ $weightText kg',
          style: TextStyle(
            fontSize: w * 0.03,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}

// ── Fragile toggle ────────────────────────────────────────────────────────────

class _FragileToggle extends StatelessWidget {
  final bool fragile;
  final ValueChanged<bool> onChanged;

  const _FragileToggle({required this.fragile, required this.onChanged});

  void _toggle(bool value) {
    HapticFeedback.lightImpact();
    onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return MergeSemantics(
      child: ParcelCard(
        highlighted: fragile,
        padding: EdgeInsets.zero,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(w * 0.045),
            onTap: () => _toggle(!fragile),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.04,
                vertical: w * 0.03,
              ),
              child: Row(
                children: [
                  ParcelIconBadge(
                    icon: HugeIcons.strokeRoundedAlert02,
                    active: fragile,
                  ),
                  SizedBox(width: w * 0.035),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fragile item',
                          style: TextStyle(
                            fontSize: w * 0.036,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: w * 0.005),
                        Text(
                          'The rider will handle it with extra care',
                          style: TextStyle(
                            fontSize: w * 0.03,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(value: fragile, onChanged: _toggle),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Photos ────────────────────────────────────────────────────────────────────

class _CountPill extends StatelessWidget {
  final int count;
  final int max;

  const _CountPill({required this.count, required this.max});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Text(
      '$count/$max',
      style: TextStyle(
        fontSize: w * 0.031,
        fontWeight: FontWeight.w700,
        color: count == max ? AppColors.primary : AppColors.textHint,
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  final List<File> images;
  final bool canAddMore;
  final bool isPicking;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _PhotoStrip({
    required this.images,
    required this.canAddMore,
    required this.isPicking,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    if (images.isEmpty) {
      return _AddPhotoTile(isPicking: isPicking, onTap: onAdd, expanded: true);
    }

    final tile = w * 0.21;
    final itemCount = images.length + (canAddMore ? 1 : 0);
    return SizedBox(
      // Room for the remove badge that overhangs each thumbnail.
      height: tile + w * 0.025,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.only(top: w * 0.025),
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(width: w * 0.03),
        itemBuilder: (context, i) {
          if (canAddMore && i == 0) {
            return SizedBox(
              width: tile,
              child: _AddPhotoTile(isPicking: isPicking, onTap: onAdd),
            );
          }
          final index = canAddMore ? i - 1 : i;
          return _Thumbnail(
            file: images[index],
            size: tile,
            onRemove: () => onRemove(index),
          );
        },
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final bool isPicking;
  final VoidCallback onTap;
  final bool expanded;

  const _AddPhotoTile({
    required this.isPicking,
    required this.onTap,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final radius = BorderRadius.circular(w * 0.035);

    final content = isPicking
        ? SizedBox(
            width: w * 0.06,
            height: w * 0.06,
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
        : expanded
        ? Row(
            children: [
              const ParcelIconBadge(
                icon: HugeIcons.strokeRoundedCamera02,
                active: true,
              ),
              SizedBox(width: w * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add photos',
                      style: TextStyle(
                        fontSize: w * 0.036,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: w * 0.005),
                    Text(
                      'Helps the rider recognise your package',
                      style: TextStyle(
                        fontSize: w * 0.03,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                color: AppColors.primary,
                size: w * 0.05,
              ),
            ],
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                color: AppColors.primary,
                size: w * 0.06,
              ),
              SizedBox(height: w * 0.01),
              Text(
                'Add',
                style: TextStyle(
                  fontSize: w * 0.028,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      label: 'Add package photos',
      child: Material(
        color: AppColors.surface,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: isPicking ? null : onTap,
          child: Container(
            padding: expanded ? EdgeInsets.all(w * 0.04) : null,
            alignment: expanded ? null : Alignment.center,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: expanded && isPicking ? Center(child: content) : content,
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final File file;
  final double size;
  final VoidCallback onRemove;

  const _Thumbnail({
    required this.file,
    required this.size,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final badge = w * 0.06;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(w * 0.035),
            child: Image.file(
              file,
              width: size,
              height: size,
              fit: BoxFit.cover,
              cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                  .round(),
            ),
          ),
          Positioned(
            top: -badge * 0.35,
            right: -badge * 0.35,
            child: Semantics(
              button: true,
              label: 'Remove photo',
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: badge,
                  height: badge,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: badge * 0.55,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
