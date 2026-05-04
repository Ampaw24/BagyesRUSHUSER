import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import '../models/order.dart' as ord;

class OrdersRepository {
  const OrdersRepository({required Dio client}) : _client = client;

  final Dio _client;

  ResultFuture<List<ord.Order>> getCustomerOrders() async {
    appLogger.d('OrdersRepository.getCustomerOrders → initiated');
    try {
      final response = await _client.get(ApiEndpoints.customerOrders);

      if (response.statusCode == 200) {
        final payload = (response.data as DataMap)['data'] as List<dynamic>? ??
            response.data as List<dynamic>;
        final orders =
            payload.map((e) => ord.Order.fromJson(e as DataMap)).toList();
        appLogger.i('OrdersRepository.getCustomerOrders → success, loaded ${orders.length} orders');
        return Right(orders);
      }

      appLogger.w('OrdersRepository.getCustomerOrders → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('OrdersRepository.getCustomerOrders → DioException', error: e);
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
      final response = await _client.get(ApiEndpoints.customerOrderById(orderId));

      if (response.statusCode == 200) {
        final payload = (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;
        final order = ord.Order.fromJson(payload);
        appLogger.i('OrdersRepository.getOrderById → success');
        return Right(order);
      }

      appLogger.w('OrdersRepository.getOrderById → HTTP ${response.statusCode}');
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
}
