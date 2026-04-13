import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../constant/app_theme.dart';

// 5 MB size cap per image
const _maxFileSizeBytes = 5 * 1024 * 1024;

// ── Weight category model ─────────────────────────────────────────────────────

class _WCategory {
  final String id;
  final String label;
  final String range;
  final String examples;
  final String defaultKg;
  final List<List<dynamic>> icon;
  final Color accent;

  const _WCategory({
    required this.id,
    required this.label,
    required this.range,
    required this.examples,
    required this.defaultKg,
    required this.icon,
    required this.accent,
  });

  double get _min => switch (id) {
        'envelope' => 0.0,
        'small' => 0.5,
        'medium' => 3.0,
        'large' => 8.0,
        'heavy' => 15.0,
        _ => 0.0,
      };

  double get _max => switch (id) {
        'envelope' => 0.5,
        'small' => 3.0,
        'medium' => 8.0,
        'large' => 15.0,
        'heavy' => 20.0,
        _ => 20.0,
      };

  bool matches(double kg) => kg >= _min && (id == 'heavy' ? kg <= _max : kg < _max);
}

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
  });

  @override
  State<PackageDetailsStep> createState() => _PackageDetailsStepState();
}

class _PackageDetailsStepState extends State<PackageDetailsStep> {
  late final List<_WCategory> _categories;
  late final TextEditingController _customCtrl;
  bool _isPicking = false;
  String? _selectedCategoryId;
  bool _showCustom = false;
  bool _overLimit = false;

