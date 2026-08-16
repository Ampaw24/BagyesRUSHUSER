import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/vendor/model/menu_item.dart';
import 'package:bagyesrushappusernew/src/vendor/model/vendor_order.dart';
import 'package:bagyesrushappusernew/src/vendor/model/vendor_profile.dart';

class VendorRepository {
  const VendorRepository({required Dio client}) : _client = client;

  final Dio _client;

  // ── Profile ───────────────────────────────────────────────────────────────


  ResultFuture<VendorProfile> getVendorProfile() async {
    appLogger.d('VendorRepository.getVendorProfile → initiated');
    try {
      final response = await _client.get(ApiEndpoints.vendorProfile);

      if (_isSuccess(response.statusCode)) {
        final payload = _single(response);
        final profile = VendorProfile.fromJson(payload);
        appLogger.i('VendorRepository.getVendorProfile → id=${profile.id}');
        return Right(profile);
      }

      appLogger.w('VendorRepository.getVendorProfile → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('VendorRepository.getVendorProfile → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'VendorRepository', methodName: 'getVendorProfile');
    }
  }


  ResultFuture<VendorProfile> updateVendorProfile(
      Map<String, dynamic> data) async {
    appLogger.d('VendorRepository.updateVendorProfile → fields=${data.keys.join(', ')}');
    try {
      final response = await _client.patch(
        ApiEndpoints.vendorProfile,
        data: data,
      );

      if (_isSuccess(response.statusCode)) {
        final payload = _single(response);
        final profile = VendorProfile.fromJson(payload);
        appLogger.i('VendorRepository.updateVendorProfile → updated id=${profile.id}');
        return Right(profile);
      }

      appLogger.w('VendorRepository.updateVendorProfile → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('VendorRepository.updateVendorProfile → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'VendorRepository', methodName: 'updateVendorProfile');
    }
  }

  // ── Menu Items ────────────────────────────────────────────────────────────


  ResultFuture<List<MenuItem>> getMenuItems() async {
    appLogger.d('VendorRepository.getMenuItems → initiated');
    try {
      final response = await _client.get(ApiEndpoints.vendorMenu);

      if (_isSuccess(response.statusCode)) {
        final list = _list(response);
        final items = list
            .map((e) => MenuItem.fromJson(e as DataMap))
            .toList();
        appLogger.i('VendorRepository.getMenuItems → loaded ${items.length} items');
        return Right(items);
      }

      appLogger.w('VendorRepository.getMenuItems → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('VendorRepository.getMenuItems → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'VendorRepository', methodName: 'getMenuItems');
    }
  }


  ResultFuture<MenuItem> createMenuItem(Map<String, dynamic> data) async {
    appLogger.d('VendorRepository.createMenuItem → name=${data['name']}');
    try {
      final response = await _client.post(ApiEndpoints.vendorMenu, data: data);

      if (_isSuccess(response.statusCode)) {
        final payload = _single(response);
        final item = MenuItem.fromJson(payload);
        appLogger.i('VendorRepository.createMenuItem → created id=${item.id}');
        return Right(item);
      }

      appLogger.w('VendorRepository.createMenuItem → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('VendorRepository.createMenuItem → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'VendorRepository', methodName: 'createMenuItem');
    }
  }


  ResultFuture<MenuItem> updateMenuItem(
      String id, Map<String, dynamic> data) async {
    appLogger.d('VendorRepository.updateMenuItem → id=$id');
    try {
      final response = await _client.put(
        ApiEndpoints.vendorMenuItem(id),
        data: data,
      );

      if (_isSuccess(response.statusCode)) {
        final payload = _single(response);
        final item = MenuItem.fromJson(payload);
        appLogger.i('VendorRepository.updateMenuItem → updated id=${item.id}');
        return Right(item);
      }

      appLogger.w('VendorRepository.updateMenuItem → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('VendorRepository.updateMenuItem → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'VendorRepository', methodName: 'updateMenuItem');
    }
  }


  ResultFuture<MenuItem> toggleMenuItemAvailability(
      String id, bool isAvailable) async {
    appLogger.d(
        'VendorRepository.toggleMenuItemAvailability → id=$id isAvailable=$isAvailable');
    try {
      final response = await _client.patch(
        ApiEndpoints.vendorMenuItemAvailability(id),
        data: {'is_available': isAvailable},
      );

      if (_isSuccess(response.statusCode)) {
        final payload = _single(response);
        final item = MenuItem.fromJson(payload);
        appLogger.i(
            'VendorRepository.toggleMenuItemAvailability → id=${item.id} isAvailable=$isAvailable');
        return Right(item);
      }

      appLogger.w(
          'VendorRepository.toggleMenuItemAvailability → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
          'VendorRepository.toggleMenuItemAvailability → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'VendorRepository',
          methodName: 'toggleMenuItemAvailability');
    }
  }


