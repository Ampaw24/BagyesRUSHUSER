import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../constant/config.dart';
import '../utils/app_logger.dart';

// ── Data classes ──────────────────────────────────────────────────────────────

class PlacePrediction {
  final String placeId;
  final String description;

  const PlacePrediction({required this.placeId, required this.description});
}

/// Holds both the resolved coordinates and the human-readable address
/// returned by the Places Details API.
class PlaceDetail {
  final LatLng latLng;
  final String formattedAddress;

  const PlaceDetail({required this.latLng, required this.formattedAddress});
}

// ── Service ───────────────────────────────────────────────────────────────────

class PlacesService {
  PlacesService._();

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  static const _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';
  static const _geocodeUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

  // Default location bias: central Accra
  static const _defaultBias =
      LatLng(Config.defaultMapCenterLat, Config.defaultMapCenterLng);

  /// Returns up to 7 autocomplete predictions for [input].
  ///
  /// Uses a soft location bias (not a hard country filter) so that all
  /// place types — streets, neighbourhoods, landmarks, cities — are returned
  /// worldwide while still preferring results near [locationBias].
  static Future<List<PlacePrediction>> autocomplete(
    String input, {
    LatLng? locationBias,
  }) async {
    if (input.trim().isEmpty) return [];
    final bias = locationBias ?? _defaultBias;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _autocompleteUrl,
        queryParameters: {
          'input': input,
          'key': Config.mapsApiKey,
          // Soft bias — prefers nearby but does NOT exclude other regions.
          'location': '${bias.latitude},${bias.longitude}',
          'radius': '100000',
          'language': 'en',
          // No 'components' filter so streets, areas and landmarks all appear.
        },
      );

      final data = response.data;
      if (data == null) {
        appLogger.w('[Places] autocomplete: null response body');
        return [];
      }

      final status = data['status'] as String?;
      if (status != 'OK') {
        appLogger.w(
          '[Places] autocomplete status: $status '
          '— error: ${data['error_message'] ?? 'none'}',
        );
        return [];
      }

      final predictions = data['predictions'] as List<dynamic>;
      return predictions.take(7).map((p) {
        return PlacePrediction(
          placeId: p['place_id'] as String,
          description: p['description'] as String,
        );
      }).toList();
    } on DioException catch (e, s) {
      appLogger.e('[Places] autocomplete network error', error: e, stackTrace: s);
      return [];
    } catch (e, s) {
      appLogger.e('[Places] autocomplete unexpected error', error: e, stackTrace: s);
      return [];
    }
  }

  /// Fetches the full [PlaceDetail] (coordinates + formatted address) for a
  /// given [placeId].  Returns `null` if the lookup fails.
  static Future<PlaceDetail?> fetchPlaceDetail(String placeId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _detailsUrl,
        queryParameters: {
          'place_id': placeId,
          // Request geometry, the formatted address and the display name so
          // we can show a rich, accurate address without relying on reverse
          // geocoding after the user selects a suggestion.
          'fields': 'geometry,formatted_address,name',
          'key': Config.mapsApiKey,
          'language': 'en',
        },
      );

      final data = response.data;
      if (data == null) {
        appLogger.w('[Places] fetchPlaceDetail: null response body');
        return null;
      }

      final status = data['status'] as String?;
      if (status != 'OK') {
        appLogger.w(
          '[Places] fetchPlaceDetail status: $status '
          '— error: ${data['error_message'] ?? 'none'}',
        );
        return null;
      }

      final result = data['result'] as Map<String, dynamic>;
      final location =
          result['geometry']['location'] as Map<String, dynamic>;

      final latLng = LatLng(
        (location['lat'] as num).toDouble(),
        (location['lng'] as num).toDouble(),
      );

      // Prefer the full formatted address; fall back to the place name.
      final formattedAddress =
          (result['formatted_address'] as String?)?.trim() ??
          (result['name'] as String?)?.trim() ??
          '';

      return PlaceDetail(latLng: latLng, formattedAddress: formattedAddress);
    } on DioException catch (e, s) {
      appLogger.e('[Places] fetchPlaceDetail network error', error: e, stackTrace: s);
      return null;
    } catch (e, s) {
      appLogger.e('[Places] fetchPlaceDetail unexpected error', error: e, stackTrace: s);
      return null;
    }
  }

  /// Kept for backward compatibility — prefer [fetchPlaceDetail].
  static Future<LatLng?> fetchPlaceLatLng(String placeId) async {
    final detail = await fetchPlaceDetail(placeId);
    return detail?.latLng;
  }

  /// Reverse-geocodes [latitude]/[longitude] via the Google Geocoding API —
  /// unlike the native `geocoding` package (used elsewhere in the app), this
  /// hits Google's own service directly, which tends to have denser address
  /// coverage than the platform geocoders in some regions.
  ///
  /// Returns Google's `formatted_address` for the closest result, or `null`
  /// on any failure (network error, non-OK status, or zero results).
  static Future<String?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _geocodeUrl,
        queryParameters: {
          'latlng': '$latitude,$longitude',
          'key': Config.mapsApiKey,
          'language': 'en',
        },
      );

      final data = response.data;
      if (data == null) {
        appLogger.w('[Places] reverseGeocode: null response body');
        return null;
      }

      final status = data['status'] as String?;
      if (status != 'OK') {
        appLogger.w(
          '[Places] reverseGeocode status: $status '
          '— error: ${data['error_message'] ?? 'none'}',
        );
        return null;
      }

      final results = data['results'] as List<dynamic>;
      if (results.isEmpty) return null;

      final formattedAddress =
          ((results.first as Map<String, dynamic>)['formatted_address']
                  as String?)
              ?.trim();
      return (formattedAddress != null && formattedAddress.isNotEmpty)
          ? formattedAddress
          : null;
    } on DioException catch (e, s) {
      appLogger.e('[Places] reverseGeocode network error', error: e, stackTrace: s);
      return null;
    } catch (e, s) {
      appLogger.e('[Places] reverseGeocode unexpected error', error: e, stackTrace: s);
      return null;
    }
  }
}
