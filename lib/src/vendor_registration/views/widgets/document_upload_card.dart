import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';

/// Card widget for selecting and displaying a document upload
class DocumentUploadCard extends StatelessWidget {
  final String title;
  final String description;
  final String? filePath;
  final bool isRequired;
  final bool isLoading;
  final VoidCallback onTap;

  const DocumentUploadCard({
    super.key,
    required this.title,
    required this.description,
    this.filePath,
    this.isRequired = false,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hasFile = filePath != null && filePath!.isNotEmpty;
    final radius = size.width * 0.03;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(size.width * 0.04),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: hasFile
              ? AppColors.success.withValues(alpha: 0.06)
              : AppColors.surfaceVariant,
          border: Border.all(
            color: hasFile ? AppColors.success : AppColors.border,
            width: hasFile ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: size.width * 0.12,
              height: size.width * 0.12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius * 0.7),
                color: hasFile
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.08),
              ),
              child: isLoading
                  ? Padding(
                      padding: EdgeInsets.all(size.width * 0.03),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Icon(
                      hasFile
                          ? Icons.check_circle_rounded
                          : Icons.cloud_upload_outlined,
                      color: hasFile ? AppColors.success : AppColors.primary,
                      size: size.width * 0.06,
                    ),
            ),
            SizedBox(width: size.width * 0.035),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: size.width * 0.036,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isRequired) ...[
                        SizedBox(width: size.width * 0.01),
                        Text(
                          '*',
                          style: TextStyle(
                            fontSize: size.width * 0.036,
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: size.height * 0.003),
                  Text(
                    hasFile ? _fileName(filePath!) : description,
                    style: TextStyle(
                      fontSize: size.width * 0.03,
                      color: hasFile
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Trailing icon
            Icon(
              hasFile ? Icons.swap_horiz_rounded : Icons.add_rounded,
              color: AppColors.textHint,
              size: size.width * 0.055,
            ),
          ],
        ),
      ),
    );
  }

  String _fileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }
}
