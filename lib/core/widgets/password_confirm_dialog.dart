import 'package:flutter/material.dart';

import '../../constant/app_theme.dart';

/// Prompts the signed-in user to re-enter their password to confirm a
/// sensitive action (e.g. changing payout details). Returns the entered
/// password, or `null` if the user cancelled.
Future<String?> promptCurrentPassword(
  BuildContext context, {
  String title = 'Confirm Your Password',
  String message = 'For your security, please re-enter your password to continue.',
}) async {
  final controller = TextEditingController();
  bool obscure = true;
  String? errorText;

  final password = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final w = MediaQuery.sizeOf(context).width;

          void submit() {
            if (controller.text.isEmpty) {
              setDialogState(() => errorText = 'Enter your password');
              return;
            }
            Navigator.of(dialogContext).pop(controller.text);
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(w * 0.04),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontFamily: 'Mukta',
                fontWeight: FontWeight.w800,
                fontSize: w * 0.045,
                color: AppColors.textPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: w * 0.034,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: w * 0.04),
                TextField(
                  controller: controller,
                  obscureText: obscure,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(fontFamily: 'Mukta', fontSize: w * 0.038),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    errorText: errorText,
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: w * 0.04,
                      vertical: w * 0.032,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textHint,
                        size: w * 0.05,
                      ),
                      onPressed: () => setDialogState(() => obscure = !obscure),
                    ),
                  ),
                  onChanged: (_) {
                    if (errorText != null) setDialogState(() => errorText = null);
                  },
                  onSubmitted: (_) => submit(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                onPressed: submit,
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    },
  );

  controller.dispose();
  return password;
}
