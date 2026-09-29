import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/order_review.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/review_target.dart';

/// Customer-side reviews. One review per order, rating the vendor and/or
/// the rider in the same request.
class OrderReviewRepository {
  const OrderReviewRepository({required Dio client}) : _client = client;

  final Dio _client;

  /// `POST /customer/orders/:id/review` with `vendor_rating`,
  /// `vendor_comment`, `rider_rating`, `rider_comment` — each optional. The
  /// success shape is undocumented: a returned review carrying ratings is
  /// used as-is; otherwise one is built from the submitted [ratings].
  ResultFuture<OrderReview> submitReview({
    required String orderId,
    required Map<ReviewSubject, SubjectRating> ratings,
  }) async {
    appLogger.d(
      'OrderReviewRepository.submitReview → order=$orderId '
      'subjects=${ratings.keys.map((s) => s.name).join(',')}',
    );
    try {
      final response = await _client.post(
        ApiEndpoints.customerOrderReview(orderId),
        data: reviewRequestBody(ratings),
      );

      if ([200, 201].contains(response.statusCode)) {
        final map = _dataMap(response);
        final returned = OrderReview.fromJson(map, orderId: orderId);
        final review = returned.ratings.isNotEmpty
            ? returned
            : OrderReview(
                id: returned.id,
                orderId: orderId,
                ratings: ratings,
                createdAt: DateTime.now(),
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
  /// Only reviews that carry an order id are useful here.
  ResultFuture<List<OrderReview>> getMyReviews({int perPage = 50}) async {
    appLogger.d('OrderReviewRepository.getMyReviews → initiated');
    try {
      final response = await _client.get(
        ApiEndpoints.customerReviews,
        queryParameters: {'per_page': perPage},
      );

      if ([200, 201].contains(response.statusCode)) {
        final reviews = _dataList(response)
            .whereType<DataMap>()
            .map(OrderReview.fromJson)
            .where((r) => r.orderId.isNotEmpty)
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
