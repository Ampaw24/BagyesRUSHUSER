import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';
import '../../../../core/widgets/custom_dialogs.dart';
import '../../model/payment_method.dart';

/// Shows the "Set as Default" / "Remove" action sheet for a saved payment
/// method and returns the chosen action ('default' | 'delete'), or null if
/// dismissed. Shared between the consumer and vendor Payment Methods screens.
Future<String?> showManagePaymentMethodSheet(
  BuildContext context,
  PaymentMethod method,
) {
  final w = MediaQuery.sizeOf(context).width;
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.06)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: w * 0.03),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: w * 0.1,
              height: w * 0.012,
              margin: EdgeInsets.only(bottom: w * 0.045),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(w * 0.01),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: w * 0.01),
              child: Text(
                method.displayTitle,
                style: TextStyle(fontSize: w * 0.042, fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(height: w * 0.02),
            if (!method.isDefault)
              _SheetAction(
                icon: Icons.star_outline_rounded,
                iconColor: AppColors.accent,
                label: 'Set as Default',
                onTap: () => Navigator.of(ctx).pop('default'),
              ),
            _SheetAction(
              icon: Icons.delete_outline_rounded,
              iconColor: AppColors.error,
              label: 'Remove',
              labelColor: AppColors.error,
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Confirmation dialog before removing a saved payment method.
Future<bool> confirmDeletePaymentMethod(BuildContext context, String title) async {
  final completer = Completer<bool>();
  CustomDialog.showConfirmation(
    context: context,
    title: 'Remove Payment Method',
    subtitle: 'Remove "$title"? This action cannot be undone.',
    confirmText: 'Remove',
    onConfirm: () => completer.complete(true),
    onCancel: () => completer.complete(false),
  );
  return completer.future;
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: w * 0.032),
        child: Row(
          children: [
            Container(
              width: w * 0.1,
              height: w * 0.1,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(w * 0.03),
              ),
              child: Icon(icon, color: iconColor, size: w * 0.05),
            ),
            SizedBox(width: w * 0.035),
            Text(
              label,
              style: TextStyle(
                fontSize: w * 0.038,
                fontWeight: FontWeight.w600,
                color: labelColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
