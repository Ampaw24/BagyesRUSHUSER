import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/features/report/domain/entities/report_reason.dart';
import 'package:bagyesrushappusernew/presentation/help_support/help_support_view.dart';

/// Step 3 — "What went wrong?"
class ReportReasonStep extends StatelessWidget {
  final List<ReportReason> reasons;
  final String? selectedCode;
  final void Function(ReportReason reason) onSelect;

  const ReportReasonStep({
    super.key,
    required this.reasons,
    required this.selectedCode,
    required this.onSelect,
  });

  bool get _showUrgentBanner =>
      selectedCode != null &&
      reasons.any((r) => r.code == selectedCode && r.isUrgent);

  Future<void> _callSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'tel',
      path: HelpSupportView.supportPhone.replaceAll(' ', ''),
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start a call on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return ListView(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.06),
      children: [
        Text(
          'What went wrong?',
          style: TextStyle(
            fontSize: w * 0.052,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: w * 0.015),
        Text(
          'Choose the reason that best matches what happened.',
          style: TextStyle(fontSize: w * 0.034, color: AppColors.textSecondary),
        ),
        SizedBox(height: w * 0.05),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reasons.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: w * 0.03,
            crossAxisSpacing: w * 0.03,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, i) {
            final reason = reasons[i];
            final isSelected = reason.code == selectedCode;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(reason);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.all(w * 0.035),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.07)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(w * 0.035),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.6 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (reason.isUrgent)
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedAlertCircle,
                        color: AppColors.error,
                        size: w * 0.045,
                      ),
                    Text(
                      reason.label,
                      style: TextStyle(
                        fontSize: w * 0.034,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (_showUrgentBanner) ...[
          SizedBox(height: w * 0.05),
          Container(
            padding: EdgeInsets.all(w * 0.04),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(w * 0.035),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedShield01,
                      color: AppColors.warning,
                      size: w * 0.045,
                    ),
                    SizedBox(width: w * 0.025),
                    Expanded(
                      child: Text(
                        'This will be reviewed urgently by our Trust & Safety team.',
                        style: TextStyle(
                          fontSize: w * 0.032,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: w * 0.03),
                GestureDetector(
                  onTap: () => _callSupport(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedCall02,
                        color: AppColors.warning,
                        size: w * 0.04,
                      ),
                      SizedBox(width: w * 0.02),
                      Text(
                        'Call Support Now',
                        style: TextStyle(
                          fontSize: w * 0.033,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
