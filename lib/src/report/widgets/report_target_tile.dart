import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';

/// A person/place that can be reported, derived from the reporter's own
/// order history — riders and customers have no stable id elsewhere in
/// this codebase, so [orderId] is often the only reliable link back to
/// who this is.
class ReportableTarget {
  final String? targetId;
  final String name;
  final String? imageUrl;
  final String? phone;
  final String? orderId;
  final String subtitle;

  const ReportableTarget({
    this.targetId,
    required this.name,
    this.imageUrl,
    this.phone,
    this.orderId,
    required this.subtitle,
  });
}

/// Row showing who/what is being reported — used in the target picker list
/// and, in [compact] form, as a read-only summary on later steps.
class ReportTargetTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool compact;

  const ReportTargetTile({
    super.key,
    required this.name,
    required this.subtitle,
    this.imageUrl,
    this.onTap,
    this.compact = false,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final avatarSize = compact ? w * 0.11 : w * 0.13;

    final avatar = ClipRRect(
      borderRadius: BorderRadius.circular(w * 0.03),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? Image.network(
              imageUrl!,
              width: avatarSize,
              height: avatarSize,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _InitialsAvatar(
                initials: _initials,
                size: avatarSize,
              ),
            )
          : _InitialsAvatar(initials: _initials, size: avatarSize),
    );

    final content = Container(
      padding: EdgeInsets.all(w * 0.035),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Row(
        children: [
          avatar,
          SizedBox(width: w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: w * 0.038,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: w * 0.006),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: w * 0.031,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            SizedBox(width: w * 0.02),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: AppColors.textHint,
              size: w * 0.038,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(w * 0.035),
        child: content,
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;

  const _InitialsAvatar({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
