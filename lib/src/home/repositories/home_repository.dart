import 'package:dartz/dartz.dart' hide Order;
import 'package:dio/dio.dart';
import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/home/models/business_type.model.dart';
import 'package:bagyesrushappusernew/src/home/models/category.dart';
import 'package:bagyesrushappusernew/src/home/models/category_element.model.dart';
import 'package:bagyesrushappusernew/src/home/models/menu_item.dart';
import 'package:bagyesrushappusernew/src/home/models/order.dart';
import 'package:bagyesrushappusernew/src/home/models/vendor.dart';

class HomeRepository {
  const HomeRepository({required Dio client}) : _client = client;

  final Dio _client;

  // ─── Business Types ────────────────────────────────────────────────────────

  ResultFuture<List<BusinessType>> getBusinessTypes() async {
    appLogger.d('HomeRepository.getBusinessTypes → initiated');
    try {
      final response = await _client.get(ApiEndpoints.businessTypes);

      if ([200, 201].contains(response.statusCode)) {
        final payload = (response.data as DataMap)['data'] as List<dynamic>? ??
            response.data as List<dynamic>;
        final businessTypes =
            payload.map((e) => BusinessType.fromJson(e as DataMap)).toList();
        appLogger.i(
            'HomeRepository.getBusinessTypes → loaded ${businessTypes.length} business types');
        return Right(businessTypes);
      }

      appLogger.w(
          'HomeRepository.getBusinessTypes → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('HomeRepository.getBusinessTypes → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'HomeRepository', methodName: 'getBusinessTypes');
    }
  }

  // ─── Categories ────────────────────────────────────────────────────────────
 //["This defines the API endpoint for fetching categories. It is a static constant string that can be used throughout the application to make API calls related to categories."]
 //[categories such as pizza , burgers , soups , locals etc ..]
  ResultFuture<List<Category>> getCategories() async {
    appLogger.d('HomeRepository.getCategories → initiated');
    try {
      final response = await _client.get(ApiEndpoints.categories);

      if ([200, 201].contains(response.statusCode)) {
        final data = (response.data as DataMap)['data'] as DataMap;
        final categories = [Category.fromJson(data)];
        appLogger.i(
            'HomeRepository.getCategories → loaded ${categories.first.categories.length} categories');
        return Right(categories);
      }

      appLogger.w(
          'HomeRepository.getCategories → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('HomeRepository.getCategories → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'HomeRepository', methodName: 'getCategories');
    }
  }
  //[Get a single category element by ID value.]
  
