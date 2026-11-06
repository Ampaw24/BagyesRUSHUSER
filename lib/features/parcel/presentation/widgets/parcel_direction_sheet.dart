import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import '../../../../core/router/app_navigator.dart';
import 'package:gopady/src/parcel/model/parcel_direction.dart';
import 'package:gopady/constant/app_tokens.dart';
import 'parcel_ui.dart';

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
          const ParcelStepHeader(
            title: 'Parcel delivery',
            subtitle: 'Same-day delivery across town by a vetted rider.',
          ),
          SizedBox(height: w * 0.05),
          _DirectionCard(
            icon: HugeIcons.strokeRoundedPackageSent,
            title: 'Send a parcel',
            subtitle:
                'A rider picks it up from you and delivers it to one or '
                'more people.',
            onTap: () => onSelected(ParcelDirection.send),
          ),
          SizedBox(height: w * 0.035),
          _DirectionCard(
            icon: HugeIcons.strokeRoundedPackageReceive,
            title: 'Receive a parcel',
            subtitle:
                'A rider collects it from someone else and brings it '
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
      borderRadius: BorderRadius.circular(w * 0.045),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(w * 0.045),
        child: Container(
          padding: EdgeInsets.all(w * 0.04),
          decoration: parcelCardDecoration(
            w,
          ).copyWith(color: Colors.transparent),
          child: Row(
            children: [
              ParcelIconBadge(icon: icon, active: true, sizeFactor: 0.13),
              SizedBox(width: w * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: w * 0.042,
                        fontWeight: FontWeight.w600,
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
                icon: HugeIcons.strokeRoundedArrowRight02,
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
