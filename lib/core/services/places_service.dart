import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
/// returned by the Places API (New) place-details call.
class PlaceDetail {
  final LatLng latLng;
  final String formattedAddress;

  const PlaceDetail({required this.latLng, required this.formattedAddress});
}

// ── Service ───────────────────────────────────────────────────────────────────

class PlacesService {
  PlacesService._();

  static Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  @visibleForTesting
  static set httpClient(Dio dio) => _dio = dio;

  // Places API (New). The legacy `/maps/api/place/*` endpoints can't be
  // enabled on newer Google Cloud projects. Geocoding is not part of that
  // deprecation and keeps its own endpoint.
  static const _autocompleteUrl = 'https://places.googleapis.com/v1/places:autocomplete';
  static const _detailsUrl = 'https://places.googleapis.com/v1/places';
  static const _geocodeUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

  // Default location bias: central Accra
  static const _defaultBias =
      LatLng(Config.defaultMapCenterLat, Config.defaultMapCenterLng);

  /// Logs a failed call with Google's own error message (e.g. API not
  /// enabled, key restricted) rather than only the HTTP status.
  static void _logHttpError(String call, DioException e, StackTrace s) {
    final body = e.response?.data;
    String? detail;
    if (body is Map && body['error'] is Map) {
      detail = (body['error'] as Map)['message']?.toString();
    }
    appLogger.e(
      '[Places] $call network error${detail == null ? '' : ' — $detail'}',
      error: e,
      stackTrace: s,
    );
  }

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
      final response = await _dio.post<Map<String, dynamic>>(
        _autocompleteUrl,
        options: Options(headers: {'X-Goog-Api-Key': Config.mapsApiKey}),
        data: {
          'input': input,
          'languageCode': 'en',
          // Soft bias — prefers nearby but does NOT exclude other regions
          // (no included-type or region filter, so streets, areas and
          // landmarks all appear). 50 km is the API's maximum radius.
          'locationBias': {
            'circle': {
              'center': {
                'latitude': bias.latitude,
                'longitude': bias.longitude,
              },
              'radius': 50000.0,
            },
          },
        },
      );

      final data = response.data;
      if (data == null) {
        appLogger.w('[Places] autocomplete: null response body');
        return [];
      }

      // An empty result is `{}` — no `suggestions` key — not an error.
      final suggestions = data['suggestions'] as List<dynamic>? ?? const [];
      return suggestions
          .map((s) => (s as Map<String, dynamic>)['placePrediction'])
          .whereType<Map<String, dynamic>>()
          .take(7)
          .map((p) => PlacePrediction(
                placeId: p['placeId'] as String,
                description: (p['text'] as Map<String, dynamic>)['text'] as String,
              ))
          .toList();
    } on DioException catch (e, s) {
      _logHttpError('autocomplete', e, s);
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
        '$_detailsUrl/$placeId',
        queryParameters: {'languageCode': 'en'},
        options: Options(headers: {
          'X-Goog-Api-Key': Config.mapsApiKey,
          // Only the fields we use — the field mask also sets the billing SKU.
          'X-Goog-FieldMask': 'location,formattedAddress,displayName',
        }),
      );

      final data = response.data;
      if (data == null) {
        appLogger.w('[Places] fetchPlaceDetail: null response body');
        return null;
      }

      final location = data['location'] as Map<String, dynamic>?;
      if (location == null) {
        appLogger.w('[Places] fetchPlaceDetail: no location in response');
        return null;
      }

      final latLng = LatLng(
        (location['latitude'] as num).toDouble(),
        (location['longitude'] as num).toDouble(),
      );

      // Prefer the full formatted address; fall back to the place name.
      final formattedAddress =
          (data['formattedAddress'] as String?)?.trim() ??
          ((data['displayName'] as Map<String, dynamic>?)?['text'] as String?)
              ?.trim() ??
          '';

      return PlaceDetail(latLng: latLng, formattedAddress: formattedAddress);
    } on DioException catch (e, s) {
      _logHttpError('fetchPlaceDetail', e, s);
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

      // Google returns several candidate results per coordinate. In areas
      // with thin premise-level coverage (common outside Accra's main
      // roads), the top result is often a Plus Code — e.g. "MP4W+FXJ
      // Directly opposite the Taifa Mosque" — which reads badly as a
      // delivery address. Prefer the first result that isn't plus-code-only,
      // falling back to the plus code only when nothing better exists.
      final best = results.cast<Map<String, dynamic>>().firstWhere(
            (r) => !(r['types'] as List<dynamic>? ?? [])
                .cast<String>()
                .contains('plus_code'),
            orElse: () => results.first as Map<String, dynamic>,
          );

      final formattedAddress = (best['formatted_address'] as String?)?.trim();
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
