import 'package:equatable/equatable.dart';

import 'report.dart';

class ReportReason extends Equatable {
  const ReportReason({
    required this.vendor,
    required this.rider,
    required this.customer,
    required this.orderIssue,
    required this.general,
  });

  final List<ReportReasonOption> vendor;
  final List<ReportReasonOption> rider;
  final List<ReportReasonOption> customer;
  final List<ReportReasonOption> orderIssue;
  final List<ReportReasonOption> general;

  ReportReason copyWith({
    List<ReportReasonOption>? vendor,
    List<ReportReasonOption>? rider,
    List<ReportReasonOption>? customer,
    List<ReportReasonOption>? orderIssue,
    List<ReportReasonOption>? general,
  }) {
    return ReportReason(
      vendor: vendor ?? this.vendor,
      rider: rider ?? this.rider,
      customer: customer ?? this.customer,
      orderIssue: orderIssue ?? this.orderIssue,
      general: general ?? this.general,
    );
  }

  factory ReportReason.fromJson(Map<String, dynamic> json) {
    return ReportReason(
      vendor: json["vendor"] == null
          ? []
          : List<ReportReasonOption>.from(
              json["vendor"]!.map((x) => ReportReasonOption.fromJson(x)),
            ),
      rider: json["rider"] == null
          ? []
          : List<ReportReasonOption>.from(
              json["rider"]!.map((x) => ReportReasonOption.fromJson(x)),
            ),
      customer: json["customer"] == null
          ? []
          : List<ReportReasonOption>.from(
              json["customer"]!.map((x) => ReportReasonOption.fromJson(x)),
            ),
      orderIssue: json["order_issue"] == null
          ? []
          : List<ReportReasonOption>.from(
              json["order_issue"]!.map((x) => ReportReasonOption.fromJson(x)),
            ),
      general: json["general"] == null
          ? []
          : List<ReportReasonOption>.from(
              json["general"]!.map((x) => ReportReasonOption.fromJson(x)),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
    "vendor": vendor.map((x) => x.toJson()).toList(),
    "rider": rider.map((x) => x.toJson()).toList(),
    "customer": customer.map((x) => x.toJson()).toList(),
    "order_issue": orderIssue.map((x) => x.toJson()).toList(),
    "general": general.map((x) => x.toJson()).toList(),
  };

  /// Reason options for the "What went wrong?" step, grouped by who/what
  /// is being reported.
  List<ReportReasonOption> forTargetType(ReportTargetType type) =>
      switch (type) {
        ReportTargetType.vendor => vendor,
        ReportTargetType.rider => rider,
        ReportTargetType.customer => customer,
        ReportTargetType.orderIssue => orderIssue,
        ReportTargetType.general => general,
      };

  @override
  String toString() {
    return "$vendor, $rider, $customer, $orderIssue, $general, ";
  }

  @override
  List<Object?> get props => [vendor, rider, customer, orderIssue, general];
}

/// A single selectable reason option (`{code, label}`) as returned by
/// `GET /reports/reasons`, shared across every report category.
class ReportReasonOption extends Equatable {
  const ReportReasonOption({required this.code, required this.label});

  final String code;
  final String label;

  ReportReasonOption copyWith({String? code, String? label}) {
    return ReportReasonOption(
      code: code ?? this.code,
      label: label ?? this.label,
    );
  }

  factory ReportReasonOption.fromJson(Map<String, dynamic> json) {
    return ReportReasonOption(
      code: json["code"] ?? "",
      label: json["label"] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {"code": code, "label": label};

  @override
  String toString() {
    return "$code, $label, ";
  }

  @override
  List<Object?> get props => [code, label];
}
