import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/vendor_reviews/models/review.dart';

/// Customer-side reviews. One review per order — the backend attaches it to
/// the vendor (food order) or the rider (parcel) based on the order id.
class OrderReviewRepository {
  const OrderReviewRepository({required Dio client}) : _client = client;

  final Dio _client;

  /// `POST /customer/orders/:id/review`. The success shape is undocumented:
  /// a returned review object is used as-is; a bare acknowledgement is
  /// turned into a local [Review] from the submitted values.
  ResultFuture<Review> submitReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    appLogger.d('OrderReviewRepository.submitReview → order=$orderId');
    try {
      final response = await _client.post(
        ApiEndpoints.customerOrderReview(orderId),
        // An explicit `comment: null` fails `sometimes|string` validation.
        data: {'rating': rating, 'comment': ?comment},
      );

      if ([200, 201].contains(response.statusCode)) {
        final map = _dataMap(response);
        final review = map['rating'] != null
            ? Review.fromJson({'order_id': orderId, ...map})
            : Review(
                id: map['id']?.toString() ?? '',
                rating: rating,
                comment: comment,
                createdAt: DateTime.now(),
                customerName: '',
                orderId: orderId,
              );
        appLogger.i('OrderReviewRepository.submitReview → success');
        return Right(review);
      }

      appLogger.w(
        'OrderReviewRepository.submitReview → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'OrderReviewRepository.submitReview → DioException',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'OrderReviewRepository',
        methodName: 'submitReview',
      );
    }
  }

  /// `GET /customer/reviews` — used to know which orders are already rated.
  /// Only reviews that carry an `order_id` are useful here.
  ResultFuture<List<Review>> getMyReviews({int perPage = 50}) async {
    appLogger.d('OrderReviewRepository.getMyReviews → initiated');
    try {
      final response = await _client.get(
        ApiEndpoints.customerReviews,
        queryParameters: {'per_page': perPage},
      );

      if ([200, 201].contains(response.statusCode)) {
        final reviews = _dataList(response)
            .whereType<DataMap>()
            // Tolerate the order arriving nested (`order: {id}`) rather
            // than as a flat `order_id`.
            .map(
              (json) => Review.fromJson({
                if (json['order'] is DataMap)
                  'order_id': (json['order'] as DataMap)['id'],
                ...json,
              }),
            )
            .where((r) => r.orderId != null)
            .toList();
        appLogger.i(
          'OrderReviewRepository.getMyReviews → ${reviews.length} reviews',
        );
        return Right(reviews);
      }

      appLogger.w(
        'OrderReviewRepository.getMyReviews → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'OrderReviewRepository.getMyReviews → DioException',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'OrderReviewRepository',
        methodName: 'getMyReviews',
      );
    }
  }

  // ─── Private Helpers ───────────────────────────────────────────────────────

  DataMap _dataMap(Response response) {
    final body = response.data;
    if (body is DataMap) {
      final d = body['data'];
      if (d is DataMap) {
        final inner = d['data'] ?? d['review'];
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
        for (final key in ['data', 'items', 'reviews', 'results']) {
          final nested = d[key];
          if (nested is List) return nested;
        }
      }
    }
    return const [];
  }
}
