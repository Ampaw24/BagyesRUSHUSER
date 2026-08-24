import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/router/app_navigator.dart';
import 'package:bagyesrushappusernew/features/report/domain/entities/report.dart';
import 'package:bagyesrushappusernew/features/report/presentation/report_flow_args.dart';
import 'package:bagyesrushappusernew/features/report/presentation/widgets/report_card.dart';

/// Bottom sheet offering quick, order-scoped report actions — shown from an
/// order card. Skips the wizard's type/target steps since both are already
/// known from the order.
class ReportQuickActionSheet {
  static Future<void> show(
    BuildContext context, {
    required ReportRole role,
    required String orderId,
    ReportFlowArgs? primaryTarget,
    ReportFlowArgs? riderTarget,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.05)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: w * 0.03),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: w * 0.12,
                height: 4,
                margin: EdgeInsets.only(bottom: w * 0.04),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (primaryTarget != null)
                _Tile(
                  icon: targetTypeIcon(primaryTarget.targetType!),
                  label: primaryTarget.targetType == ReportTargetType.vendor
                      ? 'Report the Restaurant'
                      : 'Report the Customer',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    AppNavigator.toReportFlow(context, args: primaryTarget);
                  },
                ),
              if (riderTarget != null)
                _Tile(
                  icon: targetTypeIcon(ReportTargetType.rider),
                  label: 'Report the Rider',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    AppNavigator.toReportFlow(context, args: riderTarget);
                  },
                ),
              _Tile(
                icon: targetTypeIcon(ReportTargetType.orderIssue),
                label: 'Report an Order Issue',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  AppNavigator.toReportFlow(
                    context,
                    args: ReportFlowArgs(
                      role: role,
                      targetType: ReportTargetType.orderIssue,
                      orderId: orderId,
                      targetName: 'Order #$orderId',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  const _Tile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return ListTile(
      leading: HugeIcon(icon: icon, color: AppColors.primary, size: w * 0.055),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Mukta',
          fontSize: w * 0.038,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}