  @override
  void initState() {
    super.initState();

    _categories = [
      _WCategory(
        id: 'envelope',
        label: 'Envelope',
        range: 'Under 0.5 kg',
        examples: 'Documents, letters, SIM cards',
        defaultKg: '0.3',
        icon: HugeIcons.strokeRoundedMail01,
        accent: AppColors.info,
      ),
      _WCategory(
        id: 'small',
        label: 'Small',
        range: '0.5 – 3 kg',
        examples: 'Phone, books, shoes, small gift',
        defaultKg: '1.5',
        icon: HugeIcons.strokeRoundedSmartPhone01,
        accent: AppColors.success,
      ),
      _WCategory(
        id: 'medium',
        label: 'Medium',
        range: '3 – 8 kg',
        examples: 'Clothes, food box, small electronics',
        defaultKg: '5.0',
        icon: HugeIcons.strokeRoundedShoppingBag01,
        accent: AppColors.accent,
      ),
      _WCategory(
        id: 'large',
        label: 'Large',
        range: '8 – 15 kg',
        examples: 'Appliances, big boxes, groceries',
        defaultKg: '11.0',
        icon: HugeIcons.strokeRoundedDeliveryBox01,
        accent: const Color(0xFF9B59B6),
      ),
      _WCategory(
        id: 'heavy',
        label: 'Heavy',
        range: '15 – 20 kg',
        examples: 'Furniture parts, heavy equipment',
        defaultKg: '17.0',
        icon: HugeIcons.strokeRoundedDeliveryTruck01,
        accent: AppColors.error,
      ),
    ];

    _customCtrl = TextEditingController(text: widget.weightText);

    // Auto-restore selection when returning to this step
    if (widget.weightText.isNotEmpty) {
      final kg = double.tryParse(widget.weightText);
      if (kg != null) {
        final match = _categories.where((c) => c.matches(kg)).firstOrNull;
        if (match != null) {
          _selectedCategoryId = match.id;
        } else {
          // Weight was set manually outside any category range
          _showCustom = true;
          _overLimit = kg > 20.0;
        }
      }
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  // ── Image picking ─────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    final remaining = widget.maxImages - widget.images.length;
    if (remaining <= 0) return;

    setState(() => _isPicking = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage(
        maxWidth: 1200,
        imageQuality: 80,
        limit: remaining,
      );
      if (picked.isEmpty) return;

      final validFiles = <File>[];
      final validBase64 = <String>[];
      final oversized = <String>[];

      for (final xFile in picked) {
        final file = File(xFile.path);
        final bytes = await xFile.readAsBytes();
        if (bytes.length > _maxFileSizeBytes) {
          oversized.add(xFile.name);
          continue;
        }
        validFiles.add(file);
        validBase64.add(base64.encode(bytes));
      }

      if (validFiles.isNotEmpty) {
        widget.onImagesAdded(validFiles, validBase64);
      }

      if (oversized.isNotEmpty && mounted) {
        _showSizeError(oversized);
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _showSizeError(List<String> names) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${names.length} image${names.length > 1 ? 's' : ''} skipped — '
          'each photo must be under 5 MB.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.warning,
      ),
    );
  }

  // ── Weight selection ──────────────────────────────────────────────────────

  void _selectCategory(_WCategory cat) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedCategoryId = cat.id;
      _showCustom = false;
      _overLimit = false;
    });
    _customCtrl.text = cat.defaultKg;
    widget.onWeightChanged(cat.defaultKg);
  }

  void _onCustomWeightChanged(String value) {
    final kg = double.tryParse(value);
    setState(() {
      _overLimit = kg != null && kg > 20.0;
      if (kg != null) {
        // Smart: auto-highlight matching category tile while typing
        final match = _categories.where((c) => c.matches(kg)).firstOrNull;
        _selectedCategoryId = match?.id;
      } else {
        _selectedCategoryId = null;
      }
    });
    widget.onWeightChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final hasImages = widget.images.isNotEmpty;
    final canAddMore = widget.images.length < widget.maxImages;

    return ListView(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.02, w * 0.05, w * 0.06),
      children: [
        // ── Header ───────────────────────────────────────────────────────────
        Text(
          'Package Details',
          style: TextStyle(
            fontSize: w * 0.055,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: w * 0.015),
        Text(
          'Add photos and select your package size.',
          style: TextStyle(fontSize: w * 0.035, color: AppColors.textSecondary),
        ),
        SizedBox(height: w * 0.06),

        // ── Photo section ─────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel('Package Photos', w),
            if (hasImages)
              Text(
                '${widget.images.length}/${widget.maxImages}',
                style: TextStyle(
                  fontSize: w * 0.032,
                  fontWeight: FontWeight.w600,
                  color: widget.images.length == widget.maxImages
                      ? AppColors.primary
                      : AppColors.textHint,
                ),
              ),
          ],
        ),
        SizedBox(height: w * 0.03),

        if (!hasImages)
          _EmptyImageSlot(isPicking: _isPicking, onTap: _pickImages, w: w)
        else
          _ImageGrid(
            images: widget.images,
            canAddMore: canAddMore,
            isPicking: _isPicking,
            onAdd: _pickImages,
            onRemove: widget.onImageRemoved,
            w: w,
          ),

        SizedBox(height: w * 0.025),
        _SizeRestrictionNote(w: w, maxImages: widget.maxImages),
        if (widget.images.isNotEmpty) ...[
          SizedBox(height: w * 0.025),
          _MultiItemHint(w: w),
        ],

        SizedBox(height: w * 0.07),

        // ── Weight / Size section ─────────────────────────────────────────────
        Row(
          children: [
            _sectionLabel('Package Size', w),
            const Spacer(),
            // Selected weight badge
            if (widget.weightText.isNotEmpty && !_overLimit)
              _WeightBadge(weightText: widget.weightText, w: w),
          ],
        ),
        SizedBox(height: w * 0.01),
        Text(
          'Tap the closest match — we\'ll estimate the weight for you.',
          style: TextStyle(fontSize: w * 0.032, color: AppColors.textSecondary),
        ),
        SizedBox(height: w * 0.04),

        // ── Category grid (2 columns) ──────────────────────────────────────────
        _buildCategoryGrid(w),

        SizedBox(height: w * 0.04),

        // ── "Enter exact weight" toggle ───────────────────────────────────────
        _ExactWeightToggle(
          isOpen: _showCustom,
          w: w,
          onToggle: () => setState(() => _showCustom = !_showCustom),
        ),

        // ── Custom weight field (expanded) ────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: _showCustom
              ? Padding(
                  padding: EdgeInsets.only(top: w * 0.03),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CustomWeightField(
                        controller: _customCtrl,
                        onChanged: _onCustomWeightChanged,
                        w: w,
                      ),
                      if (_overLimit) ...[
                        SizedBox(height: w * 0.025),
                        _OverLimitWarning(w: w),
                      ] else if (_selectedCategoryId != null &&
                          _customCtrl.text.isNotEmpty) ...[
                        SizedBox(height: w * 0.02),
                        _CategoryMatchHint(
                          category: _categories
                              .firstWhere((c) => c.id == _selectedCategoryId),
                          w: w,
                        ),
                      ],
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),

        SizedBox(height: w * 0.025),
        _MaxWeightNote(w: w),

        SizedBox(height: w * 0.07),

        // ── Handle with care ──────────────────────────────────────────────────
        _sectionLabel('Handle with care', w),
        SizedBox(height: w * 0.03),
        _FragileToggle(
          fragile: widget.fragile,
          onChanged: widget.onFragileChanged,
          w: w,
        ),

        SizedBox(height: w * 0.04),
      ],
    );
  }

  Widget _buildCategoryGrid(double w) {
    final gap = w * 0.03;
    final tileW = (w - w * 0.1 - gap) / 2;

    return Column(
      children: [
        // Row 1: Envelope + Small
        Row(
          children: [
            _CategoryTile(
              category: _categories[0],
              isSelected: _selectedCategoryId == _categories[0].id,
              width: tileW,
              onTap: () => _selectCategory(_categories[0]),
              w: w,
            ),
            SizedBox(width: gap),
            _CategoryTile(
              category: _categories[1],
              isSelected: _selectedCategoryId == _categories[1].id,
              width: tileW,
              onTap: () => _selectCategory(_categories[1]),
              w: w,
            ),
          ],
        ),
        SizedBox(height: gap),
        // Row 2: Medium + Large
        Row(
          children: [
            _CategoryTile(
              category: _categories[2],
              isSelected: _selectedCategoryId == _categories[2].id,
              width: tileW,
              onTap: () => _selectCategory(_categories[2]),
              w: w,
            ),
            SizedBox(width: gap),
            _CategoryTile(
              category: _categories[3],
              isSelected: _selectedCategoryId == _categories[3].id,
              width: tileW,
              onTap: () => _selectCategory(_categories[3]),
              w: w,
            ),
          ],
        ),
        SizedBox(height: gap),
        // Row 3: Heavy (full width)
        _CategoryTile(
          category: _categories[4],
          isSelected: _selectedCategoryId == _categories[4].id,
          width: double.infinity,
          isFullWidth: true,
          onTap: () => _selectCategory(_categories[4]),
          w: w,
        ),
      ],
    );
  }

  Widget _sectionLabel(String label, double w) => Text(
        label,
        style: TextStyle(
          fontSize: w * 0.038,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );
}

