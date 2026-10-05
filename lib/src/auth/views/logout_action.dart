import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_viewmodel.dart';

/// The single logout entry point for every role: asks for confirmation,
/// then runs [performLogout].
void confirmLogout(BuildContext context) {
  CustomDialog.showConfirmation(
    context: context,
    title: 'Log out?',
    subtitle: 'Are you sure you want to log out?',
    confirmText: 'Log out',
    cancelText: 'Cancel',
    onConfirm: () => performLogout(context),
  );
}

/// Ends the session, then lands on login.
Future<void> performLogout(BuildContext context) async {
  await context.read<AuthViewmodel>().logout();
  // On an account-only route the router's auth redirect has already moved
  // to login and unmounted this context — nothing left to do then.
  if (context.mounted) context.go(AppRoutes.login);
}
