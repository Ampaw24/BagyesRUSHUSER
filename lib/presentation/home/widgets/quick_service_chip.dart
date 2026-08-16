import 'package:flutter/material.dart';
import '../../../constant/app_theme.dart';

class QuickServiceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickServiceChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: w * 0.03),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(w * 0.03),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: w * 0.06, color: AppColors.primary),
              SizedBox(height: w * 0.01),
              Text(
                label,
                style: TextStyle(
                  fontSize: w * 0.028,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
