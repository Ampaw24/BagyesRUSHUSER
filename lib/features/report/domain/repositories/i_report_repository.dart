import 'dart:io';

import 'package:bagyesrushappusernew/features/report/domain/entities/report.dart';

abstract interface class IReportRepository {
  Future<List<Report>> getMyReports(ReportRole role);
  Future<Report> getReportById(String id, ReportRole role);

  Future<Report> submitReport({
    required ReportRole role,
    required ReportTargetType targetType,
    String? orderId,
    String? targetId,
    required String targetName,
    String? targetPhone,
    required String reasonCode,
    required String reasonLabel,
    required String description,
    List<File> attachments = const [],
  });
}
