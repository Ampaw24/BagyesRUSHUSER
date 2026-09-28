import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/customer_address/models/customer_address.dart';

class CustomerAddressRepository {
  const CustomerAddressRepository({required Dio client}) : _client = client;

  final Dio _client;

  /// `GET /customer/addresses`
  ResultFuture<List<CustomerAddress>> getAddresses() async {
    try {
      final response = await _client.get(ApiEndpoints.customerAddresses);
      if (response.statusCode == 200) {
        final body = response.data;
        final data = body is DataMap ? body['data'] : body;
        final list = data is List
            ? data
            : (data is DataMap && data['data'] is List ? data['data'] as List : const []);
        return Right(
          list.map((e) => CustomerAddress.fromJson(e as DataMap)).toList(),
        );
      }
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('CustomerAddressRepository.getAddresses', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'CustomerAddressRepository',
        methodName: 'getAddresses',
      );
    }
  }

  /// `POST /customer/addresses`
  ResultFuture<CustomerAddress> createAddress({
    required String address,
    required double latitude,
    required double longitude,
    bool isDefault = false,
  }) async {
    try {
      final response = await _client.post(
        ApiEndpoints.customerAddresses,
        data: {
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          if (isDefault) 'is_default': true,
        },
      );
      if ([200, 201].contains(response.statusCode)) {
        final body = response.data;
        final data = body is DataMap && body['data'] is DataMap
            ? body['data'] as DataMap
            : body as DataMap;
        return Right(CustomerAddress.fromJson(data));
      }
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('CustomerAddressRepository.createAddress', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'CustomerAddressRepository',
        methodName: 'createAddress',
      );
    }
  }
}
