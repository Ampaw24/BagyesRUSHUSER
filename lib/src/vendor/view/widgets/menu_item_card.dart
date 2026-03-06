import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../constant/app_theme.dart';
import '../../model/menu_item.dart';

const _tagMeta = <String, Map<String, dynamic>>{
  'Spicy': {'emoji': '🌶', 'color': Color(0xFFE53935)},
  'Vegan': {'emoji': '🥗', 'color': Color(0xFF43A047)},
  'Vegetarian': {'emoji': '🥦', 'color': Color(0xFF66BB6A)},
  'Gluten-Free': {'emoji': '🌾', 'color': Color(0xFFFB8C00)},
  'Bestseller': {'emoji': '⭐', 'color': Color(0xFFF59E0B)},
  'New': {'emoji': '🆕', 'color': Color(0xFF3182CE)},
  'Seasonal': {'emoji': '🌟', 'color': Color(0xFF8E24AA)},
};

// ── List-mode card ────────────────────────────────────────────────────────────

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onAvailabilityChanged;
  final ValueChanged<bool>? onFeaturedChanged;

  const MenuItemCard({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
    this.onAvailabilityChanged,
    this.onFeaturedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(
          color: item.isFeatured
              ? AppColors.accent.withValues(alpha: 0.5)
              : AppColors.border,
          width: item.isFeatured ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: w * 0.02,
            offset: Offset(0, w * 0.005),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Main row ──
          Padding(
            padding: EdgeInsets.all(w * 0.035),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ItemImage(imageUrl: item.imageUrl, size: w * 0.18),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontSize: w * 0.038,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.isOutOfStock)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: w * 0.015,
                                vertical: w * 0.005,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(w * 0.02),
                              ),
                              child: Text(
                                'Out of Stock',
                                style: TextStyle(
                                  fontSize: w * 0.024,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: w * 0.01),
                      Row(
                        children: [
                          _CategoryPill(category: item.category, w: w),
                          SizedBox(width: w * 0.02),
                          Icon(
                            Icons.access_time_rounded,
                            size: w * 0.03,
                            color: AppColors.textHint,
                          ),
                          SizedBox(width: w * 0.008),
                          Text(
                            '${item.prepTimeMinutes} min',
                            style: TextStyle(
                              fontSize: w * 0.028,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: w * 0.01),
                      Text(
                        item.price,
                        style: TextStyle(
                          fontSize: w * 0.04,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: w * 0.02),
                // Right: featured star + availability switch
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => onFeaturedChanged?.call(!item.isFeatured),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: EdgeInsets.all(w * 0.015),
                        decoration: BoxDecoration(
                          color: item.isFeatured
                              ? AppColors.accent.withValues(alpha: 0.12)
                              : AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.isFeatured
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: w * 0.045,
                          color: item.isFeatured
                              ? AppColors.accent
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                    SizedBox(height: w * 0.01),
                    Transform.scale(
                      scale: 0.8,
                      alignment: Alignment.centerRight,
                      child: Switch(
                        value: item.isAvailable,
                        onChanged: onAvailabilityChanged,
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.success,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: AppColors.border,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Bottom: tags + edit/delete ──
          if (item.tags.isNotEmpty || onEdit != null || onDelete != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                w * 0.035,
                0,
                w * 0.035,
                w * 0.025,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: w * 0.015,
                      runSpacing: w * 0.01,
                      children: item.tags
                          .take(3)
                          .map((tag) => _TagChip(tag: tag, w: w))
                          .toList(),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        _ActionIconButton(
                          icon: Icons.edit_rounded,
                          color: AppColors.info,
                          onTap: onEdit!,
                          w: w,
                        ),
                      SizedBox(width: w * 0.015),
                      if (onDelete != null)
                        _ActionIconButton(
                          icon: Icons.delete_outline_rounded,
                          color: AppColors.error,
                          onTap: onDelete!,
                          w: w,
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Grid-mode card ────────────────────────────────────────────────────────────

class MenuItemGridCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onAvailabilityChanged;
  final ValueChanged<bool>? onFeaturedChanged;

  const MenuItemGridCard({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
    this.onAvailabilityChanged,
    this.onFeaturedChanged,
  });

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder gives the actual card width regardless of the parent
    // constraint (2-column grid, featured horizontal scroll, etc.).
    // Every dimension is derived from `cw` so the card never overflows.
    return LayoutBuilder(
      builder: (context, constraints) {
        final cw = constraints.maxWidth;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(cw * 0.06),
            border: Border.all(
              color: item.isFeatured
                  ? AppColors.accent.withValues(alpha: 0.5)
                  : AppColors.border,
              width: item.isFeatured ? 1.5 : 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: cw * 0.04,
                offset: Offset(0, cw * 0.01),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Image with overlays ──────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(cw * 0.06)),
                    child: _ItemImage(
                      imageUrl: item.imageUrl,
                      size: double.infinity,
                      // Height relative to card width — fits any parent cell
                      height: cw * 0.62,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (item.isFeatured)
                    Positioned(
                      top: cw * 0.03,
                      left: cw * 0.03,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: cw * 0.04,
                          vertical: cw * 0.015,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(cw * 0.04),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                size: cw * 0.055, color: Colors.white),
                            SizedBox(width: cw * 0.015),
                            Text(
                              'Featured',
                              style: TextStyle(
                                fontSize: cw * 0.048,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!item.isAvailable || item.isOutOfStock)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(cw * 0.06)),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.45),
                          alignment: Alignment.center,
                          child: Text(
                            item.isOutOfStock
                                ? 'Out of Stock'
                                : 'Unavailable',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: cw * 0.06,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // ── Details ─────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                    cw * 0.05, cw * 0.04, cw * 0.05, cw * 0.03),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: cw * 0.08,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: cw * 0.02),
                    Row(
                      children: [
                        _CategoryPill(
                            category: item.category, w: cw, small: true),
                        const Spacer(),
                        Text(
                          item.price,
                          style: TextStyle(
                            fontSize: cw * 0.08,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: cw * 0.03),
                    // Use FittedBox to cap the Switch's intrinsic layout height
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: cw * 0.28,
                          height: cw * 0.12,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            alignment: Alignment.centerLeft,
                            child: Switch(
                              value: item.isAvailable,
                              onChanged: onAvailabilityChanged,
                              activeThumbColor: Colors.white,
                              activeTrackColor: AppColors.success,
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: AppColors.border,
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () =>
                              onFeaturedChanged?.call(!item.isFeatured),
                          child: Icon(
                            item.isFeatured
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: cw * 0.1,
                            color: item.isFeatured
                                ? AppColors.accent
                                : AppColors.textHint,
                          ),
                        ),
                        if (onEdit != null) ...[
                          SizedBox(width: cw * 0.03),
                          GestureDetector(
                            onTap: onEdit,
                            child: Icon(Icons.edit_rounded,
                                size: cw * 0.095, color: AppColors.info),
                          ),
                        ],
                        if (onDelete != null) ...[
                          SizedBox(width: cw * 0.03),
                          GestureDetector(
                            onTap: onDelete,
                            child: Icon(Icons.delete_outline_rounded,
                                size: cw * 0.095, color: AppColors.error),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _ItemImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double? height;
  final BoxFit fit;

  const _ItemImage({
    required this.imageUrl,
    required this.size,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isLocal =
        imageUrl != null && !imageUrl!.startsWith('http');
    final isNetwork =
        imageUrl != null && imageUrl!.startsWith('http');

    Widget child;
    if (isLocal) {
      child = Image.file(File(imageUrl!), fit: fit);
    } else if (isNetwork) {
      child = Image.network(
        imageUrl!,
        fit: fit,
        errorBuilder: (context, error, stack) => _placeholder(w),
      );
    } else {
      child = _placeholder(w);
    }

    return Container(
      width: size == double.infinity ? null : size,
      height: height ?? size,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.025),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _placeholder(double w) => Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedRestaurant01,
          size: w * 0.07,
          color: AppColors.textHint,
        ),
      );
}

class _CategoryPill extends StatelessWidget {
  final String category;
  final double w;
  final bool small;

  const _CategoryPill({
    required this.category,
    required this.w,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * (small ? 0.015 : 0.02),
        vertical: w * (small ? 0.005 : 0.008),
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(w * 0.02),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: w * (small ? 0.025 : 0.028),
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  final double w;

  const _TagChip({required this.tag, required this.w});

  @override
  Widget build(BuildContext context) {
    final meta = _tagMeta[tag];
    final emoji = meta?['emoji'] as String? ?? '';
    final color =
        (meta?['color'] as Color?) ?? AppColors.textSecondary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.015,
        vertical: w * 0.005,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(w * 0.02),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$emoji $tag',
        style: TextStyle(
          fontSize: w * 0.025,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double w;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(w * 0.018),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(w * 0.02),
        ),
        child: Icon(icon, size: w * 0.04, color: color),
      ),
    );
  }
}
