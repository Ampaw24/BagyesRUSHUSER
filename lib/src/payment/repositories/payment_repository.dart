import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/payment/models/payment_channel.dart';
import 'package:bagyesrushappusernew/src/payment/models/payment_init_result.dart';
import 'package:bagyesrushappusernew/src/payment/models/payment_transaction.dart';
import 'package:bagyesrushappusernew/src/payment/models/payment_verification_result.dart';
import 'package:bagyesrushappusernew/src/payment/models/payment_wallet.dart';

/// Talks to the `/payments/*` domain (BACKEND_API_SPEC.md §8.7). Named
/// `PaymentGatewayRepository` — not `PaymentRepository` — to avoid colliding
/// with the unrelated dummy `PaymentRepository` in
/// `features/vendor_payment_methods` (vendor payout-method storage).
///
/// Unlike the rest of the app, this domain's JSON bodies are camelCase
/// (`mobileMoneyProvider`, `paymentUrl`, `paidAt`, ...) per the explicit
/// examples in BACKEND_API_SPEC.md §8.7 and its "Field Naming Convention"
/// note — not the snake_case used by auth/orders/vendor endpoints.
class PaymentGatewayRepository {
  const PaymentGatewayRepository({required Dio client}) : _client = client;

  final Dio _client;

  ResultFuture<PaymentInitResult> initializePayment({
    required double amount,
    String currency = 'GHS',
    required PaymentChannel paymentMethod,
    MobileMoneyProvider? mobileMoneyProvider,
    String? phone,
    required String email,
    required String orderId,
    Map<String, dynamic>? metadata,
  }) async {
    appLogger.d('PaymentGatewayRepository.initializePayment → orderId=$orderId');
    try {
      final response = await _client.post(
        ApiEndpoints.paymentsInitialize,
        data: {
          'amount': amount,
          'currency': currency,
          'paymentMethod': paymentMethod.apiValue,
          if (mobileMoneyProvider != null)
            'mobileMoneyProvider': mobileMoneyProvider.apiValue,
          if (phone != null) 'phone': phone,
          'email': email,
          'orderId': orderId,
          if (metadata != null) 'metadata': metadata,
        },
      );

      appLogger.d(
        'PaymentGatewayRepository.initializePayment → RAW RESPONSE\n'
        '  status : ${response.statusCode}',
      );

      if ([200, 201].contains(response.statusCode)) {
        final payload =
            (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;
        final result = PaymentInitResult.fromJson(payload);
        appLogger.i(
          'PaymentGatewayRepository.initializePayment → success ref=${result.reference}',
        );
        return Right(result);
      }

      appLogger.w(
        'PaymentGatewayRepository.initializePayment → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'PaymentGatewayRepository.initializePayment → DioException\n'
        '  type   : ${e.type}\n'
        '  status : ${e.response?.statusCode}\n'
        '  data   : ${e.response?.data}',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'PaymentGatewayRepository',
        methodName: 'initializePayment',
      );
    }
  }

  ResultFuture<PaymentVerificationResult> verifyPayment(String reference) async {
    appLogger.d('PaymentGatewayRepository.verifyPayment → reference=$reference');
    try {
      final response = await _client.post(
        ApiEndpoints.paymentsVerify,
        data: {'reference': reference},
      );

      appLogger.d(
        'PaymentGatewayRepository.verifyPayment → RAW RESPONSE\n'
        '  status : ${response.statusCode}',
      );

      if ([200, 201].contains(response.statusCode)) {
        final payload =
            (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;
        final result = PaymentVerificationResult.fromJson(payload);
        appLogger.i(
          'PaymentGatewayRepository.verifyPayment → status=${result.status}',
        );
        return Right(result);
      }

      appLogger.w(
        'PaymentGatewayRepository.verifyPayment → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'PaymentGatewayRepository.verifyPayment → DioException\n'
        '  type   : ${e.type}\n'
        '  status : ${e.response?.statusCode}\n'
        '  data   : ${e.response?.data}',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'PaymentGatewayRepository',
        methodName: 'verifyPayment',
      );
    }
  }

  ResultFuture<PaymentWallet> getWallet() async {
    appLogger.d('PaymentGatewayRepository.getWallet → initiated');
    try {
      final response = await _client.get(ApiEndpoints.paymentsWallet);

      appLogger.d(
        'PaymentGatewayRepository.getWallet → RAW RESPONSE\n'
        '  status : ${response.statusCode}',
      );

      if ([200, 201].contains(response.statusCode)) {
        final payload =
            (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;
        final wallet = PaymentWallet.fromJson(payload);
        appLogger.i('PaymentGatewayRepository.getWallet → balance=${wallet.balance}');
        return Right(wallet);
      }

      appLogger.w('PaymentGatewayRepository.getWallet → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('PaymentGatewayRepository.getWallet → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'PaymentGatewayRepository',
        methodName: 'getWallet',
      );
    }
  }

  ResultFuture<PaymentInitResult> topUpWallet({
    required double amount,
    required PaymentChannel paymentMethod,
    MobileMoneyProvider? mobileMoneyProvider,
    String? phone,
  }) async {
    appLogger.d('PaymentGatewayRepository.topUpWallet → amount=$amount');
    try {
      final response = await _client.post(
        ApiEndpoints.paymentsWalletTopup,
        data: {
          'amount': amount,
          'paymentMethod': paymentMethod.apiValue,
          if (mobileMoneyProvider != null)
            'mobileMoneyProvider': mobileMoneyProvider.apiValue,
          if (phone != null) 'phone': phone,
        },
      );

      appLogger.d(
        'PaymentGatewayRepository.topUpWallet → RAW RESPONSE\n'
        '  status : ${response.statusCode}',
      );

      if ([200, 201].contains(response.statusCode)) {
        final payload =
            (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;
        final result = PaymentInitResult.fromJson(payload);
        appLogger.i(
          'PaymentGatewayRepository.topUpWallet → success ref=${result.reference}',
        );
        return Right(result);
      }

      appLogger.w('PaymentGatewayRepository.topUpWallet → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'PaymentGatewayRepository.topUpWallet → DioException\n'
        '  type   : ${e.type}\n'
        '  status : ${e.response?.statusCode}\n'
        '  data   : ${e.response?.data}',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'PaymentGatewayRepository',
        methodName: 'topUpWallet',
      );
    }
  }

  ResultFuture<DataMap> withdrawFromWallet({
    required double amount,
    required MobileMoneyProvider mobileMoneyProvider,
    required String phone,
    required String accountName,
  }) async {
    appLogger.d('PaymentGatewayRepository.withdrawFromWallet → amount=$amount');
    try {
      final response = await _client.post(
        ApiEndpoints.paymentsWalletWithdraw,
        data: {
          'amount': amount,
          'mobileMoneyProvider': mobileMoneyProvider.apiValue,
          'phone': phone,
          'accountName': accountName,
        },
      );

      appLogger.d(
        'PaymentGatewayRepository.withdrawFromWallet → RAW RESPONSE\n'
        '  status : ${response.statusCode}',
      );

      if ([200, 201].contains(response.statusCode)) {
        final payload =
            (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;
        appLogger.i('PaymentGatewayRepository.withdrawFromWallet → success');
        return Right(payload);
      }

      appLogger.w(
        'PaymentGatewayRepository.withdrawFromWallet → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'PaymentGatewayRepository.withdrawFromWallet → DioException\n'
        '  type   : ${e.type}\n'
        '  status : ${e.response?.statusCode}\n'
        '  data   : ${e.response?.data}',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'PaymentGatewayRepository',
        methodName: 'withdrawFromWallet',
      );
    }
  }

  ResultFuture<PaymentHistoryResult> getTransactionHistory({
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    appLogger.d('PaymentGatewayRepository.getTransactionHistory → page=$page');
    try {
      final response = await _client.get(
        ApiEndpoints.paymentsHistory,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (type != null) 'type': type,
        },
      );

      appLogger.d(
        'PaymentGatewayRepository.getTransactionHistory → RAW RESPONSE\n'
        '  status : ${response.statusCode}',
      );

      if ([200, 201].contains(response.statusCode)) {
        final (list, meta) = _extractHistoryList(response.data);
        final transactions = list
            .map((e) => PaymentTransaction.fromJson(e as DataMap))
            .toList();
        final result = PaymentHistoryResult(
          transactions: transactions,
          page: (meta['page'] as num?)?.toInt() ?? page,
          totalPages: (meta['totalPages'] as num?)?.toInt() ?? 1,
          total: (meta['total'] as num?)?.toInt() ?? transactions.length,
        );
        appLogger.i(
          'PaymentGatewayRepository.getTransactionHistory → loaded ${transactions.length} transactions',
        );
        return Right(result);
      }

      appLogger.w(
        'PaymentGatewayRepository.getTransactionHistory → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'PaymentGatewayRepository.getTransactionHistory → DioException',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'PaymentGatewayRepository',
        methodName: 'getTransactionHistory',
      );
    }
  }

  /// Pulls the transaction list + pagination meta out of [rawData] regardless
  /// of whether the API wraps it as `{ data: [...], meta: {...} }` or nests
  /// the list one level deeper under `data`.
  (List<dynamic>, DataMap) _extractHistoryList(dynamic rawData) {
    if (rawData is DataMap) {
      final data = rawData['data'];
      final meta = rawData['meta'] as DataMap? ?? {};
      if (data is List) return (data, meta);
      if (data is DataMap) {
        final inner = data['data'];
        if (inner is List) return (inner, meta);
      }
    }
    return (const [], const {});
  }
}