// ── Fragile toggle ────────────────────────────────────────────────────────────

class _FragileToggle extends StatelessWidget {
  final bool fragile;
  final ValueChanged<bool> onChanged;
  final double w;

  const _FragileToggle({
    required this.fragile,
    required this.onChanged,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!fragile);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.04,
          vertical: w * 0.038,
        ),
        decoration: BoxDecoration(
          color: fragile
              ? AppColors.error.withValues(alpha: 0.06)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.035),
          border: Border.all(
            color: fragile
                ? AppColors.error.withValues(alpha: 0.4)
                : AppColors.border,
            width: fragile ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: w * 0.1,
              height: w * 0.1,
              decoration: BoxDecoration(
                color: fragile
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.border.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '🫧',
                  style: TextStyle(fontSize: w * 0.045),
                ),
              ),
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
                      fontWeight: FontWeight.w700,
                      color: fragile
                          ? AppColors.error
                          : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: w * 0.006),
                  Text(
                    'Mark this if contents can break easily',
                    style: TextStyle(
                      fontSize: w * 0.03,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: w * 0.03),
            Switch.adaptive(
              value: fragile,
              onChanged: (v) {
                HapticFeedback.lightImpact();
                onChanged(v);
              },
              activeThumbColor: AppColors.error,
              activeTrackColor: AppColors.error.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Multi-item hint ───────────────────────────────────────────────────────────

class _MultiItemHint extends StatelessWidget {
  final double w;
  const _MultiItemHint({required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.035,
        vertical: w * 0.028,
      ),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: w * 0.038,
            color: AppColors.info,
          ),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Text(
              'Sending different items to multiple locations? '
              'Add a separate photo for each item — you can tag '
              'which photo belongs to each stop on the next screen.',
              style: TextStyle(
                fontSize: w * 0.031,
                color: AppColors.info,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category tile ─────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final _WCategory category;
  final bool isSelected;
  final double width;
  final bool isFullWidth;
  final VoidCallback onTap;
  final double w;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.width,
    required this.onTap,
    required this.w,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: width,
        padding: EdgeInsets.all(w * 0.038),
        decoration: BoxDecoration(
          color: isSelected
              ? category.accent.withValues(alpha: 0.07)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.035),
          border: Border.all(
            color: isSelected ? category.accent : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: isFullWidth
            ? _FullWidthContent(category: category, isSelected: isSelected, w: w)
            : _CompactContent(category: category, isSelected: isSelected, w: w),
      ),
    );
  }
}

// ── Compact tile content (2-column tiles) ─────────────────────────────────────

class _CompactContent extends StatelessWidget {
  final _WCategory category;
  final bool isSelected;
  final double w;

  const _CompactContent({
    required this.category,
    required this.isSelected,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(w * 0.02),
              decoration: BoxDecoration(
                color: isSelected
                    ? category.accent.withValues(alpha: 0.15)
                    : AppColors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(w * 0.02),
              ),
              child: HugeIcon(
                icon: category.icon,
                color: isSelected ? category.accent : AppColors.textSecondary,
                size: w * 0.05,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Container(
                width: w * 0.05,
                height: w * 0.05,
                decoration: BoxDecoration(
                  color: category.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: w * 0.032,
                ),
              ),
          ],
        ),
        SizedBox(height: w * 0.028),
        Text(
          category.label,
          style: TextStyle(
            fontSize: w * 0.038,
            fontWeight: FontWeight.w700,
            color: isSelected ? category.accent : AppColors.textPrimary,
          ),
        ),
        SizedBox(height: w * 0.008),
        Text(
          category.range,
          style: TextStyle(
            fontSize: w * 0.029,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? category.accent.withValues(alpha: 0.8)
                : AppColors.textSecondary,
          ),
        ),
        SizedBox(height: w * 0.01),
        Text(
          category.examples,
          style: TextStyle(
            fontSize: w * 0.028,
            color: AppColors.textHint,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Full-width tile content (Heavy tier) ──────────────────────────────────────

class _FullWidthContent extends StatelessWidget {
  final _WCategory category;
  final bool isSelected;
  final double w;

  const _FullWidthContent({
    required this.category,
    required this.isSelected,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(w * 0.025),
          decoration: BoxDecoration(
            color: isSelected
                ? category.accent.withValues(alpha: 0.15)
                : AppColors.border.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(w * 0.02),
          ),
          child: HugeIcon(
            icon: category.icon,
            color: isSelected ? category.accent : AppColors.textSecondary,
            size: w * 0.055,
          ),
        ),
        SizedBox(width: w * 0.035),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.label,
                style: TextStyle(
                  fontSize: w * 0.038,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? category.accent : AppColors.textPrimary,
                ),
              ),
              SizedBox(height: w * 0.005),
              Text(
                '${category.range}  ·  ${category.examples}',
                style: TextStyle(
                  fontSize: w * 0.029,
                  color: AppColors.textHint,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (isSelected) ...[
          SizedBox(width: w * 0.02),
          Container(
            width: w * 0.055,
            height: w * 0.055,
            decoration: BoxDecoration(
              color: category.accent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: w * 0.035,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Selected weight badge ─────────────────────────────────────────────────────

class _WeightBadge extends StatelessWidget {
  final String weightText;
  final double w;

  const _WeightBadge({required this.weightText, required this.w});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey(weightText),
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.03,
          vertical: w * 0.012,
        ),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(w * 0.05),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: w * 0.035,
            ),
            SizedBox(width: w * 0.015),
            Text(
              '~$weightText kg',
              style: TextStyle(
                fontSize: w * 0.032,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Exact weight toggle ───────────────────────────────────────────────────────

class _ExactWeightToggle extends StatelessWidget {
  final bool isOpen;
  final double w;
  final VoidCallback onToggle;

  const _ExactWeightToggle({
    required this.isOpen,
    required this.w,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.04,
          vertical: w * 0.035,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.03),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedDeliveryBox01,
              color: AppColors.textSecondary,
              size: w * 0.045,
            ),
            SizedBox(width: w * 0.03),
            Expanded(
              child: Text(
                isOpen ? 'Hide exact weight' : 'Enter exact weight (optional)',
                style: TextStyle(
                  fontSize: w * 0.035,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            AnimatedRotation(
              turns: isOpen ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 220),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
                size: w * 0.055,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom weight field ───────────────────────────────────────────────────────

class _CustomWeightField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final double w;

  const _CustomWeightField({
    required this.controller,
    required this.onChanged,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(width: w * 0.04),
          HugeIcon(
            icon: HugeIcons.strokeRoundedDeliveryBox01,
            color: AppColors.textSecondary,
            size: w * 0.05,
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              onChanged: onChanged,
              autofocus: true,
              style: TextStyle(
                fontSize: w * 0.04,
                color: AppColors.textPrimary,
                fontFamily: 'Mukta',
              ),
              decoration: InputDecoration(
                hintText: '0.0',
                hintStyle: TextStyle(
                  fontSize: w * 0.04,
                  color: AppColors.textHint,
                  fontFamily: 'Mukta',
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: w * 0.04,
                  horizontal: w * 0.02,
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.04,
              vertical: w * 0.04,
            ),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppColors.border)),
            ),
            child: Text(
              'kg',
              style: TextStyle(
                fontSize: w * 0.038,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category match hint (shown when custom weight matches a category) ──────────

class _CategoryMatchHint extends StatelessWidget {
  final _WCategory category;
  final double w;

  const _CategoryMatchHint({required this.category, required this.w});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HugeIcon(
          icon: category.icon,
          color: category.accent,
          size: w * 0.038,
        ),
        SizedBox(width: w * 0.02),
        Text(
          'Matches ${category.label} · ${category.range}',
          style: TextStyle(
            fontSize: w * 0.031,
            fontWeight: FontWeight.w600,
            color: category.accent,
          ),
        ),
      ],
    );
  }
}

// ── Over-limit warning ────────────────────────────────────────────────────────

class _OverLimitWarning extends StatelessWidget {
  final double w;
  const _OverLimitWarning({required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.04,
        vertical: w * 0.025,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(w * 0.025),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedInformationCircle,
            color: AppColors.error,
            size: w * 0.04,
          ),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Text(
              'Weight exceeds 20 kg. We can\'t deliver items over this limit.',
              style: TextStyle(
                fontSize: w * 0.031,
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Max weight info note ──────────────────────────────────────────────────────

class _MaxWeightNote extends StatelessWidget {
  final double w;
  const _MaxWeightNote({required this.w});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HugeIcon(
          icon: HugeIcons.strokeRoundedInformationCircle,
          color: AppColors.textHint,
          size: w * 0.038,
        ),
        SizedBox(width: w * 0.02),
        Text(
          'Maximum delivery weight: 20 kg',
          style: TextStyle(fontSize: w * 0.03, color: AppColors.textHint),
        ),
      ],
    );
  }
}

// ── Empty image slot ──────────────────────────────────────────────────────────

class _EmptyImageSlot extends StatelessWidget {
  final bool isPicking;
  final VoidCallback onTap;
  final double w;

  const _EmptyImageSlot({
    required this.isPicking,
    required this.onTap,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPicking ? null : onTap,
      child: Container(
        height: w * 0.52,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.04),
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
          ),
        ),
        child: isPicking
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(w * 0.045),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCamera01,
                      color: AppColors.primary,
                      size: w * 0.08,
                    ),
                  ),
                  SizedBox(height: w * 0.04),
                  Text(
                    'Tap to add photos',
                    style: TextStyle(
                      fontSize: w * 0.04,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: w * 0.01),
                  Text(
                    'Select up to 5 · JPG or PNG',
                    style: TextStyle(
                      fontSize: w * 0.03,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Image grid ────────────────────────────────────────────────────────────────

class _ImageGrid extends StatelessWidget {
  final List<File> images;
  final bool canAddMore;
  final bool isPicking;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final double w;

  const _ImageGrid({
    required this.images,
    required this.canAddMore,
    required this.isPicking,
    required this.onAdd,
    required this.onRemove,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    final tileSize = (w - w * 0.1 - w * 0.03 * 2) / 3;

    return Wrap(
      spacing: w * 0.03,
      runSpacing: w * 0.03,
      children: [
        for (int i = 0; i < images.length; i++)
          _ImageThumbnail(
            file: images[i],
            index: i,
            size: tileSize,
            onRemove: onRemove,
            w: w,
          ),
        if (canAddMore)
          _AddMoreTile(
            size: tileSize,
            isPicking: isPicking,
            onTap: onAdd,
            w: w,
          ),
      ],
    );
  }
}

// ── Image thumbnail ───────────────────────────────────────────────────────────

class _ImageThumbnail extends StatelessWidget {
  final File file;
  final int index;
  final double size;
  final ValueChanged<int> onRemove;
  final double w;

  const _ImageThumbnail({
    required this.file,
    required this.index,
    required this.size,
    required this.onRemove,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(w * 0.03),
            child: Image.file(
              file,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: -(w * 0.015),
            right: -(w * 0.015),
            child: GestureDetector(
              onTap: () => onRemove(index),
              child: Container(
                width: w * 0.065,
                height: w * 0.065,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: w * 0.035,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add-more tile ─────────────────────────────────────────────────────────────

class _AddMoreTile extends StatelessWidget {
  final double size;
  final bool isPicking;
  final VoidCallback onTap;
  final double w;

  const _AddMoreTile({
    required this.size,
    required this.isPicking,
    required this.onTap,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPicking ? null : onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.03),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: isPicking
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedCamera01,
                    color: AppColors.primary,
                    size: w * 0.06,
                  ),
                  SizedBox(height: w * 0.015),
                  Text(
                    'Add more',
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

// ── Size restriction note ─────────────────────────────────────────────────────

class _SizeRestrictionNote extends StatelessWidget {
  final double w;
  final int maxImages;

  const _SizeRestrictionNote({required this.w, required this.maxImages});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.04,
        vertical: w * 0.03,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.025),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedInformationCircle,
            color: AppColors.textSecondary,
            size: w * 0.04,
          ),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Text(
              'Max $maxImages photos · 5 MB per image · JPG or PNG only',
              style: TextStyle(
                fontSize: w * 0.03,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
