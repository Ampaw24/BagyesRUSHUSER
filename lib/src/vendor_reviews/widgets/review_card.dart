import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import '../models/review.dart';
import 'rating_stars.dart';
import 'reply_composer_sheet.dart';

/// Same hand-rolled relative-time idiom as `report_card.dart`'s
/// `reportRelativeTime` — no `intl` dependency in this app.
String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}

/// Row in the vendor reviews list — customer, rating, comment, and either
/// the vendor's existing reply (read-only — see [ReplyComposerSheet]'s doc
/// on why there's no edit affordance) or a Reply button.
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review, this.isReplying = false});

  final Review review;
  final bool isReplying;

  String get _initials {
    final parts = review.customerName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final second =
        parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(w),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.customerName,
                            style: TextStyle(
                              fontSize: w * 0.037,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: 'Mukta',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: w * 0.02),
                        Text(
                          _timeAgo(review.createdAt),
                          style: TextStyle(
                            fontSize: w * 0.027,
                            color: AppColors.textHint,
                            fontFamily: 'Mukta',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: w * 0.012),
                    RatingStars(rating: review.rating, size: w * 0.034),
                  ],
                ),
              ),
            ],
          ),
          if (!review.isVisible) ...[
            SizedBox(height: w * 0.025),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.025,
                vertical: w * 0.01,
              ),
              decoration: BoxDecoration(
                color: AppColors.textHint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(w * 0.02),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_off_rounded,
                    size: w * 0.03,
                    color: AppColors.textHint,
                  ),
                  SizedBox(width: w * 0.012),
                  Text(
                    'Hidden by admin',
                    style: TextStyle(
                      fontSize: w * 0.026,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHint,
                      fontFamily: 'Mukta',
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
            SizedBox(height: w * 0.03),
            Text(
              review.comment!,
              style: TextStyle(
                fontSize: w * 0.034,
                color: AppColors.textPrimary,
                fontFamily: 'Mukta',
                height: 1.4,
              ),
            ),
          ],
          SizedBox(height: w * 0.035),
          if (review.hasReply)
            _ReplyBubble(review: review, w: w)
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isReplying
                    ? null
                    : () => ReplyComposerSheet.show(context, review),
                child: isReplying
                    ? SizedBox(
                        width: w * 0.04,
                        height: w * 0.04,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Reply'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _avatar(double w) {
    final size = w * 0.11;
    final avatarUrl = review.customerAvatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              _InitialsAvatar(initials: _initials, size: size),
        ),
      );
    }
    return _InitialsAvatar(initials: _initials, size: size);
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          fontFamily: 'Mukta',
        ),
      ),
    );
  }
}

class _ReplyBubble extends StatelessWidget {
  const _ReplyBubble({required this.review, required this.w});

  final Review review;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: w * 0.06),
      padding: EdgeInsets.all(w * 0.03),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Your reply',
                style: TextStyle(
                  fontSize: w * 0.03,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFamily: 'Mukta',
                ),
              ),
              if (review.repliedAt != null) ...[
                SizedBox(width: w * 0.02),
                Text(
                  _timeAgo(review.repliedAt!),
                  style: TextStyle(
                    fontSize: w * 0.026,
                    color: AppColors.textHint,
                    fontFamily: 'Mukta',
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: w * 0.01),
          Text(
            review.reply!,
            style: TextStyle(
              fontSize: w * 0.033,
              color: AppColors.textSecondary,
              fontFamily: 'Mukta',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
