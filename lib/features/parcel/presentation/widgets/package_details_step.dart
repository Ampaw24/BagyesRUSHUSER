import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../constant/app_theme.dart';

// 5 MB size cap per image
const _maxFileSizeBytes = 5 * 1024 * 1024;

class PackageDetailsStep extends StatefulWidget {
  final List<File> images;
  final String weightText;
  final void Function(List<File> files, List<String> base64List) onImagesAdded;
  final ValueChanged<int> onImageRemoved;
  final ValueChanged<String> onWeightChanged;
  final int maxImages;

  const PackageDetailsStep({
    super.key,
    required this.images,
    required this.weightText,
    required this.onImagesAdded,
    required this.onImageRemoved,
    required this.onWeightChanged,
    required this.maxImages,
  });

  @override
  State<PackageDetailsStep> createState() => _PackageDetailsStepState();
}

class _PackageDetailsStepState extends State<PackageDetailsStep> {
  late final TextEditingController _weightCtrl;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: widget.weightText);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

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
          'Add up to ${widget.maxImages} photos and the package weight.',
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
          _EmptyImageSlot(
            isPicking: _isPicking,
            onTap: _pickImages,
            w: w,
          )
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

        SizedBox(height: w * 0.07),

        // ── Weight section ────────────────────────────────────────────────────
        _sectionLabel('Package Weight', w),
        SizedBox(height: w * 0.03),
        _WeightField(
          controller: _weightCtrl,
          onChanged: widget.onWeightChanged,
          w: w,
        ),
        SizedBox(height: w * 0.025),
        Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedInformationCircle,
              color: AppColors.textHint,
              size: w * 0.038,
            ),
            SizedBox(width: w * 0.02),
            Text(
              'Maximum weight: 20 kg per delivery',
              style: TextStyle(fontSize: w * 0.03, color: AppColors.textHint),
            ),
          ],
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

// ── Empty slot (no images yet) ────────────────────────────────────────────────

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

// ── Image grid (thumbnails + add-more tile) ───────────────────────────────────

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

// ── Individual thumbnail ──────────────────────────────────────────────────────

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
          // Remove button
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

// ── Weight field ──────────────────────────────────────────────────────────────

class _WeightField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final double w;

  const _WeightField({
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