  ResultFuture<CategoryElement> getCategoryById(String id) async {
    appLogger.d('HomeRepository.getCategoryById → id=$id');
    try {
      final response = await _client.get(ApiEndpoints.categoryById(id));

      if (response.statusCode == 200) {
        final payload = (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;
        final category = CategoryElement.fromJson(payload);
        appLogger.i(
            'HomeRepository.getCategoryById → loaded category id=${category.id}');
        return Right(category);
      }

      appLogger.w(
          'HomeRepository.getCategoryById → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('HomeRepository.getCategoryById → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'HomeRepository', methodName: 'getCategoryById');
    }
  }

  //-- Categories ends here --//


  // ─── Vendors ───────────────────────────────────────────────────────────────

  ResultFuture<List<Vendor>> getVendors({String? categoryId}) async {
    appLogger.d(
        'HomeRepository.getVendors → categoryId=${categoryId ?? 'all'}');
    try {
      final queryParams = <String, dynamic>{
        if (categoryId != null) 'category_id': categoryId,
      };
      final response = await _client.get(
        ApiEndpoints.vendors,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if ([200, 201].contains(response.statusCode)) {
        final payload = (response.data as DataMap)['data'] as List<dynamic>? ??
            response.data as List<dynamic>;
        final vendors =
            payload.map((e) => Vendor.fromJson(e as DataMap)).toList();
        appLogger.i(
            'HomeRepository.getVendors → loaded ${vendors.length} vendors');
        return Right(vendors);
      }

      appLogger.w('HomeRepository.getVendors → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('HomeRepository.getVendors → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'HomeRepository', methodName: 'getVendors');
    }
  }

  ResultFuture<Vendor> getVendorById(String vendorId) async {
    appLogger.d('HomeRepository.getVendorById → vendorId=$vendorId');
    try {
      final response =
          await _client.get(ApiEndpoints.vendorById(vendorId));

      if (response.statusCode == 200) {
        final payload = (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;
        final vendor = Vendor.fromJson(payload);
        appLogger.i(
            'HomeRepository.getVendorById → loaded vendor id=${vendor.id}');
        return Right(vendor);
      }

      appLogger.w(
          'HomeRepository.getVendorById → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('HomeRepository.getVendorById → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'HomeRepository', methodName: 'getVendorById');
    }
  }

  // ─── Menu Items ────────────────────────────────────────────────────────────

  ResultFuture<List<MenuItem>> getVendorMenuItems(String vendorId) async {
    appLogger.d(
        'HomeRepository.getVendorMenuItems → vendorId=$vendorId');
    try {
      final response =
          await _client.get(ApiEndpoints.vendorMenuItems(vendorId));

      if ([200, 201].contains(response.statusCode)) {
        final payload = (response.data as DataMap)['data'] as List<dynamic>? ??
            response.data as List<dynamic>;
        final items =
            payload.map((e) => MenuItem.fromJson(e as DataMap)).toList();
        appLogger.i(
            'HomeRepository.getVendorMenuItems → loaded ${items.length} items');
        return Right(items);
      }

      appLogger.w(
          'HomeRepository.getVendorMenuItems → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
          'HomeRepository.getVendorMenuItems → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'HomeRepository', methodName: 'getVendorMenuItems');
    }
  }

  // ─── Orders ────────────────────────────────────────────────────────────────

  ResultFuture<List<Order>> getOrders() async {
    appLogger.d('HomeRepository.getOrders → initiated');
    try {
      final response = await _client.get(ApiEndpoints.customerOrders);

      if ([200, 201].contains(response.statusCode)) {
        final payload = (response.data as DataMap)['data'] as List<dynamic>? ??
            response.data as List<dynamic>;
        final orders =
            payload.map((e) => Order.fromJson(e as DataMap)).toList();
        appLogger.i(
            'HomeRepository.getOrders → loaded ${orders.length} orders');
        return Right(orders);
      }

      appLogger.w('HomeRepository.getOrders → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('HomeRepository.getOrders → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'HomeRepository', methodName: 'getOrders');
    }
  }

  ResultFuture<Order> getOrderById(String orderId) async {
    appLogger.d('HomeRepository.getOrderById → orderId=$orderId');
    try {
      final response =
          await _client.get(ApiEndpoints.customerOrderById(orderId));

      if (response.statusCode == 200) {
        final payload = (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;
        final order = Order.fromJson(payload);
        appLogger.i(
            'HomeRepository.getOrderById → loaded order id=${order.id}');
        return Right(order);
      }

      appLogger.w(
          'HomeRepository.getOrderById → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('HomeRepository.getOrderById → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'HomeRepository', methodName: 'getOrderById');
    }
  }

  ResultFuture<Order> placeOrder({
    required String vendorId,
    required List<OrderItem> items,
    required String deliveryAddress,
  }) async {
    appLogger.d(
        'HomeRepository.placeOrder → vendorId=$vendorId, items=${items.length}');
    final data = {
      'vendor_id': vendorId,
      'items': items.map((e) => e.toJson()).toList(),
      'delivery_address': deliveryAddress,
    };
    try {
      final response =
          await _client.post(ApiEndpoints.customerOrders, data: data);

      if ([200, 201].contains(response.statusCode)) {
        final payload = (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;
        final order = Order.fromJson(payload);
        appLogger.i(
            'HomeRepository.placeOrder → order placed id=${order.id}');
        return Right(order);
      }

      appLogger.w('HomeRepository.placeOrder → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('HomeRepository.placeOrder → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(e, s,
          repositoryName: 'HomeRepository', methodName: 'placeOrder');
    }
  }
}
