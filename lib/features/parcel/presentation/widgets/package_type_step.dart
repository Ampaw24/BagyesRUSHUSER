import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import 'package:gopady/constant/app_tokens.dart';
import 'package:gopady/src/parcel/model/parcel_direction.dart';
import 'parcel_ui.dart';

class PackageTypeStep extends StatelessWidget {
  final String? selectedType;
  final ValueChanged<String> onTypeSelected;
  final ParcelDirection direction;

  const PackageTypeStep({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
    this.direction = ParcelDirection.send,
  });

  static const _options = [
    _TypeOption(
      id: 'document',
      label: 'Document',
      subtitle: 'Letters, contracts, certificates, printed files',
      icon: HugeIcons.strokeRoundedFileAttachment,
    ),
    _TypeOption(
      id: 'parcel',
      label: 'Parcel',
      subtitle: 'Boxes, bags, electronics, clothing & goods',
      icon: HugeIcons.strokeRoundedPackage,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return ListView(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.02, w * 0.05, w * 0.06),
      children: [
        ParcelStepHeader(
          title: direction.isReceive
              ? 'What are you receiving?'
              : 'What are you sending?',
          subtitle: 'Pick the option that best describes your item.',
        ),
        const ParcelGap(0.06),
        for (final option in _options) ...[
          _TypeRow(
            option: option,
            isSelected: selectedType == option.id,
            onTap: () {
              HapticFeedback.selectionClick();
              onTypeSelected(option.id);
            },
          ),
          const ParcelGap(0.03),
        ],
        const ParcelGap(0.03),
        const ParcelNote(
          icon: HugeIcons.strokeRoundedAlert02,
          tone: ParcelNoteTone.warning,
          message:
              'Illegal items can\'t be sent or received with GoPady. '
              'Hazardous or perishable items need special handling — '
              'contact support before booking.',
        ),
      ],
    );
  }
}

class _TypeOption {
  final String id;
  final String label;
  final String subtitle;
  final List<List<dynamic>> icon;

  const _TypeOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}

class _TypeRow extends StatelessWidget {
  final _TypeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeRow({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final radius = BorderRadius.circular(w * 0.045);

    return Semantics(
      selected: isSelected,
      button: true,
      child: AnimatedContainer(
        duration: AppMotion.standard,
        curve: AppMotion.outExpo,
        decoration: parcelCardDecoration(w, highlighted: isSelected).copyWith(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.04)
              : AppColors.card,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(w * 0.045),
              child: Row(
                children: [
                  ParcelIconBadge(
                    icon: option.icon,
                    active: isSelected,
                    sizeFactor: 0.13,
                  ),
                  SizedBox(width: w * 0.04),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.label,
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: w * 0.045,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: w * 0.008),
                        Text(
                          option.subtitle,
                          style: TextStyle(
                            fontSize: w * 0.031,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: w * 0.03),
                  ParcelSelectionDot(selected: isSelected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
