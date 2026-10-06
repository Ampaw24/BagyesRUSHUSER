import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/json_utils.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import '../models/customer_wallet_model.dart';
import '../models/customer_withdrawal_model.dart';

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

  /// `PUT /customer/wallet/payout-method` — picks the network the account's
  /// verified phone number is paid out through.
  ResultFuture<void> setPayoutMethod({required int payoutProviderId}) async {
    appLogger.d('CustomerWalletRepository.setPayoutMethod → provider=$payoutProviderId');
    try {
      final response = await _client.put(
        ApiEndpoints.customerWalletPayoutMethod,
        data: {'payout_provider_id': payoutProviderId},
      );

      if ([200, 201].contains(response.statusCode)) {
        appLogger.i('CustomerWalletRepository.setPayoutMethod → success');
        return const Right(null);
      }

      appLogger.w('CustomerWalletRepository.setPayoutMethod → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('CustomerWalletRepository.setPayoutMethod → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'CustomerWalletRepository',
        methodName: 'setPayoutMethod',
      );
    }
  }

  /// `GET /customer/withdrawals`
  ResultFuture<CustomerWithdrawalPage> getWithdrawals({
    int page = 1,
    int limit = 20,
  }) async {
    appLogger.d('CustomerWalletRepository.getWithdrawals → page=$page');
    try {
      final response = await _client.get(
        ApiEndpoints.customerWithdrawals,
        queryParameters: {'page': page, 'limit': limit},
      );

      if ([200, 201].contains(response.statusCode)) {
        final withdrawals = [
          for (final item in _extractList(response.data))
            if (item is DataMap) ?CustomerWithdrawalModel.tryFromJson(item),
        ];
        final meta = _extractMeta(response.data);
        appLogger.i(
          'CustomerWalletRepository.getWithdrawals → loaded ${withdrawals.length}',
        );
        return Right(
          CustomerWithdrawalPage(
            withdrawals: withdrawals,
            page: JsonUtils.asInt(meta['page'] ?? meta['current_page'], page),
            totalPages: JsonUtils.asInt(meta['pages'] ?? meta['last_page'], 1),
          ),
        );
      }

      appLogger.w('CustomerWalletRepository.getWithdrawals → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('CustomerWalletRepository.getWithdrawals → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'CustomerWalletRepository',
        methodName: 'getWithdrawals',
      );
    }
  }

  /// `POST /customer/withdrawals` — only the amount is sent; the destination
  /// is the customer's saved payout method. Returns the created request when
  /// the response carries one.
  ResultFuture<CustomerWithdrawalModel?> requestWithdrawal({
    required num amount,
  }) async {
    appLogger.d('CustomerWalletRepository.requestWithdrawal → amount=$amount');
    try {
      final response = await _client.post(
        ApiEndpoints.customerWithdrawals,
        data: {'amount': amount},
      );

      if ([200, 201].contains(response.statusCode)) {
        appLogger.i('CustomerWalletRepository.requestWithdrawal → success');
        return Right(CustomerWithdrawalModel.tryFromJson(_extractObject(response.data)));
      }

      appLogger.w('CustomerWalletRepository.requestWithdrawal → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('CustomerWalletRepository.requestWithdrawal → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'CustomerWalletRepository',
        methodName: 'requestWithdrawal',
      );
    }
  }

  /// `PATCH /customer/withdrawals/:id/cancel` — no body.
  ResultFuture<CustomerWithdrawalModel?> cancelWithdrawal(String id) async {
    appLogger.d('CustomerWalletRepository.cancelWithdrawal → id=$id');
    try {
      final response = await _client.patch(
        ApiEndpoints.customerWithdrawalCancel(id),
      );

      if ([200, 201].contains(response.statusCode)) {
        appLogger.i('CustomerWalletRepository.cancelWithdrawal → success id=$id');
        return Right(CustomerWithdrawalModel.tryFromJson(_extractObject(response.data)));
      }

      appLogger.w('CustomerWalletRepository.cancelWithdrawal → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('CustomerWalletRepository.cancelWithdrawal → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'CustomerWalletRepository',
        methodName: 'cancelWithdrawal',
      );
    }
  }

  /// Unwraps a list payload from `{ data: [...] }` or a nested
  /// `{ data: { items: [...] } }` envelope.
  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is DataMap) {
      final d = body['data'];
      if (d is List) return d;
      if (d is DataMap) {
        for (final key in ['items', 'data', 'docs', 'results', 'list']) {
          final nested = d[key];
          if (nested is List) return nested;
        }
      }
    }
    return const [];
  }

  /// Pagination `meta`, at the top level or one level under `data`.
  DataMap _extractMeta(dynamic body) {
    if (body is DataMap) {
      final meta = body['meta'];
      if (meta is DataMap) return meta;
      final d = body['data'];
      if (d is DataMap) {
        final nested = d['meta'];
        if (nested is DataMap) return nested;
      }
    }
    return const {};
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
