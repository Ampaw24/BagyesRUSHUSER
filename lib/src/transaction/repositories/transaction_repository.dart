import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  const TransactionRepository({required Dio client}) : _client = client;

  final Dio _client;

  ResultFuture<TransactionListResult> getCustomerTransactions({
    int page = 1,
    int limit = 20,
    String? status,
    String? q,
  }) async {
    appLogger.d('TransactionRepository.getCustomerTransactions → page=$page');
    try {
      final response = await _client.get(
        ApiEndpoints.customerTransactions,
        queryParameters: {
          'page': page,
          'limit': limit,
          ...?status == null ? null : {'status': status},
          ...?q != null ? {'q': q} : null,
        },
      );

      if ([200, 201].contains(response.statusCode)) {
        final payload = _extractList(response.data);
        final transactions = payload
            .map((e) => TransactionModel.fromJson(e as DataMap))
            .toList();
        final metaJson = _extractMeta(response.data);
        final meta = metaJson == null
            ? TransactionMeta(
                page: page,
                limit: limit,
                total: transactions.length,
                pages: 1,
                hasMore: false,
              )
            : TransactionMeta.fromJson(metaJson);

        appLogger.i(
          'TransactionRepository.getCustomerTransactions → loaded ${transactions.length} transactions',
        );
        return Right(TransactionListResult(transactions: transactions, meta: meta));
      }

      appLogger.w(
        'TransactionRepository.getCustomerTransactions → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'TransactionRepository.getCustomerTransactions → DioException',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'TransactionRepository',
        methodName: 'getCustomerTransactions',
      );
    }
  }

  /// Unwraps the transaction list from `{ data: [...] }` or a nested
  /// `{ data: { items: [...] } }` envelope — this backend's real shape for
  /// `/customer/transactions` — trying the common wrapper keys, matching
  /// `OrdersRepository._dataList`'s fallback list.
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
  /// under `data` — same double-nesting the list can arrive in.
  DataMap? _extractMeta(dynamic body) {
    if (body is DataMap) {
      final meta = body['meta'];
      if (meta is DataMap) return meta;
      final d = body['data'];
      if (d is DataMap) {
        final nestedMeta = d['meta'];
        if (nestedMeta is DataMap) return nestedMeta;
      }
    }
    return null;
  }
}
