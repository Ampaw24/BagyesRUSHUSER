import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import '../../../../core/router/app_navigator.dart';
import 'package:bagyesrushappusernew/src/parcel/model/parcel_direction.dart';

/// Entry point for the parcel wizard: lets the customer choose whether
/// they are sending a package or having one brought to them.
Future<void> showParcelDirectionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _ParcelDirectionSheet(
      onSelected: (direction) {
        Navigator.pop(sheetContext);
        AppNavigator.toSendPackages(context, direction: direction);
      },
    ),
  );
}

class _ParcelDirectionSheet extends StatelessWidget {
  final ValueChanged<ParcelDirection> onSelected;

  const _ParcelDirectionSheet({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        w * 0.05,
        w * 0.03,
        w * 0.05,
        w * 0.05 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: AppColors.scaffold,
        borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.06)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: w * 0.12,
              height: w * 0.012,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(w * 0.01),
              ),
            ),
          ),
          SizedBox(height: w * 0.05),
          Text(
            'Parcel delivery',
            style: TextStyle(
              fontSize: w * 0.05,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.01),
          Text(
            'What would you like to do?',
            style: TextStyle(fontSize: w * 0.034, color: AppColors.textSecondary),
          ),
          SizedBox(height: w * 0.05),
          _DirectionCard(
            icon: HugeIcons.strokeRoundedPackageSent,
            title: 'Send a parcel',
            subtitle: 'A rider picks it up from you and delivers it to one or '
                'more people.',
            onTap: () => onSelected(ParcelDirection.send),
          ),
          SizedBox(height: w * 0.035),
          _DirectionCard(
            icon: HugeIcons.strokeRoundedPackageReceive,
            title: 'Receive a parcel',
            subtitle: 'A rider collects it from someone else and brings it '
                'to you.',
            onTap: () => onSelected(ParcelDirection.receive),
          ),
        ],
      ),
    );
  }
}

class _DirectionCard extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DirectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(w * 0.04),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(w * 0.04),
        child: Container(
          padding: EdgeInsets.all(w * 0.04),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(w * 0.04),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.03),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
                child: HugeIcon(
                  icon: icon,
                  color: AppColors.primary,
                  size: w * 0.07,
                ),
              ),
              SizedBox(width: w * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: w * 0.04,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: w * 0.008),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: w * 0.03,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: w * 0.02),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: AppColors.textHint,
                size: w * 0.05,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
