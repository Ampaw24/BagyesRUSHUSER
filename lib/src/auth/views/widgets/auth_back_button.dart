import 'package:flutter/material.dart';

import 'package:gopady/constant/app_theme.dart';
import 'package:gopady/core/router/app_navigator.dart';

/// Back arrow for auth entry screens (login, role picker). Returns to the
/// screen the user came from — e.g. a guest's sign-in prompt — or to the
/// welcome screen when there's nothing to pop.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, this.onPressed, this.onDark = false});

  /// Overrides the default pop-or-welcome behaviour.
  final VoidCallback? onPressed;

  /// Glass styling for forest surfaces.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    return Semantics(
      button: true,
      label: 'Back',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed ?? () => AppNavigator.backOrWelcome(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Container(
              padding: EdgeInsets.all(sw * 0.018),
              decoration: BoxDecoration(
                color: onDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(sw * 0.022),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: (sw * 0.045).clamp(16.0, 22.0),
                color: onDark ? AppColors.onDark : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
