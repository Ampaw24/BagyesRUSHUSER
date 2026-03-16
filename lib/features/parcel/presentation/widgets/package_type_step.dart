import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';

class PackageTypeStep extends StatelessWidget {
  final String? selectedType;
  final ValueChanged<String> onTypeSelected;

  const PackageTypeStep({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return ListView(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.02, w * 0.05, w * 0.04),
      children: [
        Text(
          'What are you sending?',
          style: TextStyle(
            fontSize: w * 0.055,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: w * 0.02),
        Text(
          'Choose the type that best describes your item.',
          style: TextStyle(fontSize: w * 0.035, color: AppColors.textSecondary),
        ),
        SizedBox(height: w * 0.06),
        Row(
          children: [
            _TypeCard(
              type: 'document',
              label: 'Document',
              subtitle: 'Letters, contracts\n& printed files',
              icon: HugeIcons.strokeRoundedTextAlignLeft01,
              isSelected: selectedType == 'document',
              onTap: () => onTypeSelected('document'),
            ),
            SizedBox(width: w * 0.04),
            _TypeCard(
              type: 'parcel',
              label: 'Parcel',
              subtitle: 'Items, goods\n& packages',
              icon: HugeIcons.strokeRoundedDeliveryBox01,
              isSelected: selectedType == 'parcel',
              onTap: () => onTypeSelected('parcel'),
            ),
          ],
        ),
        SizedBox(height: w * 0.06),
        _InfoBanner(w: w),
      ],
    );
  }
}

// ── Type selection card ───────────────────────────────────────────────────────

class _TypeCard extends StatelessWidget {
  final String type;
  final String label;
  final String subtitle;
  final List<List<dynamic>> icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.type,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(w * 0.05),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.06)
                : AppColors.card,
            borderRadius: BorderRadius.circular(w * 0.04),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(w * 0.03),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(w * 0.03),
                    ),
                    child: HugeIcon(
                      icon: icon,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: w * 0.07,
                    ),
                  ),
                  SizedBox(height: w * 0.04),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: w * 0.045,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: w * 0.01),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: w * 0.028,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              if (isSelected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(w * 0.008),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                      color: Colors.white,
                      size: w * 0.035,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Info banner ───────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final double w;
  const _InfoBanner({required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedInformationCircle,
            color: AppColors.info,
            size: w * 0.045,
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Text(
              'Fragile or hazardous items may require special handling. '
              'Contact support before booking.',
              style: TextStyle(
                fontSize: w * 0.032,
                color: AppColors.info,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
