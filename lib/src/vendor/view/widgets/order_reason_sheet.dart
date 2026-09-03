import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';

/// Bottom sheet collecting a required text reason (5-255 chars) before a
/// reject/cancel action. Returns the trimmed reason via [Navigator.pop], or
/// `null` if dismissed without submitting.
class OrderReasonSheet extends StatefulWidget {
  final String title;
  final String confirmLabel;

  const OrderReasonSheet({
    super.key,
    required this.title,
    this.confirmLabel = 'Submit',
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String confirmLabel = 'Submit',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          OrderReasonSheet(title: title, confirmLabel: confirmLabel),
    );
  }

  @override
  State<OrderReasonSheet> createState() => _OrderReasonSheetState();
}

class _OrderReasonSheetState extends State<OrderReasonSheet> {
  static const _minLength = 5;
  static const _maxLength = 255;

  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _controller.text.trim();
    if (reason.length < _minLength) {
      setState(
        () => _error = 'Please enter at least $_minLength characters',
      );
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          w * 0.05,
          w * 0.04,
          w * 0.05,
          w * 0.06,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: w * 0.1,
                height: w * 0.01,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(w * 0.01),
                ),
              ),
            ),
            SizedBox(height: w * 0.04),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: w * 0.045,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.03),
            TextField(
              controller: _controller,
              maxLength: _maxLength,
              maxLines: 3,
              autofocus: true,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                hintText: 'Enter a reason...',
                errorText: _error,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: w * 0.035),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(w * 0.03),
                  ),
                ),
                child: Text(
                  widget.confirmLabel,
                  style: TextStyle(
                    fontSize: w * 0.038,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
