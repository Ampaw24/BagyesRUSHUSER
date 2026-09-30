import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/auth/views/widgets/guest_prompt.dart';

enum LoginPromptChoice { signIn, createAccount }

/// Bottom sheet shown when a guest reaches an account feature. Resolves to
/// the option they picked, or null for "Not now"/dismissed.
class LoginPromptSheet extends StatelessWidget {
  const LoginPromptSheet({super.key, this.reason});

  /// Why an account is needed here, e.g. "Sign in to add items to your
  /// cart." Falls back to a generic line.
  final String? reason;

  static Future<LoginPromptChoice?> show(
    BuildContext context, {
    String? reason,
  }) {
    return showModalBottomSheet<LoginPromptChoice>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.scaffold,
      builder: (_) => LoginPromptSheet(reason: reason),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final horizontalPadding = w > 600 ? w * 0.12 : w * 0.06;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        w * 0.03 + bottomInset,
      ),
      child: GuestPrompt(
        title: 'Sign in to continue',
        message: reason ?? 'You need a bagyesRUSH account for this.',
        onSignIn: () => Navigator.pop(context, LoginPromptChoice.signIn),
        onCreateAccount: () =>
            Navigator.pop(context, LoginPromptChoice.createAccount),
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }
}
