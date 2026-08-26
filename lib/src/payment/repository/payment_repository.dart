import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import '../model/payment_method.dart';

class PaymentRepository {
  const PaymentRepository({required Dio client}) : _client = client;

  final Dio _client;

  // ─── Customer ────────────────────────────────────────────────────────────

  ResultFuture<List<PaymentMethod>> getCustomerPaymentMethods() =>
      _getMethods(
        ApiEndpoints.customerPaymentMethods,
        methodName: 'getCustomerPaymentMethods',
      );

  ResultFuture<PaymentMethod> addCustomerPaymentMethod({
    required int payoutProviderId,
    required String phoneNumber,
    String? label,
  }) =>
      _addMethod(
        ApiEndpoints.customerPaymentMethods,
        payoutProviderId: payoutProviderId,
        phoneNumber: phoneNumber,
        label: label,
        methodName: 'addCustomerPaymentMethod',
      );

  ResultFuture<bool> deleteCustomerPaymentMethod({required String id}) =>
      _deleteMethod(
        ApiEndpoints.customerPaymentMethodById(id),
        methodName: 'deleteCustomerPaymentMethod',
      );

  ResultFuture<PaymentMethod> makeCustomerPaymentMethodDefault({
    required String id,
  }) =>
      _makeDefault(
        ApiEndpoints.customerPaymentMethodDefault(id),
        methodName: 'makeCustomerPaymentMethodDefault',
      );

  // ─── Vendor ──────────────────────────────────────────────────────────────

  ResultFuture<List<PaymentMethod>> getVendorPaymentMethods() => _getMethods(
        ApiEndpoints.vendorPaymentMethods,
        methodName: 'getVendorPaymentMethods',
      );

  ResultFuture<PaymentMethod> addVendorPaymentMethod({
    required int payoutProviderId,
    required String phoneNumber,
    String? label,
  }) =>
      _addMethod(
        ApiEndpoints.vendorPaymentMethods,
        payoutProviderId: payoutProviderId,
        phoneNumber: phoneNumber,
        label: label,
        methodName: 'addVendorPaymentMethod',
      );

  ResultFuture<bool> deleteVendorPaymentMethod({required String id}) =>
      _deleteMethod(
        ApiEndpoints.vendorPaymentMethodById(id),
        methodName: 'deleteVendorPaymentMethod',
      );

  ResultFuture<PaymentMethod> makeVendorPaymentMethodDefault({
    required String id,
  }) =>
      _makeDefault(
        ApiEndpoints.vendorPaymentMethodDefault(id),
        methodName: 'makeVendorPaymentMethodDefault',
      );

  // ─── Shared implementations ────────────────────────────────────────────────

  ResultFuture<List<PaymentMethod>> _getMethods(
    String path, {
    required String methodName,
  }) async {
    appLogger.d('PaymentRepository.$methodName → initiated');
    try {
      final response = await _client.get(path);

      if ([200, 201].contains(response.statusCode)) {
        final methods = _dataList(response)
            .map((e) => PaymentMethod.fromJson(e as DataMap))
            .toList();
        appLogger.i(
          'PaymentRepository.$methodName → success, loaded ${methods.length} methods',
        );
        return Right(methods);
      }

      appLogger.w('PaymentRepository.$methodName → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('PaymentRepository.$methodName → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'PaymentRepository',
        methodName: methodName,
      );
    }
  }

  ResultFuture<PaymentMethod> _addMethod(
    String path, {
    required int payoutProviderId,
    required String phoneNumber,
    String? label,
    required String methodName,
  }) async {
    appLogger.d('PaymentRepository.$methodName → initiated');
    try {
      final response = await _client.post(path, data: {
        'payout_provider_id': payoutProviderId,
        'phone_number': phoneNumber,
        'label': label,
      });

      if ([200, 201].contains(response.statusCode)) {
        final method = PaymentMethod.fromJson(_dataMap(response));
        appLogger.i('PaymentRepository.$methodName → success, id=${method.id}');
        return Right(method);
      }

      appLogger.w('PaymentRepository.$methodName → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('PaymentRepository.$methodName → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'PaymentRepository',
        methodName: methodName,
      );
    }
  }

  ResultFuture<bool> _deleteMethod(
    String path, {
    required String methodName,
  }) async {
    appLogger.d('PaymentRepository.$methodName → initiated');
    try {
      final response = await _client.delete(path);

      if ([200, 204].contains(response.statusCode)) {
        appLogger.i('PaymentRepository.$methodName → success');
        return const Right(true);
      }

      appLogger.w('PaymentRepository.$methodName → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('PaymentRepository.$methodName → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'PaymentRepository',
        methodName: methodName,
      );
    }
  }

  ResultFuture<PaymentMethod> _makeDefault(
    String path, {
    required String methodName,
  }) async {
    appLogger.d('PaymentRepository.$methodName → initiated');
    try {
      final response = await _client.patch(path);

      if ([200, 201].contains(response.statusCode)) {
        final method = PaymentMethod.fromJson(_dataMap(response));
        appLogger.i('PaymentRepository.$methodName → success, id=${method.id}');
        return Right(method);
      }

      appLogger.w('PaymentRepository.$methodName → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('PaymentRepository.$methodName → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'PaymentRepository',
        methodName: methodName,
      );
    }
  }

  // ─── Private Helpers ───────────────────────────────────────────────────────

  DataMap _dataMap(Response response) {
    final body = response.data;
    if (body is DataMap) {
      final d = body['data'];
      if (d is DataMap) return d;
      return body;
    }
    return const {};
  }

  List<dynamic> _dataList(Response response) {
    final body = response.data;
    if (body is List) return body;
    if (body is DataMap) {
      final d = body['data'];
      if (d is List) return d;
      if (d is DataMap) {
        for (final key in ['data', 'items', 'docs', 'results', 'list']) {
          final nested = d[key];
          if (nested is List) return nested;
        }
      }
    }
    return const [];
  }
}
