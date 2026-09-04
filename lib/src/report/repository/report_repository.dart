import 'dart:io';

import 'package:bagyesrushappusernew/src/report/model/report_reason.dart';
import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/src/report/model/report.dart';

/// Backed by the live `v1/report` API (see `reportapis.md`): `customer/reports`
/// and `vendor/me/reports`, both GET (list/show) and POST (create).
class ReportRepository {
  ReportRepository({required Dio client}) : _client = client;

  final Dio _client;

  String _basePath(ReportRole role) => role == ReportRole.vendor
      ? ApiEndpoints.vendorReports
      : ApiEndpoints.customerReports;

  String _byIdPath(String id, ReportRole role) => role == ReportRole.vendor
      ? ApiEndpoints.vendorReportById(id)
      : ApiEndpoints.customerReportById(id);

  Future<List<Report>> getMyReports(ReportRole role) async {
    appLogger.d('ReportRepository.getMyReports → role=$role');
    try {
      final response = await _client.get(_basePath(role));
      if (response.statusCode == 200) {
        final reports = _dataList(response)
            .map((e) => Report.fromJson(e as Map<String, dynamic>, role: role))
            .toList();
        appLogger.i(
          'ReportRepository.getMyReports → loaded ${reports.length} reports',
        );
        return reports;
      }
      throw Exception('Failed to load reports (${response.statusCode}).');
    } on DioException catch (e) {
      appLogger.e('ReportRepository.getMyReports → DioException', error: e);
      throw Exception(_friendlyMessage(e));
    }
  }

  Future<Report> getReportById(String id, ReportRole role) async {
    appLogger.d('ReportRepository.getReportById → id=$id, role=$role');
    try {
      final response = await _client.get(_byIdPath(id, role));
      if (response.statusCode == 200) {
        return Report.fromJson(_dataMap(response), role: role);
      }
      throw Exception('Failed to load report (${response.statusCode}).');
    } on DioException catch (e) {
      appLogger.e(
        'ReportRepository.getReportById → DioException',
        error: e,
      );
      throw Exception(_friendlyMessage(e));
    }
  }

  Future<ReportReason> getReportReasons() async {
    appLogger.d('ReportRepository.getReportReasons → ');
    try {
      final response = await _client.get(ApiEndpoints.customerReportReasons);
      if (response.statusCode == 200) {
        return ReportReason.fromJson(_dataMap(response));
      }
      throw Exception('Failed to load report reasons (${response.statusCode}).');
    } on DioException catch (e) {
      appLogger.e(
        'ReportRepository.getReportReasons → DioException',
        error: e,
      );
      throw Exception(_friendlyMessage(e));
    }
  }

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
  }) async {
    appLogger.d(
      'ReportRepository.submitReport → role=$role, targetType=$targetType, '
      'reasonCode=$reasonCode, attachments=${attachments.length}',
    );
    try {
      final formData = FormData.fromMap({
        'target_type': targetType.apiValue,
        if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
        if (targetId != null) 'target_id': int.tryParse(targetId) ?? targetId,
        'target_name': targetName,
        if (targetPhone != null && targetPhone.isNotEmpty)
          'target_phone': targetPhone,
        'reason_code': reasonCode,
        if (reasonLabel.isNotEmpty) 'reason_label': reasonLabel,
        'description': description,
      });
      for (final file in attachments) {
        formData.files.add(
          MapEntry('attachments[]', await MultipartFile.fromFile(file.path)),
        );
      }

      final response = await _client.post(_basePath(role), data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        appLogger.i('ReportRepository.submitReport → success');
        return Report.fromJson(_dataMap(response), role: role);
      }
      throw Exception('Failed to submit report (${response.statusCode}).');
    } on DioException catch (e) {
      appLogger.e('ReportRepository.submitReport → DioException', error: e);
      throw Exception(_friendlyMessage(e));
    }
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  String _friendlyMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        return errors.values
            .map((v) => v is List ? v.join(', ') : v.toString())
            .join('\n');
      }
      final message = data['message']?.toString() ?? data['error']?.toString();
      if (message != null) return message;
    }
    return e.message ?? 'Something went wrong. Please try again.';
  }

  Map<String, dynamic> _dataMap(Response response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final d = body['data'];
      if (d is Map<String, dynamic>) {
        final inner = d['data'];
        if (inner is Map<String, dynamic>) return inner;
        return d;
      }
    }
    return const {};
  }

  List<dynamic> _dataList(Response response) {
    final body = response.data;
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      final d = body['data'];
      if (d is List) return d;
      if (d is Map<String, dynamic>) {
        final inner = d['data'];
        if (inner is List) return inner;
        final items = d['items'];
        if (items is List) return items;
      }
    }
    return const [];
  }
}
