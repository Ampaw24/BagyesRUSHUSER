import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/report/model/report.dart';
import 'package:bagyesrushappusernew/src/report/model/report_reason.dart';

/// Splits a [ReportTargetType]'s enum name (which mirrors the API's
/// category keys — `vendor`, `rider`, `customer`, `orderIssue`, `general`)
/// into a readable title, e.g. `orderIssue` → `Order Issue`.
String _titleFor(ReportTargetType type) {
  final name = type.name;
  final buffer = StringBuffer();
  for (var i = 0; i < name.length; i++) {
    final char = name[i];
    final isUpper = char != char.toLowerCase();
    if (i == 0) {
      buffer.write(char.toUpperCase());
    } else {
      if (isUpper) buffer.write(' ');
      buffer.write(char);
    }
  }
  return buffer.toString();
}

/// A preview of this category's actual reason labels, as returned by the
/// reasons API, so the card reflects real content instead of hand-written
/// copy.
String _subtitleFor(List<ReportReasonOption> reasons) {
  final labels = reasons.where((r) => r.code != 'other').map((r) => r.label);
  if (labels.isEmpty) return '';
  final preview = labels.take(2).join(' · ');
  return labels.length > 2 ? '$preview and more' : preview;
}

/// Per-category icon, since the reasons API has no icon field.
List<List<dynamic>> _iconFor(ReportTargetType type) => switch (type) {
  ReportTargetType.vendor => HugeIcons.strokeRoundedStore01,
  ReportTargetType.rider => HugeIcons.strokeRoundedMotorbike01,
  ReportTargetType.customer => HugeIcons.strokeRoundedUserBlock01,
  ReportTargetType.orderIssue => HugeIcons.strokeRoundedReceiptDollar,
  ReportTargetType.general => HugeIcons.strokeRoundedMessageQuestion,
};

/// Step 1 — "What would you like to report?"
class ReportTargetTypeStep extends StatelessWidget {
  final ReportRole role;
  final ReportReason? reasonCategories;
  final bool reasonsLoading;
  final String? reasonsError;
  final VoidCallback onRetry;
  final ValueChanged<ReportTargetType> onSelect;

  const ReportTargetTypeStep({
    super.key,
    required this.role,
    required this.reasonCategories,
    required this.reasonsLoading,
    required this.reasonsError,
    required this.onRetry,
    required this.onSelect,
  });

  /// Which target types are eligible for this reporter, before checking
  /// whether the API actually has reasons for them. A reporter never
  /// reports themself (a vendor can't report "vendor", a customer can't
  /// report "customer") — every other category, including `rider`, is
  /// always offered.
  List<ReportTargetType> get _eligibleTypes {
    final isVendor = role == ReportRole.vendor;
    return [
      if (!isVendor) ReportTargetType.vendor,
      ReportTargetType.rider,
      if (isVendor) ReportTargetType.customer,
      ReportTargetType.orderIssue,
      ReportTargetType.general,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final categories = reasonCategories;
    final options = categories == null
        ? const <ReportTargetType>[]
        : _eligibleTypes
              .where((t) => categories.forTargetType(t).isNotEmpty)
              .toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.06),
      children: [
        Text(
          'What would you like to report?',
          style: TextStyle(
            fontSize: w * 0.052,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: w * 0.015),
        Text(
          "We'll ask a few quick questions and route this to the right team.",
          style: TextStyle(fontSize: w * 0.034, color: AppColors.textSecondary),
        ),
        SizedBox(height: w * 0.06),
        if (reasonsLoading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: w * 0.12),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (reasonsError != null)
          Padding(
            padding: EdgeInsets.symmetric(vertical: w * 0.1),
            child: Column(
              children: [
                Text(
                  "Couldn't load report categories",
                  style: TextStyle(
                    fontSize: w * 0.04,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: w * 0.02),
                Text(
                  reasonsError!,
                  style: TextStyle(
                    fontSize: w * 0.032,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: w * 0.04),
                ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          )
        else if (options.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: w * 0.12),
            child: Center(
              child: Text(
                'No report categories available.',
                style: TextStyle(
                  fontSize: w * 0.036,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: w * 0.035,
              crossAxisSpacing: w * 0.035,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, i) {
              final type = options[i];
              return _TypeCard(
                title: _titleFor(type),
                subtitle: _subtitleFor(categories!.forTargetType(type)),
                icon: _iconFor(type),
                w: w,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSelect(type);
                },
              );
            },
          ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<List<dynamic>> icon;
  final double w;
  final VoidCallback onTap;

  const _TypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.w,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(w * 0.04),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.04),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(w * 0.028),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(w * 0.03),
              ),
              child: HugeIcon(
                icon: icon,
                color: AppColors.primary,
                size: w * 0.065,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: w * 0.038,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              SizedBox(height: w * 0.01),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: w * 0.028,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
