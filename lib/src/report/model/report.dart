import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';

/// Who is filing the report.
enum ReportRole { customer, vendor }

/// What/who is being reported.
enum ReportTargetType {
  vendor,
  rider,
  customer,
  orderIssue,
  general;

  /// The wire value for `POST .../reports`. The backend's `target_type`
  /// column only accepts `"order_issue"` or `"general"` (see
  /// `reportapis.md`) — who/what is actually being reported (vendor, rider,
  /// customer) is carried separately via `target_name`/`target_id`, not by
  /// this field.
  String get apiValue => switch (this) {
        ReportTargetType.general => 'general',
        ReportTargetType.vendor ||
        ReportTargetType.rider ||
        ReportTargetType.customer ||
        ReportTargetType.orderIssue =>
          'order_issue',
      };

  static ReportTargetType fromString(String value) {
    switch (value) {
      case 'vendor':
        return ReportTargetType.vendor;
      case 'rider':
        return ReportTargetType.rider;
      case 'customer':
        return ReportTargetType.customer;
      case 'order_issue':
        return ReportTargetType.orderIssue;
      default:
        return ReportTargetType.general;
    }
  }

  /// Whether reporting this category requires identifying a specific
  /// vendor/rider/customer. `orderIssue` and `general` reports are about
  /// the order or the app as a whole, not a person, so the wizard skips
  /// the target-picker step for them entirely.
  bool get requiresTarget => switch (this) {
        ReportTargetType.vendor ||
        ReportTargetType.rider ||
        ReportTargetType.customer =>
          true,
        ReportTargetType.orderIssue || ReportTargetType.general => false,
      };
}

enum ReportStatus {
  pending('Pending', AppColors.warning),
  inReview('In Review', AppColors.info),
  resolved('Resolved', AppColors.success),
  dismissed('Dismissed', AppColors.textHint);

  final String label;
  final Color color;
  const ReportStatus(this.label, this.color);

  /// Falls back to [pending] for unrecognized values rather than throwing —
  /// verify against a real `GET .../reports` response and adjust if the
  /// backend uses different string values.
  static ReportStatus fromString(String value) {
    switch (value) {
      case 'in_review':
      case 'reviewing':
        return ReportStatus.inReview;
      case 'resolved':
        return ReportStatus.resolved;
      case 'dismissed':
      case 'rejected':
        return ReportStatus.dismissed;
      default:
        return ReportStatus.pending;
    }
  }
}

class Report extends Equatable {
  final String id;
  final ReportRole reporterRole;
  final ReportTargetType targetType;

  /// The order this report is about, when known. Riders and customers have
  /// no stable id elsewhere in this codebase, so the order is often the
  /// only reliable link back to who/what is being reported.
  final String? orderId;

  /// Only populated when a real id exists (e.g. a restaurant id).
  final String? targetId;
  final String targetName;
  final String? targetImageUrl;
  final String? targetPhone;

  final String reasonCode;
  final String reasonLabel;
  final String description;
  final List<String> attachmentUrls;
  final ReportStatus status;
  final DateTime createdAt;
  final String? resolutionNote;

  const Report({
    required this.id,
    required this.reporterRole,
    required this.targetType,
    this.orderId,
    this.targetId,
    required this.targetName,
    this.targetImageUrl,
    this.targetPhone,
    required this.reasonCode,
    required this.reasonLabel,
    required this.description,
    this.attachmentUrls = const [],
    required this.status,
    required this.createdAt,
    this.resolutionNote,
  });

  /// [role] is the role the request was made under (the endpoint itself is
  /// role-scoped — `customer/reports` vs `vendor/me/reports`) — used as the
  /// fallback when the response has no `reporter_role` field of its own.
  factory Report.fromJson(Map<String, dynamic> json, {ReportRole? role}) =>
      Report(
        id: json['id'].toString(),
        reporterRole: switch (json['reporter_role']) {
          'vendor' => ReportRole.vendor,
          'customer' => ReportRole.customer,
          _ => role ?? ReportRole.customer,
        },
        targetType: ReportTargetType.fromString(
          json['target_type'] as String? ?? '',
        ),
        orderId: json['order_id']?.toString(),
        targetId: json['target_id']?.toString(),
        targetName: json['target_name'] as String? ?? '',
        targetImageUrl: json['target_image_url'] as String?,
        targetPhone: json['target_phone'] as String?,
        reasonCode: json['reason_code'] as String? ?? '',
        reasonLabel: json['reason_label'] as String? ?? '',
        description: json['description'] as String? ?? '',
        attachmentUrls: (json['attachment_urls'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        status: ReportStatus.fromString(json['status'] as String? ?? ''),
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
                DateTime.now(),
        resolutionNote: json['resolution_note'] as String?,
      );

  @override
  List<Object?> get props => [
        id,
        reporterRole,
        targetType,
        orderId,
        targetId,
        targetName,
        targetImageUrl,
        targetPhone,
        reasonCode,
        reasonLabel,
        description,
        attachmentUrls,
        status,
        createdAt,
        resolutionNote,
      ];
}
