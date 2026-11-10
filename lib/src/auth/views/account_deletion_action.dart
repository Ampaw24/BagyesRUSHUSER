import 'package:flutter/material.dart';

import 'package:gopady/core/router/app_navigator.dart';
import 'package:gopady/core/widgets/custom_dialogs.dart';
import 'package:gopady/src/legal/models/legal_document.dart';

/// The single "Delete Account" entry point for every role: warns the user,
/// then opens the account-deletion page on the GoPady website, where the
/// deletion itself happens.
void confirmAccountDeletion(BuildContext context) {
  CustomDialog.showConfirmation(
    context: context,
    title: 'Delete Account',
    subtitle: "You'll finish on the GoPady website, where you confirm with "
        'your phone number. Deleting your account is permanent: your data '
        'cannot be recovered.',
    confirmText: 'Continue',
    cancelText: 'Cancel',
    onConfirm: () => AppNavigator.toLegal(context, LegalDocument.deleteAccount),
  );
}
