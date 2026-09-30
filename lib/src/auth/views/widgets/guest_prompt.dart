import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';

/// Sign-in call to action for guests — the body of the login prompt sheet
/// (see AuthGate) and the stand-in for account-only tabs like Orders.
class GuestPrompt extends StatelessWidget {
  const GuestPrompt({
    super.key,
    required this.title,
    required this.message,
    required this.onSignIn,
    required this.onCreateAccount,
    this.onDismiss,
    this.icon = HugeIcons.strokeRoundedLogin01,
  });

  final String title;
  final String message;
  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;

  /// Adds a "Not now" button — for the dismissible sheet, not a tab.
  final VoidCallback? onDismiss;
  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular((w * 0.035).clamp(10.0, 16.0)),
    );
    final buttonPadding = EdgeInsets.symmetric(
      vertical: (w * 0.038).clamp(12.0, 18.0),
    );
    final buttonTextStyle = TextStyle(
      fontSize: (w * 0.04).clamp(14.0, 18.0),
      fontWeight: FontWeight.w700,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all((w * 0.045).clamp(14.0, 24.0)),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: HugeIcon(
            icon: icon,
            color: AppColors.primary,
            size: (w * 0.085).clamp(28.0, 44.0),
          ),
        ),
        SizedBox(height: w * 0.045),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: (w * 0.05).clamp(18.0, 26.0),
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: w * 0.02),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: (w * 0.035).clamp(13.0, 17.0),
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        SizedBox(height: w * 0.06),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onSignIn,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: buttonPadding,
              shape: buttonShape,
            ),
            child: Text('Sign in', style: buttonTextStyle),
          ),
        ),
        SizedBox(height: w * 0.03),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onCreateAccount,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: buttonPadding,
              shape: buttonShape,
            ),
            child: Text('Create account', style: buttonTextStyle),
          ),
        ),
        if (onDismiss != null) ...[
          SizedBox(height: w * 0.015),
          TextButton(
            onPressed: onDismiss,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: Text(
              'Not now',
              style: buttonTextStyle.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}
