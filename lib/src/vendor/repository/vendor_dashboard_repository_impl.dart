import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/errors/failure.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/network_utils.dart';
import '../../../core/utils/network_utility.dart';
import '../../../core/utils/typedefs.dart';
import '../../../features/consumer/restaurant/domain/entities/addon.dart';
import '../model/earnings_data.dart';
import '../model/menu_item.dart';
import '../model/vendor_order.dart';
import '../model/vendor_profile.dart';
import 'vendor_dashboard_repository.dart';

class VendorDashboardRepositoryImpl implements VendorDashboardRepository {
  const VendorDashboardRepositoryImpl(this._networkUtility);

  final NetworkUtility _networkUtility;

  // ── Dashboard ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Map<String, dynamic>>> fetchDashboardStats() async {
    appLogger.d('VendorDashboardRepo.fetchDashboardStats → initiated');
    try {
      final response =
          await _networkUtility.dio.get(ApiEndpoints.vendorDashStats);
      if (_isSuccess(response.statusCode)) {
        appLogger.i('VendorDashboardRepo.fetchDashboardStats → loaded');
        return Right(_dataMap(response));
      }
      appLogger.w(
          'VendorDashboardRepo.fetchDashboardStats → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError<Map<String, dynamic>>(
          response);
    } on DioException catch (e) {
      appLogger.e('VendorDashboardRepo.fetchDashboardStats → DioException',
          error: e);
      return NetworkUtils.handleDioException<Map<String, dynamic>>(e);
    } catch (e, s) {
      return NetworkUtils.handleException<Map<String, dynamic>>(e, s,
          repositoryName: 'VendorDashboardRepo',
          methodName: 'fetchDashboardStats');
    }
  }

  @override
  Future<Either<Failure, List<VendorOrder>>> fetchActiveOrders() async {
    appLogger.d('VendorDashboardRepo.fetchActiveOrders → initiated');
    try {
      final response = await _networkUtility.dio.get(
        ApiEndpoints.vendorOrders,
        queryParameters: {'status': 'active'},
      );
      if (_isSuccess(response.statusCode)) {
        final list = _dataList(response)
            .map((e) => VendorOrder.fromJson(e as DataMap))
            .toList();
        appLogger.i(
            'VendorDashboardRepo.fetchActiveOrders → loaded ${list.length}');
        return Right(list);
      }
      appLogger.w(
          'VendorDashboardRepo.fetchActiveOrders → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError<List<VendorOrder>>(response);
    } on DioException catch (e) {
      appLogger.e('VendorDashboardRepo.fetchActiveOrders → DioException',
          error: e);
      return NetworkUtils.handleDioException<List<VendorOrder>>(e);
    } catch (e, s) {
      return NetworkUtils.handleException<List<VendorOrder>>(e, s,
          repositoryName: 'VendorDashboardRepo',
          methodName: 'fetchActiveOrders');
    }
  }

  @override
  Future<Either<Failure, bool>> toggleStoreStatus(bool isOpen) async {
    appLogger
        .d('VendorDashboardRepo.toggleStoreStatus → isOpen=$isOpen');
    try {
      final response = await _networkUtility.dio.patch(
        ApiEndpoints.vendorStoreStatus,
        data: {'is_open': isOpen},
      );
      if (_isSuccess(response.statusCode)) {
        appLogger.i('VendorDashboardRepo.toggleStoreStatus → toggled');
        return Right(isOpen);
      }
      appLogger.w(
          'VendorDashboardRepo.toggleStoreStatus → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError<bool>(response);
    } on DioException catch (e) {
      appLogger.e('VendorDashboardRepo.toggleStoreStatus → DioException',
          error: e);
      return NetworkUtils.handleDioException<bool>(e);
    } catch (e, s) {
      return NetworkUtils.handleException<bool>(e, s,
          repositoryName: 'VendorDashboardRepo',
          methodName: 'toggleStoreStatus');
    }
  }

  // ── Orders ────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<VendorOrder>>> fetchAllOrders({
    String? status,
  }) async {
    appLogger.d(
        'VendorDashboardRepo.fetchAllOrders → status=${status ?? 'all'}');
    try {
      final response = await _networkUtility.dio.get(
        ApiEndpoints.vendorOrders,
        queryParameters: status != null ? {'status': status} : null,
      );
      if (_isSuccess(response.statusCode)) {
        final list = _dataList(response)
            .map((e) => VendorOrder.fromJson(e as DataMap))
            .toList();
        appLogger.i(
            'VendorDashboardRepo.fetchAllOrders → loaded ${list.length}');
        return Right(list);
      }
      appLogger.w(
          'VendorDashboardRepo.fetchAllOrders → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError<List<VendorOrder>>(response);
    } on DioException catch (e) {
      appLogger.e('VendorDashboardRepo.fetchAllOrders → DioException',
          error: e);
      return NetworkUtils.handleDioException<List<VendorOrder>>(e);
    } catch (e, s) {
      return NetworkUtils.handleException<List<VendorOrder>>(e, s,
          repositoryName: 'VendorDashboardRepo',
          methodName: 'fetchAllOrders');
    }
  }

  @override
  Future<Either<Failure, VendorOrder>> updateOrderStatus(
    String orderId,
    String status,
  ) async {
    appLogger.d(
        'VendorDashboardRepo.updateOrderStatus → orderId=$orderId status=$status');
    try {
      final response = await _networkUtility.dio.patch(
        ApiEndpoints.vendorOrderStatus(orderId),
        data: {'status': status},
      );
      if (_isSuccess(response.statusCode)) {
        final order = VendorOrder.fromJson(_dataMap(response));
        appLogger.i(
            'VendorDashboardRepo.updateOrderStatus → updated id=${order.id}');
        return Right(order);
      }
      appLogger.w(
          'VendorDashboardRepo.updateOrderStatus → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError<VendorOrder>(response);
    } on DioException catch (e) {
      appLogger.e('VendorDashboardRepo.updateOrderStatus → DioException',
          error: e);
      return NetworkUtils.handleDioException<VendorOrder>(e);
    } catch (e, s) {
      return NetworkUtils.handleException<VendorOrder>(e, s,
          repositoryName: 'VendorDashboardRepo',
          methodName: 'updateOrderStatus');
    }
  }

  // ── Menu ──────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<MenuItem>>> fetchMenuItems() async {
    appLogger.d('VendorDashboardRepo.fetchMenuItems → initiated');
    try {
      final response =
          await _networkUtility.dio.get(ApiEndpoints.vendorMenu);
      if (_isSuccess(response.statusCode)) {
        final list = _dataList(response)
            .map((e) => MenuItem.fromJson(e as DataMap))
            .toList();
        appLogger.i(
            'VendorDashboardRepo.fetchMenuItems → loaded ${list.length}');
        return Right(list);
      }
      appLogger.w(
          'VendorDashboardRepo.fetchMenuItems → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError<List<MenuItem>>(response);
    } on DioException catch (e) {
      appLogger.e('VendorDashboardRepo.fetchMenuItems → DioException',
          error: e);
      return NetworkUtils.handleDioException<List<MenuItem>>(e);
    } catch (e, s) {
      return NetworkUtils.handleException<List<MenuItem>>(e, s,
          repositoryName: 'VendorDashboardRepo',
          methodName: 'fetchMenuItems');
    }
  }

  @override
  Future<Either<Failure, MenuItem>> toggleMenuItemAvailability(
    String itemId,
    bool isAvailable,
  ) async {
    appLogger.d(
        'VendorDashboardRepo.toggleMenuItemAvailability → id=$itemId isAvailable=$isAvailable');
    try {
      final response = await _networkUtility.dio.patch(
        ApiEndpoints.vendorMenuItemAvailability(itemId),
        data: {'is_available': isAvailable},
      );
      if (_isSuccess(response.statusCode)) {
        final item = MenuItem.fromJson(_dataMap(response));
        appLogger.i(
            'VendorDashboardRepo.toggleMenuItemAvailability → id=${item.id}');
        return Right(item);
      }
      appLogger.w(
          'VendorDashboardRepo.toggleMenuItemAvailability → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError<MenuItem>(response);
    } on DioException catch (e) {
      appLogger.e(
          'VendorDashboardRepo.toggleMenuItemAvailability → DioException',
          error: e);
      return NetworkUtils.handleDioException<MenuItem>(e);
    } catch (e, s) {
      return NetworkUtils.handleException<MenuItem>(e, s,
          repositoryName: 'VendorDashboardRepo',
          methodName: 'toggleMenuItemAvailability');
    }
  }

  @override
  Future<Either<Failure, MenuItem>> toggleMenuItemPopular(
    String id,
    bool isPopular,
  ) async {
    appLogger.d(
        'VendorDashboardRepo.toggleMenuItemPopular → id=$id isPopular=$isPopular');
    try {
      final response = await _networkUtility.dio.patch(
        ApiEndpoints.vendorMenuItem(id),
        data: {'is_popular': isPopular},
      );
      if (_isSuccess(response.statusCode)) {
        final item = MenuItem.fromJson(_dataMap(response));
        appLogger.i(
            'VendorDashboardRepo.toggleMenuItemPopular → id=${item.id}');
        return Right(item);
      }
      appLogger.w(
          'VendorDashboardRepo.toggleMenuItemPopular → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError<MenuItem>(response);
    } on DioException catch (e) {
      appLogger.e('VendorDashboardRepo.toggleMenuItemPopular → DioException',
          error: e);
      return NetworkUtils.handleDioException<MenuItem>(e);
    } catch (e, s) {
      return NetworkUtils.handleException<MenuItem>(e, s,
          repositoryName: 'VendorDashboardRepo',
          methodName: 'toggleMenuItemPopular');
    }
  }

  @override
  Future<Either<Failure, MenuItem>> createMenuItem(
    Map<String, dynamic> data,
  ) async {
    appLogger.d(
        'VendorDashboardRepo.createMenuItem → title=${data['name'] ?? data['title']}');
    try {
      final body = await _buildMenuItemBody(data);
      final response =
          await _networkUtility.dio.post(ApiEndpoints.vendorMenu, data: body);
      if (_isSuccess(response.statusCode)) {
        final item = MenuItem.fromJson(_dataMap(response));
        appLogger
            .i('VendorDashboardRepo.createMenuItem → created id=${item.id}');
        return Right(item);
      }
      appLogger.w(
          'VendorDashboardRepo.createMenuItem → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError<MenuItem>(response);
    } on DioException catch (e) {
      appLogger.e('VendorDashboardRepo.createMenuItem → DioException',
          error: e);
      return NetworkUtils.handleDioException<MenuItem>(e);
    } catch (e, s) {
      return NetworkUtils.handleException<MenuItem>(e, s,
          repositoryName: 'VendorDashboardRepo',
          methodName: 'createMenuItem');
    }
  }

  @override
  Future<Either<Failure, MenuItem>> updateMenuItem(
    String id,
    Map<String, dynamic> data,
  ) async {
    appLogger.d('VendorDashboardRepo.updateMenuItem → id=$id');
    try {
      final body = await _buildMenuItemBody(data);
      final response = await _networkUtility.dio.put(
        ApiEndpoints.vendorMenuItem(id),
        data: body,
      );
      if (_isSuccess(response.statusCode)) {
        final item = MenuItem.fromJson(_dataMap(response));
        appLogger
            .i('VendorDashboardRepo.updateMenuItem → updated id=${item.id}');
        return Right(item);
      }
      appLogger.w(
          'VendorDashboardRepo.updateMenuItem → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError<MenuItem>(response);
    } on DioException catch (e) {
      appLogger.e('VendorDashboardRepo.updateMenuItem → DioException',
          error: e);
      return NetworkUtils.handleDioException<MenuItem>(e);
    } catch (e, s) {
      return NetworkUtils.handleException<MenuItem>(e, s,
          repositoryName: 'VendorDashboardRepo',
          methodName: 'updateMenuItem');
    }
  }

  @override
  Future<Either<Failure, bool>> deleteMenuItem(String id) async {
    appLogger.d('VendorDashboardRepo.deleteMenuItem → id=$id');
    try {
      final response =
          await _networkUtility.dio.delete(ApiEndpoints.vendorMenuItem(id));
      if (_isSuccess(response.statusCode)) {
        appLogger.i('VendorDashboardRepo.deleteMenuItem → deleted id=$id');
        return const Right(true);
      }
      appLogger.w(
          'VendorDashboardRepo.deleteMenuItem → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError<bool>(response);
    } on DioException catch (e) {
      appLogger.e('VendorDashboardRepo.deleteMenuItem → DioException',
          error: e);
      return NetworkUtils.handleDioException<bool>(e);
    } catch (e, s) {
      return NetworkUtils.handleException<bool>(e, s,
          repositoryName: 'VendorDashboardRepo',
          methodName: 'deleteMenuItem');
    }
  }

  @override
  Future<Either<Failure, MenuItem>> upsertAddonGroups(
    String menuItemId,
    List<AddonGroup> groups,
  ) async {
    appLogger.d(
        'VendorDashboardRepo.upsertAddonGroups → itemId=$menuItemId groups=${groups.length}');
    try {
      final response = await _networkUtility.dio.put(
        ApiEndpoints.vendorMenuItemAddonGroups(menuItemId),
        data: {'addon_groups': groups.map((g) => g.toJson()).toList()},
      );
      if (_isSuccess(response.statusCode)) {
        final item = MenuItem.fromJson(_dataMap(response));
        appLogger
            .i('VendorDashboardRepo.upsertAddonGroups → updated id=${item.id}');
        return Right(item);
      }
      appLogger.w(
          'VendorDashboardRepo.upsertAddonGroups → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError<MenuItem>(response);
    } on DioException catch (e) {
      appLogger.e('VendorDashboardRepo.upsertAddonGroups → DioException',
          error: e);
      return NetworkUtils.handleDioException<MenuItem>(e);
    } catch (e, s) {
      return NetworkUtils.handleException<MenuItem>(e, s,
          repositoryName: 'VendorDashboardRepo',
          methodName: 'upsertAddonGroups');
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAddonGroup(
    String menuItemId,
    String groupId,
  ) async {
    appLogger.d(
        'VendorDashboardRepo.deleteAddonGroup → itemId=$menuItemId groupId=$groupId');
    try {
      final response = await _networkUtility.dio.delete(
        ApiEndpoints.vendorMenuItemAddonGroup(menuItemId, groupId),
      );
      if (_isSuccess(response.statusCode)) {
        appLogger.i(
            'VendorDashboardRepo.deleteAddonGroup → deleted groupId=$groupId');
        return const Right(true);
      }
      appLogger.w(
          'VendorDashboardRepo.deleteAddonGroup → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError<bool>(response);
    } on DioException catch (e) {
      appLogger.e('VendorDashboardRepo.deleteAddonGroup → DioException',
          error: e);
      return NetworkUtils.handleDioException<bool>(e);
    } catch (e, s) {
      return NetworkUtils.handleException<bool>(e, s,
          repositoryName: 'VendorDashboardRepo',
          methodName: 'deleteAddonGroup');
    }
  }

  // ── Earnings ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, EarningsData>> fetchEarnings({String? period}) async {
    appLogger
        .d('VendorDashboardRepo.fetchEarnings → period=${period ?? 'all'}');
    try {
      final response = await _networkUtility.dio.get(
        ApiEndpoints.vendorEarnings,
        queryParameters: period != null ? {'period': period} : null,
      );
      if (_isSuccess(response.statusCode)) {
        final earnings = EarningsData.fromJson(_dataMap(response));
        appLogger.i('VendorDashboardRepo.fetchEarnings → loaded');
        return Right(earnings);
      }
      appLogger.w(
          'VendorDashboardRepo.fetchEarnings → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError<EarningsData>(response);
    } on DioException catch (e) {
      appLogger.e('VendorDashboardRepo.fetchEarnings → DioException', error: e);
      return NetworkUtils.handleDioException<EarningsData>(e);
    } catch (e, s) {
      return NetworkUtils.handleException<EarningsData>(e, s,
          repositoryName: 'VendorDashboardRepo',
          methodName: 'fetchEarnings');
    }
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, VendorProfile>> fetchVendorProfile() async {
    appLogger.d('VendorDashboardRepo.fetchVendorProfile → initiated');
    try {
      final response =
          await _networkUtility.dio.get(ApiEndpoints.vendorProfile);
      if (_isSuccess(response.statusCode)) {
        final profile = VendorProfile.fromJson(_dataMap(response));
        appLogger
            .i('VendorDashboardRepo.fetchVendorProfile → id=${profile.id}');
        return Right(profile);
      }
      appLogger.w(
          'VendorDashboardRepo.fetchVendorProfile → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError<VendorProfile>(response);
    } on DioException catch (e) {
      appLogger.e('VendorDashboardRepo.fetchVendorProfile → DioException',
          error: e);
      return NetworkUtils.handleDioException<VendorProfile>(e);
    } catch (e, s) {
      return NetworkUtils.handleException<VendorProfile>(e, s,
          repositoryName: 'VendorDashboardRepo',
          methodName: 'fetchVendorProfile');
    }
  }

  @override
  Future<Either<Failure, VendorProfile>> updateVendorProfile(
    Map<String, dynamic> data,
  ) async {
    appLogger.d(
        'VendorDashboardRepo.updateVendorProfile → fields=${data.keys.join(', ')}');
    try {
      final response = await _networkUtility.dio.put(
        ApiEndpoints.vendorProfile,
        data: data,
      );
      if (_isSuccess(response.statusCode)) {
        final profile = VendorProfile.fromJson(_dataMap(response));
        appLogger.i(
            'VendorDashboardRepo.updateVendorProfile → updated id=${profile.id}');
        return Right(profile);
      }
      appLogger.w(
          'VendorDashboardRepo.updateVendorProfile → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError<VendorProfile>(response);
    } on DioException catch (e) {
      appLogger.e('VendorDashboardRepo.updateVendorProfile → DioException',
          error: e);
      return NetworkUtils.handleDioException<VendorProfile>(e);
    } catch (e, s) {
      return NetworkUtils.handleException<VendorProfile>(e, s,
          repositoryName: 'VendorDashboardRepo',
          methodName: 'updateVendorProfile');
    }
  }

  // ── Account ───────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, bool>> deleteVendorAccount() async {
    appLogger.d('VendorDashboardRepo.deleteVendorAccount → initiated');
    try {
      final response =
          await _networkUtility.dio.delete(ApiEndpoints.vendorAccount);
      if (_isSuccess(response.statusCode)) {
        appLogger.i('VendorDashboardRepo.deleteVendorAccount → deleted');
        return const Right(true);
      }
      appLogger.w(
          'VendorDashboardRepo.deleteVendorAccount → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError<bool>(response);
    } on DioException catch (e) {
      appLogger.e('VendorDashboardRepo.deleteVendorAccount → DioException',
          error: e);
      return NetworkUtils.handleDioException<bool>(e);
    } catch (e, s) {
      return NetworkUtils.handleException<bool>(e, s,
          repositoryName: 'VendorDashboardRepo',
          methodName: 'deleteVendorAccount');
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  bool _isSuccess(int? code) => code != null && code >= 200 && code < 300;

  DataMap _dataMap(Response response) {
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

  List<dynamic> _dataList(Response response) {
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

  Future<DataMap> _buildMenuItemBody(DataMap data) async {
    final body = <String, dynamic>{
      'title': data['name'] ?? data['title'] ?? '',
      'description': data['description'] ?? '',
      'price': double.tryParse(data['price']?.toString() ?? '') ?? 0.0,
      'category': data['category'] ?? '',
      'is_available': data['is_available'] ?? true,
      'is_popular': data['is_featured'] ?? data['is_popular'] ?? false,
      'minimum_order_qty': data['minimum_order_qty'] ?? 1,
      if (data['maximum_order_qty'] != null)
        'maximum_order_qty': data['maximum_order_qty'],
      if (data['addon_groups'] != null) 'addon_groups': data['addon_groups'],
    };

    final localPath = data['local_image_path'] as String?;
    if (localPath != null) {
      final bytes = await File(localPath).readAsBytes();
      final ext = localPath.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      body['image_base64'] = 'data:$mime;base64,${base64Encode(bytes)}';
    } else if (data['image_url'] != null) {
      body['image_url'] = data['image_url'];
    }

    return body;
  }
}
