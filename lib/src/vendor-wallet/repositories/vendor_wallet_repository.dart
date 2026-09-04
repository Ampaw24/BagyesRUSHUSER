import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/json_utils.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import '../models/vendor_wallet_model.dart';
import '../models/vendor_wallet_transaction_model.dart';
import '../models/vendor_withdrawal_model.dart';

/// Talks to the `vendor/wallet` API — `App\Http\Controllers\Api\V1\Vendor\WalletController`.
/// Restricted to role: vendor.
class VendorWalletRepository {
  const VendorWalletRepository({required Dio client}) : _client = client;

  final Dio _client;

  /// `GET /vendor/me/wallet`
  ResultFuture<VendorWalletModel> getWallet() async {
    appLogger.d('VendorWalletRepository.getWallet → initiated');
    try {
      final response = await _client.get(ApiEndpoints.vendorMeWallet);

      if ([200, 201].contains(response.statusCode)) {
        final wallet = VendorWalletModel.fromJson(_extractObject(response.data));
        appLogger.i('VendorWalletRepository.getWallet → balance=${wallet.balance}');
        return Right(wallet);
      }

      appLogger.w('VendorWalletRepository.getWallet → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('VendorWalletRepository.getWallet → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'VendorWalletRepository',
        methodName: 'getWallet',
      );
    }
  }

  /// `GET /vendor/me/wallet/transactions`
  ResultFuture<VendorWalletTransactionListResult> getWalletTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    appLogger.d('VendorWalletRepository.getWalletTransactions → page=$page');
    try {
      final response = await _client.get(
        ApiEndpoints.vendorMeWalletTransactions,
        queryParameters: {'page': page, 'limit': limit},
      );

      if ([200, 201].contains(response.statusCode)) {
        final list = _extractList(response.data);
        final meta = _extractMeta(response.data);
        final transactions = list
            .map(
              (e) => VendorWalletTransactionModel.fromJson(e as DataMap),
            )
            .toList();
        final result = VendorWalletTransactionListResult(
          transactions: transactions,
          page: JsonUtils.asInt(meta['page'] ?? meta['current_page'], page),
          totalPages: JsonUtils.asInt(meta['pages'] ?? meta['last_page'], 1),
          total: JsonUtils.asInt(meta['total'], transactions.length),
        );
        appLogger.i(
          'VendorWalletRepository.getWalletTransactions → loaded ${transactions.length} transactions',
        );
        return Right(result);
      }

      appLogger.w(
        'VendorWalletRepository.getWalletTransactions → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'VendorWalletRepository.getWalletTransactions → DioException',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'VendorWalletRepository',
        methodName: 'getWalletTransactions',
      );
    }
  }

  /// `GET /vendor/me/withdrawals`
  ResultFuture<VendorWithdrawalListResult> getWithdrawals({
    int page = 1,
    int limit = 20,
  }) async {
    appLogger.d('VendorWalletRepository.getWithdrawals → page=$page');
    try {
      final response = await _client.get(
        ApiEndpoints.vendorMeWithdrawals,
        queryParameters: {'page': page, 'limit': limit},
      );

      if ([200, 201].contains(response.statusCode)) {
        final list = _extractList(response.data);
        final meta = _extractMeta(response.data);
        final withdrawals = list
            .map((e) => VendorWithdrawalModel.fromJson(e as DataMap))
            .toList();
        final result = VendorWithdrawalListResult(
          withdrawals: withdrawals,
          page: JsonUtils.asInt(meta['page'] ?? meta['current_page'], page),
          totalPages: JsonUtils.asInt(meta['pages'] ?? meta['last_page'], 1),
          total: JsonUtils.asInt(meta['total'], withdrawals.length),
        );
        appLogger.i(
          'VendorWalletRepository.getWithdrawals → loaded ${withdrawals.length} withdrawals',
        );
        return Right(result);
      }

      appLogger.w(
        'VendorWalletRepository.getWithdrawals → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('VendorWalletRepository.getWithdrawals → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'VendorWalletRepository',
        methodName: 'getWithdrawals',
      );
    }
  }

  /// `POST /vendor/me/withdrawals` — payout destination comes from the
  /// vendor's saved payout details (`PUT vendor/me/payout`); only the amount
  /// is sent here. Field rules: amount required, numeric, min:1, max:1000000.
  ResultFuture<VendorWithdrawalModel> requestWithdrawal({
    required num amount,
  }) async {
    appLogger.d('VendorWalletRepository.requestWithdrawal → amount=$amount');
    try {
      final response = await _client.post(
        ApiEndpoints.vendorMeWithdrawals,
        data: {'amount': amount},
      );

      if ([200, 201].contains(response.statusCode)) {
        final withdrawal = VendorWithdrawalModel.fromJson(
          _extractObject(response.data),
        );
        appLogger.i(
          'VendorWalletRepository.requestWithdrawal → success id=${withdrawal.id}',
        );
        return Right(withdrawal);
      }

      appLogger.w(
        'VendorWalletRepository.requestWithdrawal → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'VendorWalletRepository.requestWithdrawal → DioException',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'VendorWalletRepository',
        methodName: 'requestWithdrawal',
      );
    }
  }

  /// `PATCH /vendor/me/withdrawals/:id/cancel` — no body or reason required.
  ResultFuture<VendorWithdrawalModel> cancelWithdrawal(String id) async {
    appLogger.d('VendorWalletRepository.cancelWithdrawal → id=$id');
    try {
      final response = await _client.patch(
        ApiEndpoints.vendorMeWithdrawalCancel(id),
      );

      if ([200, 201].contains(response.statusCode)) {
        final withdrawal = VendorWithdrawalModel.fromJson(
          _extractObject(response.data),
        );
        appLogger.i('VendorWalletRepository.cancelWithdrawal → success id=$id');
        return Right(withdrawal);
      }

      appLogger.w(
        'VendorWalletRepository.cancelWithdrawal → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'VendorWalletRepository.cancelWithdrawal → DioException',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'VendorWalletRepository',
        methodName: 'cancelWithdrawal',
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

  /// Unwraps a list payload from `{ data: [...] }` or a nested
  /// `{ data: { items: [...] } }` envelope, matching
  /// `TransactionRepository._extractList`'s fallback keys.
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

  /// Unwraps pagination `meta`, checking both the top level and one level
  /// under `data`.
  DataMap _extractMeta(dynamic body) {
    if (body is DataMap) {
      final meta = body['meta'];
      if (meta is DataMap) return meta;
      final d = body['data'];
      if (d is DataMap) {
        final nestedMeta = d['meta'];
        if (nestedMeta is DataMap) return nestedMeta;
      }
    }
    return const {};
  }
}
