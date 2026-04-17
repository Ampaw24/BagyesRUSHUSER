import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../constant/config.dart';

// ── Data classes ──────────────────────────────────────────────────────────────

class PlacePrediction {
  final String placeId;
  final String description;

  const PlacePrediction({required this.placeId, required this.description});
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

  // Default bias: central Accra
  static const _defaultBias = LatLng(5.6037, -0.1870);

  /// Returns up to 5 autocomplete predictions for [input].
  /// Biased toward [locationBias] (defaults to Accra) with a 50 km radius.
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
          'components': 'country:gh',
          'location': '${bias.latitude},${bias.longitude}',
          'radius': '50000',
          'language': 'en',
        },
      );

      final data = response.data;
      if (data == null || data['status'] != 'OK') return [];

      final predictions = data['predictions'] as List<dynamic>;
      return predictions.take(5).map((p) {
        return PlacePrediction(
          placeId: p['place_id'] as String,
          description: p['description'] as String,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetches the [LatLng] for a given [placeId].
  /// Returns `null` if the lookup fails.
  static Future<LatLng?> fetchPlaceLatLng(String placeId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _detailsUrl,
        queryParameters: {
          'place_id': placeId,
          'fields': 'geometry',
          'key': Config.mapsApiKey,
        },
      );

      final data = response.data;
      if (data == null || data['status'] != 'OK') return null;

      final location =
          data['result']['geometry']['location'] as Map<String, dynamic>;
      return LatLng(
        (location['lat'] as num).toDouble(),
        (location['lng'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}
