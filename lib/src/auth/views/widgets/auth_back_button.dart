import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/core/router/app_navigator.dart';

/// Back arrow for auth entry screens (login, role picker). Returns to the
/// screen the user came from — e.g. a guest's sign-in prompt — or to the
/// welcome screen when there's nothing to pop.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, this.onPressed});

  /// Overrides the default pop-or-welcome behaviour.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      onTap: onPressed ?? () => AppNavigator.backOrWelcome(context),
      child: Container(
        padding: EdgeInsets.all(sw * 0.018),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(sw * 0.022),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: (sw * 0.045).clamp(16.0, 22.0),
          color: Colors.black87,
        ),
      ),
    );
  }
}
