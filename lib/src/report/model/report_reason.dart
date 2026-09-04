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

/// `reason_code` values are constrained by the backend to a fixed list (see
/// the `reason_code` field rule in `reportapis.md`); every code below is
/// taken verbatim from that list and grouped here by which UI category best
/// fits it.
abstract final class ReportReasons {
  static const Map<ReportTargetType, List<ReportReason>> byTargetType = {
    ReportTargetType.vendor: [
      ReportReason(code: 'food_quality', label: 'Poor food quality'),
      ReportReason(code: 'wrong_items', label: 'Wrong items received'),
      ReportReason(code: 'hygiene', label: 'Hygiene issue', isUrgent: true),
      ReportReason(code: 'long_wait', label: 'Took too long to prepare'),
      ReportReason(code: 'overcharged', label: 'Overcharged'),
      ReportReason(code: 'rude_staff', label: 'Rude staff'),
      ReportReason(code: 'other', label: 'Something else'),
    ],
    ReportTargetType.rider: [
      ReportReason(
        code: 'rider_unsafe',
        label: 'Rider was rude or unsafe',
        isUrgent: true,
      ),
      ReportReason(code: 'late_delivery', label: 'Took too long to deliver'),
      ReportReason(code: 'never_arrived', label: 'Never delivered my order'),
      ReportReason(code: 'damaged_items', label: 'Mishandled my order'),
      ReportReason(code: 'wrong_address', label: 'Delivered to wrong address'),
      ReportReason(code: 'other', label: 'Something else'),
    ],
    ReportTargetType.customer: [
      ReportReason(code: 'abusive', label: 'Abusive behavior', isUrgent: true),
      ReportReason(code: 'refused_delivery', label: 'Refused delivery'),
      ReportReason(code: 'unreachable', label: 'Customer unreachable'),
      ReportReason(code: 'fraud', label: 'Suspected fraud'),
      ReportReason(code: 'other', label: 'Something else'),
    ],
    ReportTargetType.orderIssue: [
      ReportReason(code: 'missing_items', label: 'Missing items'),
      ReportReason(code: 'wrong_order', label: 'Wrong order'),
      ReportReason(code: 'extra_charge', label: 'Extra charge'),
      ReportReason(code: 'charged_incorrectly', label: 'Charged incorrectly'),
      ReportReason(code: 'refund_not_received', label: 'Refund not received'),
      ReportReason(code: 'other', label: 'Something else'),
    ],
    ReportTargetType.general: [
      ReportReason(code: 'app_problem', label: 'App problem or bug'),
      ReportReason(code: 'payment_problem', label: 'Payment problem'),
      ReportReason(code: 'account_problem', label: 'Account problem'),
      ReportReason(code: 'feedback', label: 'General feedback'),
      ReportReason(code: 'other', label: 'Something else'),
    ],
  };

  static List<ReportReason> forTargetType(ReportTargetType type) =>
      byTargetType[type] ?? const [];
}
