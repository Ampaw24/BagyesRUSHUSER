import 'report.dart';

/// A selectable reason category shown on the "What went wrong?" step.
///
/// Reasons are a fixed set of categories, not dynamic content, so they're
/// kept as a static map rather than fetched from an endpoint.
class ReportReason {
  final String code;
  final String label;

  /// Flags reasons that should surface the urgent/safety banner and the
  /// "Call Support Now" shortcut on the reason step.
  final bool isUrgent;

  const ReportReason({
    required this.code,
    required this.label,
    this.isUrgent = false,
  });
}

abstract final class ReportReasons {
  static const Map<ReportTargetType, List<ReportReason>> byTargetType = {
    ReportTargetType.vendor: [
      ReportReason(code: 'poor_food_quality', label: 'Poor food quality'),
      ReportReason(code: 'wrong_items', label: 'Wrong items received'),
      ReportReason(
        code: 'hygiene_issue',
        label: 'Hygiene issue',
        isUrgent: true,
      ),
      ReportReason(code: 'overcharged', label: 'Overcharged'),
      ReportReason(code: 'vendor_other', label: 'Something else'),
    ],
    ReportTargetType.rider: [
      ReportReason(
        code: 'rider_unsafe',
        label: 'Rider was rude or unsafe',
        isUrgent: true,
      ),
      ReportReason(code: 'rider_late', label: 'Took too long to deliver'),
      ReportReason(
        code: 'rider_never_arrived',
        label: 'Never delivered my order',
      ),
      ReportReason(code: 'rider_mishandled', label: 'Mishandled my order'),
      ReportReason(code: 'rider_other', label: 'Something else'),
    ],
    ReportTargetType.customer: [
      ReportReason(
        code: 'customer_abusive',
        label: 'Abusive behavior',
        isUrgent: true,
      ),
      ReportReason(
        code: 'customer_false_complaint',
        label: 'False complaint',
      ),
      ReportReason(code: 'customer_refused', label: 'Refused delivery'),
      ReportReason(code: 'customer_other', label: 'Something else'),
    ],
    ReportTargetType.orderIssue: [
      ReportReason(code: 'missing_items', label: 'Missing items'),
      ReportReason(code: 'wrong_order', label: 'Wrong order'),
      ReportReason(code: 'payment_issue', label: 'Payment or refund issue'),
      ReportReason(code: 'order_other', label: 'Something else'),
    ],
    ReportTargetType.general: [
      ReportReason(code: 'app_bug', label: 'App problem or bug'),
      ReportReason(code: 'general_other', label: 'Something else'),
    ],
  };

  static List<ReportReason> forTargetType(ReportTargetType type) =>
      byTargetType[type] ?? const [];
}
