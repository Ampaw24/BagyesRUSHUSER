import 'package:bagyesrushappusernew/src/report/model/report.dart';

/// Pre-fill passed via `extra:` when pushing [AppRoutes.reportFlow].
/// Contextual entry points (an order card, a notification) set [targetType]
/// and/or the target fields so the wizard can skip straight to the reason
/// step; the primary entry point (Profile/Drawer) leaves them null.
class ReportFlowArgs {
  final ReportRole role;
  final ReportTargetType? targetType;
  final String? orderId;
  final String? targetId;
  final String? targetName;
  final String? targetImageUrl;
  final String? targetPhone;

  const ReportFlowArgs({
    required this.role,
    this.targetType,
    this.orderId,
    this.targetId,
    this.targetName,
    this.targetImageUrl,
    this.targetPhone,
  });
}
