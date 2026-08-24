import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../constant/app_theme.dart';

/// Custom-styled bottom sheet with a single destructive action, used across
/// the app for "delete this item" confirmations (e.g. notifications).
class DeleteActionSheet {
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onDelete,
    String label = 'Delete notification',
  }) {
    final w = MediaQuery.sizeOf(context).width;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.05)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: w * 0.03),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: w * 0.12,
                  height: 4,
                  margin: EdgeInsets.only(bottom: w * 0.05),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    color: AppColors.error,
                    size: w * 0.055,
                  ),
                  title: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: w * 0.038,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
