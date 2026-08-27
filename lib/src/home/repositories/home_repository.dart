import 'package:bagyesrushappusernew/src/home/models/ads_banner.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/home/models/category.dart';

/// Only [getHomePageBanners] and [getCategories] are live — this repository
/// used to also cover vendors/menu-items/orders, but those are all now
/// served by `features/consumer/restaurant` and `features/consumer/orders`.
class HomeRepository {
  const HomeRepository({required Dio client}) : _client = client;

  final Dio _client;

  // -- Get banner ads for home page --
  ResultFuture<AdBannerModel> getHomePageBanners() async {
    appLogger.d('HomeRepository.getHomePageBanners → initiated');
    try {
      final response = await _client.get(ApiEndpoints.adsBanners);
      if ([200, 201].contains(response.statusCode)) {
        final payload =
            (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;
        final adBannerModel = AdBannerModel.fromJson(payload);
        appLogger.i(
          'HomeRepository.getHomePageBanners → loaded ${adBannerModel.banners.length} banners',
        );
        return Right(adBannerModel);
      }

      appLogger.w(
        'HomeRepository.getHomePageBanners → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('HomeRepository.getHomePageBanners → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'HomeRepository',
        methodName: 'getHomePageBanners',
      );
    }
  }

  //Get all Vendors
  //["This method fetches a list of vendors from the server. It accepts an optional categoryId parameter to filter vendors by category. The method makes a GET request to the API endpoint for vendors, passing the categoryId as a query parameter if provided. It handles the response and errors appropriately, returning either a list of Vendor objects or an error message.
  //"]

  // ─── Categories ────────────────────────────────────────────────────────────
  //["This defines the API endpoint for fetching categories. It is a static constant string that can be used throughout the application to make API calls related to categories."]
  //[categories such as pizza , burgers , soups , locals etc ..]
  ResultFuture<List<Category>> getCategories() async {
    appLogger.d('HomeRepository.getCategories → initiated');
    try {
      final response = await _client.get(ApiEndpoints.categories);

      appLogger.d(
        'HomeRepository.getCategories → RAW RESPONSE\n'
        '  status : ${response.statusCode}\n'
        '  data   : ${response.data}',
      );

      if ([200, 201].contains(response.statusCode)) {
        final categories = [Category.fromResponseData(response.data)];
        appLogger.i(
          'HomeRepository.getCategories → loaded ${categories.first.categories.length} categories',
        );
        return Right(categories);
      }

      appLogger.w('HomeRepository.getCategories → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('HomeRepository.getCategories → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'HomeRepository',
        methodName: 'getCategories',
      );
    }
  }

}
