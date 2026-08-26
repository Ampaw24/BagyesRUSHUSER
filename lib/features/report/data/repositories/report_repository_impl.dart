import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/features/report/domain/entities/report.dart';
import 'package:bagyesrushappusernew/features/report/domain/repositories/i_report_repository.dart';

/// Backed by the live `v1/report` API (see `reportapis.md`): `customer/reports`
/// and `vendor/me/reports`, both GET (list/show) and POST (create).
class ReportRepositoryImpl implements IReportRepository {
  ReportRepositoryImpl({required Dio client}) : _client = client;

  final Dio _client;

  String _basePath(ReportRole role) => role == ReportRole.vendor
      ? ApiEndpoints.vendorReports
      : ApiEndpoints.customerReports;

  String _byIdPath(String id, ReportRole role) => role == ReportRole.vendor
      ? ApiEndpoints.vendorReportById(id)
      : ApiEndpoints.customerReportById(id);

  @override
  Future<List<Report>> getMyReports(ReportRole role) async {
    appLogger.d('ReportRepositoryImpl.getMyReports → role=$role');
    try {
      final response = await _client.get(_basePath(role));
      if (response.statusCode == 200) {
        final reports = _dataList(response)
            .map((e) => Report.fromJson(e as Map<String, dynamic>, role: role))
            .toList();
        appLogger.i(
          'ReportRepositoryImpl.getMyReports → loaded ${reports.length} reports',
        );
        return reports;
      }
      throw Exception('Failed to load reports (${response.statusCode}).');
    } on DioException catch (e) {
      appLogger.e('ReportRepositoryImpl.getMyReports → DioException', error: e);
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<Report> getReportById(String id, ReportRole role) async {
    appLogger.d('ReportRepositoryImpl.getReportById → id=$id, role=$role');
    try {
      final response = await _client.get(_byIdPath(id, role));
      if (response.statusCode == 200) {
        return Report.fromJson(_dataMap(response), role: role);
      }
      throw Exception('Failed to load report (${response.statusCode}).');
    } on DioException catch (e) {
      appLogger.e(
        'ReportRepositoryImpl.getReportById → DioException',
        error: e,
      );
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
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
      'ReportRepositoryImpl.submitReport → role=$role, targetType=$targetType, '
      'reasonCode=$reasonCode, attachments=${attachments.length}',
    );
    try {
      final attachmentUris = await Future.wait(attachments.map(_toDataUri));

      final response = await _client.post(
        _basePath(role),
        data: {
          'target_type': targetType.apiValue,
          if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
          if (targetId != null) 'target_id': int.tryParse(targetId) ?? targetId,
          'target_name': targetName,
          if (targetPhone != null && targetPhone.isNotEmpty)
            'target_phone': targetPhone,
          'reason_code': reasonCode,
          if (reasonLabel.isNotEmpty) 'reason_label': reasonLabel,
          'description': description,
          if (attachmentUris.isNotEmpty) 'attachments': attachmentUris,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        appLogger.i('ReportRepositoryImpl.submitReport → success');
        return Report.fromJson(_dataMap(response), role: role);
      }
      throw Exception('Failed to submit report (${response.statusCode}).');
    } on DioException catch (e) {
      appLogger.e('ReportRepositoryImpl.submitReport → DioException', error: e);
      throw Exception(_friendlyMessage(e));
    }
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  /// Attachments travel as base64 data URIs inside the JSON body (per
  /// `reportapis.md`, this endpoint is `Content-Type: application/json`,
  /// not multipart) — same convention as `vendorDashboardRepositoryImpl`'s
  /// image uploads.
  Future<String> _toDataUri(File file) async {
    final bytes = await file.readAsBytes();
    final ext = file.path.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

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
      }
    }
    return const [];
  }
}
