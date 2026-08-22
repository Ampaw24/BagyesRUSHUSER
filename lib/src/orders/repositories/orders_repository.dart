import 'package:bagyesrushappusernew/src/home/models/category.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/vendor/model/menu_item.dart';
import '../models/order.dart' as ord;

class OrdersRepository {
  const OrdersRepository({required Dio client}) : _client = client;

  final Dio _client;

  // ─── Categories ────────────────────────────────────────────────────────────

  ResultFuture<List<Category>> getCategories() async {
    appLogger.d('OrdersRepository.getCategories → initiated');
    try {
      final response = await _client.get(ApiEndpoints.categories);

      appLogger.d(
        'OrdersRepository.getCategories → RAW RESPONSE\n'
        '  status : ${response.statusCode}\n'
        '  data   : ${response.data}',
      );

      if ([200, 201].contains(response.statusCode)) {
        final categories = [Category.fromResponseData(response.data)];
        appLogger.i(
          'OrdersRepository.getCategories → loaded ${categories.first.categories.length} categories',
        );
        return Right(categories);
      }

      appLogger.w(
        'OrdersRepository.getCategories → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('OrdersRepository.getCategories → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'OrdersRepository',
        methodName: 'getCategories',
      );
    }
  }

  //["Get Orders"]
  ResultFuture<List<ord.Order>> getCustomerOrders() async {
    appLogger.d('OrdersRepository.getCustomerOrders → initiated');
    try {
      final response = await _client.get(ApiEndpoints.customerOrders);

      if (response.statusCode == 200) {
        final payload =
            (response.data as DataMap)['data'] as List<dynamic>? ??
            response.data as List<dynamic>;
        final orders = payload
            .map((e) => ord.Order.fromJson(e as DataMap))
            .toList();
        appLogger.i(
          'OrdersRepository.getCustomerOrders → success, loaded ${orders.length} orders',
        );
        return Right(orders);
      }

      appLogger.w(
        'OrdersRepository.getCustomerOrders → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'OrdersRepository.getCustomerOrders → DioException',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'OrdersRepository',
        methodName: 'getCustomerOrders',
      );
    }
  }

  ResultFuture<ord.Order> getOrderById({required String orderId}) async {
    appLogger.d('OrdersRepository.getOrderById → id=$orderId');
    try {
      final response = await _client.get(
        ApiEndpoints.customerOrderById(orderId),
      );

      if (response.statusCode == 200) {
        final payload =
            (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;
        final order = ord.Order.fromJson(payload);
        appLogger.i('OrdersRepository.getOrderById → success');
        return Right(order);
      }

      appLogger.w(
        'OrdersRepository.getOrderById → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('OrdersRepository.getOrderById → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'OrdersRepository',
        methodName: 'getOrderById',
      );
    }
  }

  // ─── Vendor Menu API integrations ──────────────────────────────────────────

  ResultFuture<List<MenuItem>> fetchMenuItems() async {
    appLogger.d('OrdersRepository.fetchMenuItems → initiated');
    try {
      final response = await _client.get(ApiEndpoints.vendorMenu);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final list = _dataList(
          response,
        ).map((e) => MenuItem.fromJson(e as DataMap)).toList();
        appLogger.i(
          'OrdersRepository.fetchMenuItems → success, loaded ${list.length}',
        );
        return Right(list);
      }
      appLogger.w(
        'OrdersRepository.fetchMenuItems → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('OrdersRepository.fetchMenuItems → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'OrdersRepository',
        methodName: 'fetchMenuItems',
      );
    }
  }

  ResultFuture<MenuItem> createMenuItem(Map<String, dynamic> data) async {
    appLogger.d('OrdersRepository.createMenuItem → initiated');
    try {
      final body = _buildMenuItemBody(data);
      final response = await _client.post(ApiEndpoints.vendorMenu, data: body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final item = MenuItem.fromJson(_dataMap(response));
        appLogger.i(
          'OrdersRepository.createMenuItem → success, created id=${item.id}',
        );
        return Right(item);
      }
      appLogger.w(
        'OrdersRepository.createMenuItem → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('OrdersRepository.createMenuItem → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'OrdersRepository',
        methodName: 'createMenuItem',
      );
    }
  }