  ResultFuture<bool> deleteMenuItem(String id) async {
    appLogger.d('VendorRepository.deleteMenuItem → id=$id');
    try {
      final response = await _client.delete(ApiEndpoints.vendorMenuItem(id));

      if (_isSuccess(response.statusCode)) {
        appLogger.i('VendorRepository.deleteMenuItem → deleted id=$id');
        return const Right(true);
      }

      appLogger.w('VendorRepository.deleteMenuItem → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('VendorRepository.deleteMenuItem → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'VendorRepository', methodName: 'deleteMenuItem');
    }
  }

  // ── Orders ────────────────────────────────────────────────────────────────


  ResultFuture<List<VendorOrder>> getOrders({String? status}) async {
    appLogger.d(
        'VendorRepository.getOrders → status=${status ?? 'all'}');
    try {
      final response = await _client.get(
        ApiEndpoints.vendorOrders,
        queryParameters: status != null ? {'status': status} : null,
      );

      if (_isSuccess(response.statusCode)) {
        final list = _list(response);
        final orders = list
            .map((e) => VendorOrder.fromJson(e as DataMap))
            .toList();
        appLogger.i('VendorRepository.getOrders → loaded ${orders.length} orders');
        return Right(orders);
      }

      appLogger.w('VendorRepository.getOrders → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('VendorRepository.getOrders → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'VendorRepository', methodName: 'getOrders');
    }
  }


  ResultFuture<VendorOrder> getOrderById(String orderId) async {
    appLogger.d('VendorRepository.getOrderById → orderId=$orderId');
    try {
      final response = await _client.get(ApiEndpoints.vendorOrderById(orderId));

      if (_isSuccess(response.statusCode)) {
        final payload = _single(response);
        final order = VendorOrder.fromJson(payload);
        appLogger.i('VendorRepository.getOrderById → loaded order id=${order.id}');
        return Right(order);
      }

      appLogger.w('VendorRepository.getOrderById → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('VendorRepository.getOrderById → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'VendorRepository', methodName: 'getOrderById');
    }
  }


  ResultFuture<VendorOrder> updateOrderStatus(
      String orderId, String status) async {
    appLogger.d(
        'VendorRepository.updateOrderStatus → orderId=$orderId status=$status');
    try {
      final path = switch (status) {
        'accepted' || 'accept' => ApiEndpoints.vendorOrderAccept(orderId),
        'rejected' || 'reject' => ApiEndpoints.vendorOrderReject(orderId),
        'preparing' => ApiEndpoints.vendorOrderPreparing(orderId),
        'ready' => ApiEndpoints.vendorOrderReady(orderId),
        'out_for_delivery' || 'outForDelivery' =>
          ApiEndpoints.vendorOrderOutForDelivery(orderId),
        'delivered' => ApiEndpoints.vendorOrderDelivered(orderId),
        _ => ApiEndpoints.vendorOrderCancel(orderId),
      };
      final response = await _client.patch(path);

      if (_isSuccess(response.statusCode)) {
        final payload = _single(response);
        final order = VendorOrder.fromJson(payload);
        appLogger.i(
            'VendorRepository.updateOrderStatus → order id=${order.id} status=${order.status}');
        return Right(order);
      }

      appLogger.w(
          'VendorRepository.updateOrderStatus → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('VendorRepository.updateOrderStatus → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'VendorRepository', methodName: 'updateOrderStatus');
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  bool _isSuccess(int? code) => code != null && code >= 200 && code < 300;

  /// Unwrap { "data": { ... } } or { "data": { "data": { ... } } }
  DataMap _single(Response response) {
    final body = response.data;
    if (body is DataMap) {
      final d = body['data'];
      if (d is DataMap) {
        final inner = d['data'];
        if (inner is DataMap) return inner;
        return d;
      }
    }
    return const {};
  }

  /// Unwrap { "data": [...] } or { "data": { "data": [...] } }
  List<dynamic> _list(Response response) {
    final body = response.data;
    if (body is List) return body;
    if (body is DataMap) {
      final d = body['data'];
      if (d is List) return d;
      if (d is DataMap) {
        final inner = d['data'];
        if (inner is List) return inner;
      }
    }
    return const [];
  }
}
