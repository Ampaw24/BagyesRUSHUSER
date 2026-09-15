import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import '../models/customer_wallet_model.dart';

/// Talks to the `customer/wallet` API — `App\Http\Controllers\Api\V1\Customer\WalletController`.
/// Restricted to role: customer.
class CustomerWalletRepository {
  const CustomerWalletRepository({required Dio client}) : _client = client;

  final Dio _client;

  /// `GET /customer/wallet`
  ResultFuture<CustomerWalletModel> getWallet() async {
    appLogger.d('CustomerWalletRepository.getWallet → initiated');
    try {
      final response = await _client.get(ApiEndpoints.customerWallet);

      if ([200, 201].contains(response.statusCode)) {
        final wallet = CustomerWalletModel.fromJson(_extractObject(response.data));
        appLogger.i('CustomerWalletRepository.getWallet → balance=${wallet.balance}');
        return Right(wallet);
      }

      appLogger.w('CustomerWalletRepository.getWallet → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('CustomerWalletRepository.getWallet → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'CustomerWalletRepository',
        methodName: 'getWallet',
      );
    }
  }

  /// Unwraps a single-object payload from `{ data: {...} }` or a bare object.
  DataMap _extractObject(dynamic body) {
    if (body is DataMap) {
      final d = body['data'];
      if (d is DataMap) return d;
      return body;
    }
    return const {};
  }
}
