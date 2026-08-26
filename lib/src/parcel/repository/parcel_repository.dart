import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import '../model/parcel.dart';
import '../model/parcel_photo.dart';
import '../model/parcel_quote.dart';

class ParcelRepository {
  const ParcelRepository({required Dio client}) : _client = client;

  final Dio _client;

  // ─── Parcels ─────────────────────────────────────────────────────────────

  ResultFuture<List<Parcel>> getParcels() async {
    appLogger.d('ParcelRepository.getParcels → initiated');
    try {
      final response = await _client.get(ApiEndpoints.customerParcels);

      if ([200, 201].contains(response.statusCode)) {
        final parcels =
            _dataList(response).map((e) => Parcel.fromJson(e as DataMap)).toList();
        appLogger.i(
          'ParcelRepository.getParcels → success, loaded ${parcels.length} parcels',
        );
        return Right(parcels);
      }

      appLogger.w('ParcelRepository.getParcels → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('ParcelRepository.getParcels → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'ParcelRepository',
        methodName: 'getParcels',
      );
    }
  }

  ResultFuture<Parcel> getParcelById({required String id}) async {
    appLogger.d('ParcelRepository.getParcelById → id=$id');
    try {
      final response = await _client.get(ApiEndpoints.customerParcelById(id));

      if ([200, 201].contains(response.statusCode)) {
        final parcel = Parcel.fromJson(_dataMap(response));
        appLogger.i('ParcelRepository.getParcelById → success');
        return Right(parcel);
      }

      appLogger.w(
        'ParcelRepository.getParcelById → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('ParcelRepository.getParcelById → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'ParcelRepository',
        methodName: 'getParcelById',
      );
    }
  }

  ResultFuture<Parcel> createParcel({
    required int deliveryQuoteId,
    required String paymentMethod,
    int? paymentMethodId,
    required String itemDescription,
    int? quantity,
    bool? isFragile,
    double? declaredValue,
    required String pickupAddress,
    String? pickupContactName,
    String? pickupContactPhone,
    String? pickupInstructions,
    required String dropoffAddress,
    String? recipientName,
    String? recipientPhone,
    String? deliveryInstructions,
    List<int>? photoIds,
  }) async {
    appLogger.d('ParcelRepository.createParcel → initiated');
    try {
      final body = <String, dynamic>{
        'delivery_quote_id': deliveryQuoteId,
        'payment_method': paymentMethod,
        'payment_method_id': paymentMethodId,
        'item_description': itemDescription,
        'quantity': quantity,
        'is_fragile': isFragile,
        'declared_value': declaredValue,
        'pickup_address': pickupAddress,
        'pickup_contact_name': pickupContactName,
        'pickup_contact_phone': pickupContactPhone,
        'pickup_instructions': pickupInstructions,
        'dropoff_address': dropoffAddress,
        'recipient_name': recipientName,
        'recipient_phone': recipientPhone,
        'delivery_instructions': deliveryInstructions,
        'photo_ids': photoIds,
      };
      final response =
          await _client.post(ApiEndpoints.customerParcels, data: body);

      if ([200, 201].contains(response.statusCode)) {
        final parcel = Parcel.fromJson(_dataMap(response));
        appLogger.i(
          'ParcelRepository.createParcel → success, id=${parcel.id}',
        );
        return Right(parcel);
      }

      appLogger.w(
        'ParcelRepository.createParcel → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('ParcelRepository.createParcel → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'ParcelRepository',
        methodName: 'createParcel',
      );
    }
  }

  ResultFuture<Parcel> cancelParcel({
    required String id,
    required String reason,
  }) async {
    appLogger.d('ParcelRepository.cancelParcel → id=$id');
    try {
      final response = await _client.patch(
        ApiEndpoints.customerParcelCancel(id),
        data: {'reason': reason},
      );

      if ([200, 201].contains(response.statusCode)) {
        final parcel = Parcel.fromJson(_dataMap(response));
        appLogger.i('ParcelRepository.cancelParcel → success, id=$id');
        return Right(parcel);
      }

      appLogger.w(
        'ParcelRepository.cancelParcel → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('ParcelRepository.cancelParcel → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'ParcelRepository',
        methodName: 'cancelParcel',
      );
    }
  }

  // ─── Quotes ──────────────────────────────────────────────────────────────

  ResultFuture<ParcelQuote> getParcelQuote({
    required String pickupAddress,
    required double pickupLatitude,
    required double pickupLongitude,
    required String dropoffAddress,
    required double dropoffLatitude,
    required double dropoffLongitude,
    required String size,
    bool? isFragile,
  }) async {
    appLogger.d('ParcelRepository.getParcelQuote → initiated');
    try {
      final body = {
        'pickup_address': pickupAddress,
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'dropoff_address': dropoffAddress,
        'dropoff_latitude': dropoffLatitude,
        'dropoff_longitude': dropoffLongitude,
        'size': size,
        'is_fragile': isFragile,
      };
      final response =
          await _client.post(ApiEndpoints.customerParcelQuotes, data: body);

      if ([200, 201].contains(response.statusCode)) {
        final quote = ParcelQuote.fromJson(_dataMap(response));
        appLogger.i('ParcelRepository.getParcelQuote → success');
        return Right(quote);
      }

      appLogger.w(
        'ParcelRepository.getParcelQuote → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'ParcelRepository.getParcelQuote → DioException',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'ParcelRepository',
        methodName: 'getParcelQuote',
      );
    }
  }

  // ─── Photos ──────────────────────────────────────────────────────────────

  ResultFuture<ParcelPhoto> uploadParcelPhoto({
    required String filePath,
  }) async {
    appLogger.d('ParcelRepository.uploadParcelPhoto → initiated');
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(filePath),
      });
      final response = await _client.post(
        ApiEndpoints.customerParcelPhotos,
        data: formData,
      );

      if ([200, 201].contains(response.statusCode)) {
        final photo = ParcelPhoto.fromJson(_dataMap(response));
        appLogger.i(
          'ParcelRepository.uploadParcelPhoto → success, id=${photo.id}',
        );
        return Right(photo);
      }

      appLogger.w(
        'ParcelRepository.uploadParcelPhoto → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'ParcelRepository.uploadParcelPhoto → DioException',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'ParcelRepository',
        methodName: 'uploadParcelPhoto',
      );
    }
  }

  ResultFuture<bool> deleteParcelPhoto({required String photoId}) async {
    appLogger.d('ParcelRepository.deleteParcelPhoto → id=$photoId');
    try {
      final response = await _client
          .delete(ApiEndpoints.customerParcelPhotoById(photoId));

      if ([200, 204].contains(response.statusCode)) {
        appLogger.i(
          'ParcelRepository.deleteParcelPhoto → success, id=$photoId',
        );
        return const Right(true);
      }

      appLogger.w(
        'ParcelRepository.deleteParcelPhoto → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'ParcelRepository.deleteParcelPhoto → DioException',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'ParcelRepository',
        methodName: 'deleteParcelPhoto',
      );
    }
  }

  // ─── Private Helpers ───────────────────────────────────────────────────────

  DataMap _dataMap(Response response) {
    final body = response.data;
    if (body is DataMap) {
      final d = body['data'];
      if (d is DataMap) return d;
      return body;
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
}
