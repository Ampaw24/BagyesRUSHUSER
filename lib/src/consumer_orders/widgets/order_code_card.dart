import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';

/// Highlighted card for a short verification code (delivery PIN, parcel
/// collection code). Tap the code to copy; [onShare] adds a share action.
class OrderCodeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String code;
  final IconData icon;
  final String? shareLabel;
  final VoidCallback? onShare;

  const OrderCodeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.code,
    this.icon = Icons.password_rounded,
    this.shareLabel,
    this.onShare,
  });

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title copied'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: w * 0.07),
              SizedBox(width: w * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: w * 0.032,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: w * 0.008),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: w * 0.03,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: w * 0.03),
              GestureDetector(
                onTap: () => _copyCode(context),
                child: Row(
                  children: [
                    Text(
                      code,
                      style: TextStyle(
                        fontSize: w * 0.065,
                        fontWeight: FontWeight.w800,
                        letterSpacing: w * 0.012,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: w * 0.015),
                    Icon(
                      Icons.copy_rounded,
                      color: AppColors.primary,
                      size: w * 0.04,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onShare != null) ...[
            SizedBox(height: w * 0.03),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onShare,
                icon: Icon(Icons.share_rounded, size: w * 0.042),
                label: Text(shareLabel ?? 'Share'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  padding: EdgeInsets.symmetric(vertical: w * 0.028),
                  textStyle: TextStyle(
                    fontSize: w * 0.034,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(w * 0.03),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
