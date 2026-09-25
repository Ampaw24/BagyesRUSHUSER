import 'package:flutter/material.dart';

import '../../constant/app_theme.dart';

/// Prompts the signed-in user to re-enter their password to confirm a
/// sensitive action (e.g. changing payout details). Returns the entered
/// password, or `null` if the user cancelled.
Future<String?> promptCurrentPassword(
  BuildContext context, {
  String title = 'Confirm Your Password',
  String message = 'For your security, please re-enter your password to continue.',
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _PasswordConfirmDialog(title: title, message: message),
  );
}

class _PasswordConfirmDialog extends StatefulWidget {
  final String title;
  final String message;

  const _PasswordConfirmDialog({required this.title, required this.message});

  @override
  State<_PasswordConfirmDialog> createState() => _PasswordConfirmDialogState();
}

class _PasswordConfirmDialogState extends State<_PasswordConfirmDialog> {
  late final TextEditingController _controller;
  bool _obscure = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.isEmpty) {
      setState(() => _errorText = 'Enter your password');
      return;
    }
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(w * 0.04),
      ),
      title: Text(
        widget.title,
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
            widget.message,
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: w * 0.034,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: w * 0.04),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            autofocus: true,
            textInputAction: TextInputAction.done,
            style: TextStyle(fontFamily: 'Mukta', fontSize: w * 0.038),
            decoration: InputDecoration(
              hintText: 'Password',
              errorText: _errorText,
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
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textHint,
                  size: w * 0.05,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          onPressed: _submit,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