  ResultFuture<MenuItem> updateMenuItem({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    appLogger.d('OrdersRepository.updateMenuItem → id=$id');
    try {
      final body = _buildMenuItemBody(data);
      final response = await _client.put(
        ApiEndpoints.vendorMenuItem(id),
        data: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final item = MenuItem.fromJson(_dataMap(response));
        appLogger.i(
          'OrdersRepository.updateMenuItem → success, updated id=${item.id}',
        );
        return Right(item);
      }
      appLogger.w(
        'OrdersRepository.updateMenuItem → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('OrdersRepository.updateMenuItem → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'OrdersRepository',
        methodName: 'updateMenuItem',
      );
    }
  }

  ResultFuture<bool> deleteMenuItem({required String id}) async {
    appLogger.d('OrdersRepository.deleteMenuItem → id=$id');
    try {
      final response = await _client.delete(ApiEndpoints.vendorMenuItem(id));
      if (response.statusCode == 200 || response.statusCode == 204) {
        appLogger.i(
          'OrdersRepository.deleteMenuItem → success, deleted id=$id',
        );
        return const Right(true);
      }
      appLogger.w(
        'OrdersRepository.deleteMenuItem → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('OrdersRepository.deleteMenuItem → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'OrdersRepository',
        methodName: 'deleteMenuItem',
      );
    }
  }

  ResultFuture<MenuItem> toggleMenuItemAvailability({
    required String itemId,
    required bool isAvailable,
  }) async {
    appLogger.d(
      'OrdersRepository.toggleMenuItemAvailability → id=$itemId, isAvailable=$isAvailable',
    );
    try {
      final response = await _client.patch(
        ApiEndpoints.vendorMenuItemAvailability(itemId),
        data: {'is_available': isAvailable},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final item = MenuItem.fromJson(_dataMap(response));
        appLogger.i(
          'OrdersRepository.toggleMenuItemAvailability → success, id=${item.id}',
        );
        return Right(item);
      }
      appLogger.w(
        'OrdersRepository.toggleMenuItemAvailability → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'OrdersRepository.toggleMenuItemAvailability → DioException',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'OrdersRepository',
        methodName: 'toggleMenuItemAvailability',
      );
    }
  }

  ResultFuture<MenuItem> toggleMenuItemPopular({
    required String itemId,
    required bool isPopular,
  }) async {
    appLogger.d(
      'OrdersRepository.toggleMenuItemPopular → id=$itemId, isPopular=$isPopular',
    );
    try {
      final response = await _client.patch(
        ApiEndpoints.vendorMenuItem(itemId),
        data: {'is_popular': isPopular},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final item = MenuItem.fromJson(_dataMap(response));
        appLogger.i(
          'OrdersRepository.toggleMenuItemPopular → success, id=${item.id}',
        );
        return Right(item);
      }
      appLogger.w(
        'OrdersRepository.toggleMenuItemPopular → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'OrdersRepository.toggleMenuItemPopular → DioException',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'OrdersRepository',
        methodName: 'toggleMenuItemPopular',
      );
    }
  }

  ResultFuture<MenuItem> uploadMenuItemImage({
    required String itemId,
    required String filePath,
  }) async {
    appLogger.d('OrdersRepository.uploadMenuItemImage → id=$itemId');
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
      });
      final response = await _client.post(
        ApiEndpoints.vendorMenuItemImage(itemId),
        data: formData,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final item = MenuItem.fromJson(_dataMap(response));
        appLogger.i(
          'OrdersRepository.uploadMenuItemImage → success, id=${item.id}',
        );
        return Right(item);
      }
      appLogger.w(
        'OrdersRepository.uploadMenuItemImage → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'OrdersRepository.uploadMenuItemImage → DioException',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'OrdersRepository',
        methodName: 'uploadMenuItemImage',
      );
    }
  }

  // ─── Private Helpers ───────────────────────────────────────────────────────

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
        for (final key in ['data', 'items', 'docs', 'results', 'list']) {
          final nested = d[key];
          if (nested is List) return nested;
        }
      }
    }
    return const [];
  }

  /// Builds the request body for create/update, restricted to the fields
  /// the backend's menu-item contract actually accepts. Image upload is a
  /// separate multipart call (`uploadMenuItemImage`) against the item's id,
  /// so no image data is embedded here.
  DataMap _buildMenuItemBody(DataMap data) {
    return {
      'name': data['name'] ?? '',
      'description': data['description'] ?? '',
      'price': data['price'] is num
          ? data['price']
          : double.tryParse(data['price']?.toString() ?? '') ?? 0.0,
      'category_id': data['category_id'],
      'is_available': data['is_available'] ?? true,
      'is_featured': data['is_featured'] ?? false,
      'minimum_order_qty': data['minimum_order_qty'] ?? 1,
      if (data['maximum_order_qty'] != null)
        'maximum_order_qty': data['maximum_order_qty'],
      if (data['addon_groups'] != null) 'addon_groups': data['addon_groups'],
    };
  }
}
