import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/report/model/report.dart';

class _TypeOption {
  final ReportTargetType type;
  final String title;
  final String subtitle;
  final List<List<dynamic>> icon;

  const _TypeOption({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// Step 1 — "What would you like to report?"
class ReportTargetTypeStep extends StatelessWidget {
  final ReportRole role;
  final bool riderAvailable;
  final ValueChanged<ReportTargetType> onSelect;

  const ReportTargetTypeStep({
    super.key,
    required this.role,
    required this.riderAvailable,
    required this.onSelect,
  });

  List<_TypeOption> get _options {
    final isVendor = role == ReportRole.vendor;
    return [
      if (!isVendor)
        const _TypeOption(
          type: ReportTargetType.vendor,
          title: 'A Vendor',
          subtitle: 'Restaurant or food quality issue',
          icon: HugeIcons.strokeRoundedStore01,
        ),
      if (isVendor)
        const _TypeOption(
          type: ReportTargetType.customer,
          title: 'A Customer',
          subtitle: 'Abusive behavior or false complaint',
          icon: HugeIcons.strokeRoundedUserBlock01,
        ),
      if (riderAvailable)
        const _TypeOption(
          type: ReportTargetType.rider,
          title: 'A Delivery Rider',
          subtitle: 'Rider behavior or delivery issue',
          icon: HugeIcons.strokeRoundedMotorbike01,
        ),
      const _TypeOption(
        type: ReportTargetType.orderIssue,
        title: 'An Order Problem',
        subtitle: 'Missing items, wrong order, or payment',
        icon: HugeIcons.strokeRoundedReceiptDollar,
      ),
      const _TypeOption(
        type: ReportTargetType.general,
        title: 'Something Else',
        subtitle: 'App issue or other concern',
        icon: HugeIcons.strokeRoundedMessageQuestion,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final options = _options;

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
          itemBuilder: (context, i) => _TypeCard(
            option: options[i],
            w: w,
            onTap: () {
              HapticFeedback.lightImpact();
              onSelect(options[i].type);
            },
          ),
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final _TypeOption option;
  final double w;
  final VoidCallback onTap;

  const _TypeCard({required this.option, required this.w, required this.onTap});

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
                icon: option.icon,
                color: AppColors.primary,
                size: w * 0.065,
              ),
            ),
            const Spacer(),
            Text(
              option.title,
              style: TextStyle(
                fontSize: w * 0.038,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.01),
            Text(
              option.subtitle,
              style: TextStyle(
                fontSize: w * 0.028,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
