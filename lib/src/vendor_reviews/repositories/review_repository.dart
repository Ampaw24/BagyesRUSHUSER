import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/json_utils.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import '../models/review.dart';
import '../models/review_summary.dart';

/// One page of `GET /vendor/me/reviews`.
class ReviewsPage extends Equatable {
  const ReviewsPage({
    required this.items,
    required this.currentPage,
    required this.hasMore,
  });

  final List<Review> items;
  final int currentPage;
  final bool hasMore;

  @override
  List<Object?> get props => [items, currentPage, hasMore];
}

class ReviewRepository {
  const ReviewRepository({required Dio client}) : _client = client;

  final Dio _client;

  /// `GET /vendor/me/reviews`
  ResultFuture<ReviewsPage> getReviews({
    int? rating,
    bool? withComment,
    bool? unanswered,
    bool? isVisible,
    int page = 1,
    int perPage = 20,
  }) async {
    appLogger.d('ReviewRepository.getReviews → page=$page');
    try {
      final response = await _client.get(
        ApiEndpoints.vendorReviews,
        queryParameters: {
          'rating': ?rating,
          'with_comment': ?withComment,
          'unanswered': ?unanswered,
          'is_visible': ?isVisible,
          'per_page': perPage,
          'page': page,
        },
      );

      if ([200, 201].contains(response.statusCode)) {
        final items = _dataList(response)
            .map((e) => Review.fromJson(e as DataMap))
            .toList();
        appLogger.i(
          'ReviewRepository.getReviews → loaded ${items.length} reviews (page $page)',
        );
        return Right(
          ReviewsPage(
            items: items,
            currentPage: page,
            hasMore: _hasMore(
              response,
              page: page,
              perPage: perPage,
              itemCount: items.length,
            ),
          ),
        );
      }

      appLogger.w('ReviewRepository.getReviews → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('ReviewRepository.getReviews → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'ReviewRepository',
        methodName: 'getReviews',
      );
    }
  }

  /// `GET /vendor/me/reviews/summary`
  ResultFuture<ReviewSummary> getReviewsSummary() async {
    appLogger.d('ReviewRepository.getReviewsSummary → initiated');
    try {
      final response = await _client.get(ApiEndpoints.vendorReviewsSummary);

      if ([200, 201].contains(response.statusCode)) {
        final summary = ReviewSummary.fromJson(_dataMap(response));
        appLogger.i('ReviewRepository.getReviewsSummary → success');
        return Right(summary);
      }

      appLogger.w(
        'ReviewRepository.getReviewsSummary → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'ReviewRepository.getReviewsSummary → DioException',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'ReviewRepository',
        methodName: 'getReviewsSummary',
      );
    }
  }

  /// `POST /vendor/me/reviews/:id/reply` — the doc doesn't say whether the
  /// response carries the updated review or a bare acknowledgement, so this
  /// returns `null` data on a bare-ack response and lets the caller decide
  /// how to patch its own copy of the review.
  ResultFuture<Review?> replyToReview({
    required String reviewId,
    required String reply,
  }) async {
    appLogger.d('ReviewRepository.replyToReview → id=$reviewId');
    try {
      final response = await _client.post(
        ApiEndpoints.vendorReviewReply(reviewId),
        data: {'reply': reply},
      );

      if ([200, 201].contains(response.statusCode)) {
        final map = _dataMap(response);
        appLogger.i('ReviewRepository.replyToReview → success, id=$reviewId');
        return Right(map.isNotEmpty ? Review.fromJson(map) : null);
      }

      appLogger.w(
        'ReviewRepository.replyToReview → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('ReviewRepository.replyToReview → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'ReviewRepository',
        methodName: 'replyToReview',
      );
    }
  }

  // ─── Private Helpers ───────────────────────────────────────────────────────

  DataMap _dataMap(Response response) {
    final body = response.data;
    if (body is DataMap) {
      final d = body['data'];
      if (d is DataMap) {
        final inner = d['data'];
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
        for (final key in ['data', 'items', 'docs', 'results', 'list']) {
          final nested = d[key];
          if (nested is List) return nested;
        }
      }
    }
    return const [];
  }

  /// Tries a `meta`/`pagination` block (either at the top level or nested
  /// under `data`) for `current_page`/`last_page` or `total`; falls back to
  /// "got a full page back, assume there's more" when no such block exists —
  /// the doc explicitly flags this envelope as undocumented.
  bool _hasMore(
    Response response, {
    required int page,
    required int perPage,
    required int itemCount,
  }) {
    final body = response.data;
    DataMap? meta;
    if (body is DataMap) {
      final topMeta = body['meta'] ?? body['pagination'];
      if (topMeta is DataMap) {
        meta = topMeta;
      } else if (body['data'] is DataMap) {
        final nested =
            (body['data'] as DataMap)['meta'] ?? (body['data'] as DataMap)['pagination'];
        if (nested is DataMap) meta = nested;
      }
    }

    if (meta != null) {
      final lastPage = meta['last_page'] ?? meta['lastPage'] ?? meta['total_pages'];
      if (lastPage != null) {
        final currentPage = JsonUtils.asInt(
          meta['current_page'] ?? meta['currentPage'],
          page,
        );
        return currentPage < JsonUtils.asInt(lastPage);
      }
      final total = meta['total'];
      if (total != null) {
        return page * perPage < JsonUtils.asInt(total);
      }
    }

    return itemCount >= perPage;
  }
}
