import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';

/// Displays a user's referral code with copy and share actions.
///
/// Reused by both the dedicated Refer & Earn screen and the compact teaser
/// shown in Edit Profile, so the code presentation stays consistent in one
/// place.
class ReferralCodeCard extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const ReferralCodeCard({
    super.key,
    required this.code,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              code,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: (w * 0.045).clamp(15.0, 19.0),
                letterSpacing: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: w * 0.02),
          _RoundIconButton(
            icon: HugeIcons.strokeRoundedCopy01,
            onTap: onCopy,
            w: w,
          ),
          SizedBox(width: w * 0.02),
          _RoundIconButton(
            icon: HugeIcons.strokeRoundedShare08,
            onTap: onShare,
            w: w,
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  final double w;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.all(w * 0.022),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: HugeIcon(icon: icon, color: AppColors.primary, size: w * 0.045),
      ),
    );
  }
}
