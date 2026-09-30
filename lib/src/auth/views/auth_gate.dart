import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/router/app_navigator.dart';
import 'package:bagyesrushappusernew/src/auth/views/widgets/login_prompt_sheet.dart';

/// Guest browsing (Apple guideline 5.1.1(v)): anyone can browse without an
/// account, and sign-in is only asked for when an account feature is used —
/// cart, orders, parcels, notifications, wallet and so on. Every
/// account-only action goes through here instead of checking the session
/// itself.
abstract final class AuthGate {
  static bool isSignedIn(BuildContext context) =>
      context.read<CurrentUserProvider>().isAuthenticated;

  /// Runs [action] straight away for a signed-in user. A guest is asked to
  /// sign in first; [action] then runs as soon as they have — no second tap
  /// — or is dropped if they back out.
  static Future<void> requireAuth(
    BuildContext context, {
    required FutureOr<void> Function() action,
    String? reason,
  }) async {
    if (isSignedIn(context)) {
      await action();
      return;
    }
    final signedIn = await showLoginPrompt(context, reason: reason);
    if (signedIn && context.mounted) await action();
  }

  /// Explains why an account is needed ([reason]) and offers sign-in or
  /// sign-up. Resolves `true` only once the guest has actually signed in —
  /// sign-up is a multi-step flow (OTP, verification) that ends on home.
  static Future<bool> showLoginPrompt(
    BuildContext context, {
    String? reason,
  }) async {
    final choice = await LoginPromptSheet.show(context, reason: reason);
    if (choice == null || !context.mounted) return false;
    switch (choice) {
      case LoginPromptChoice.signIn:
        return AppNavigator.toLoginForResult(context);
      case LoginPromptChoice.createAccount:
        AppNavigator.toCreateAccount(context);
        return false;
    }
  }
}
