import 'dart:io';

import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/features/report/domain/entities/report.dart';
import 'package:bagyesrushappusernew/features/report/domain/repositories/i_report_repository.dart';

/// TEMPORARY: backed by in-memory dummy data. The real endpoints are
/// documented in REPORT_FEATURE_API.md / REPORTS_SPEC_ADDENDUM.md but don't
/// exist on the backend yet — every `_client` call below is commented out
/// rather than deleted. Once the endpoints are live, uncomment the real
/// calls and delete the dummy-data block beneath each one.
class ReportRepositoryImpl implements IReportRepository {
  ReportRepositoryImpl({required Dio client}) : _client = client;

  // ignore: unused_field
  final Dio _client;

  // ignore: unused_element
  String _basePath(ReportRole role) => role == ReportRole.vendor
      ? ApiEndpoints.vendorReports
      : ApiEndpoints.customerReports;

  // ignore: unused_element
  String _byIdPath(String id, ReportRole role) => role == ReportRole.vendor
      ? ApiEndpoints.vendorReportById(id)
      : ApiEndpoints.customerReportById(id);

  @override
  Future<List<Report>> getMyReports(ReportRole role) async {
    // final response = await _client.get(_basePath(role));
    // final list = _dataList(response);
    // return list.map((e) => Report.fromJson(e as Map<String, dynamic>)).toList();

    await Future.delayed(const Duration(milliseconds: 500));
    return _dummyReports.where((r) => r.reporterRole == role).toList();
  }

  @override
  Future<Report> getReportById(String id, ReportRole role) async {
    // final response = await _client.get(_byIdPath(id, role));
    // return Report.fromJson(_dataMap(response));

    await Future.delayed(const Duration(milliseconds: 400));
    return _dummyReports.firstWhere(
      (r) => r.id == id,
      orElse: () => _dummyReports.first,
    );
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
    // final form = FormData.fromMap({
    //   'target_type': targetType.apiValue,
    //   if (orderId != null) 'order_id': orderId,
    //   if (targetId != null) 'target_id': targetId,
    //   'target_name': targetName,
    //   if (targetPhone != null) 'target_phone': targetPhone,
    //   'reason_code': reasonCode,
    //   'reason_label': reasonLabel,
    //   'description': description,
    //   if (attachments.isNotEmpty)
    //     'attachments[]': await Future.wait(
    //       attachments.map(
    //         (file) => MultipartFile.fromFile(
    //           file.path,
    //           filename: file.uri.pathSegments.last,
    //         ),
    //       ),
    //     ),
    // });
    // final response = await _client.post(_basePath(role), data: form);
    // return Report.fromJson(_dataMap(response));

    await Future.delayed(const Duration(milliseconds: 900));
    final report = Report(
      id: 'RPT-${_dummyIdCounter++}',
      reporterRole: role,
      targetType: targetType,
      orderId: orderId,
      targetId: targetId,
      targetName: targetName,
      targetPhone: targetPhone,
      reasonCode: reasonCode,
      reasonLabel: reasonLabel,
      description: description,
      status: ReportStatus.pending,
      createdAt: DateTime.now(),
    );
    _dummyReports.insert(0, report);
    return report;
  }

  // ─── Private helpers (unused while dummy data is in effect) ────────────────

  // ignore: unused_element
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

  // ignore: unused_element
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

  // ─── Dummy data ──────────────────────────────────────────────────────────

  int _dummyIdCounter = 1007;

  final List<Report> _dummyReports = [
    Report(
      id: 'RPT-1001',
      reporterRole: ReportRole.customer,
      targetType: ReportTargetType.vendor,
      orderId: 'ORD-2101',
      targetId: '01KZY1R3WQ2HPNA2HFXY86XDT5',
      targetName: 'Auntie Muni Waakye',
      reasonCode: 'poor_food_quality',
      reasonLabel: 'Poor food quality',
      description:
          'The waakye was cold and the stew tasted off. Had to throw most of it away.',
      status: ReportStatus.resolved,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      resolutionNote:
          'We spoke with the vendor and issued a partial refund to your wallet.',
    ),
    Report(
      id: 'RPT-1002',
      reporterRole: ReportRole.customer,
      targetType: ReportTargetType.rider,
      orderId: 'ORD-2144',
      targetName: 'Kwame Mensah',
      targetPhone: '+233 20 123 4567',
      reasonCode: 'rider_late',
      reasonLabel: 'Took too long to deliver',
      description:
          'Order was marked out for delivery over an hour before it actually arrived, with no updates.',
      status: ReportStatus.inReview,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Report(
      id: 'RPT-1003',
      reporterRole: ReportRole.customer,
      targetType: ReportTargetType.orderIssue,
      orderId: 'ORD-2201',
      targetName: 'Order #ORD-2201',
      reasonCode: 'missing_items',
      reasonLabel: 'Missing items',
      description: 'One of the two drinks I ordered was missing from the bag.',
      status: ReportStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Report(
      id: 'RPT-1004',
      reporterRole: ReportRole.vendor,
      targetType: ReportTargetType.customer,
      orderId: 'ORD-1998',
      targetName: 'Ama Boateng',
      targetPhone: '+233 24 987 6543',
      reasonCode: 'customer_abusive',
      reasonLabel: 'Abusive behavior',
      description:
          'Customer sent several abusive messages in the order chat over a delay that was caused by traffic.',
      status: ReportStatus.dismissed,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      resolutionNote: 'Reviewed chat logs — no policy violation found.',
    ),
    Report(
      id: 'RPT-1005',
      reporterRole: ReportRole.vendor,
      targetType: ReportTargetType.rider,
      orderId: 'ORD-2190',
      targetName: 'Yaw Owusu',
      targetPhone: '+233 26 555 1122',
      reasonCode: 'rider_mishandled',
      reasonLabel: 'Mishandled my order',
      description:
          'Rider left the food packaging open during pickup and some of it spilled in the bag.',
      status: ReportStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    Report(
      id: 'RPT-1006',
      reporterRole: ReportRole.customer,
      targetType: ReportTargetType.general,
      targetName: 'General',
      reasonCode: 'app_bug',
      reasonLabel: 'App problem or bug',
      description: 'The app crashed when I tried to reorder from my past orders tab.',
      status: ReportStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
  ];
}
