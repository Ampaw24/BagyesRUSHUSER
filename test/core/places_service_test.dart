import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:bagyesrushappusernew/core/services/places_service.dart';

import 'support/auth_test_support.dart';

void main() {
  late ScriptedAdapter adapter;

  void serve((int, Object) Function(String method, String path) answer) {
    adapter = ScriptedAdapter((o) => answer(o.method, o.uri.toString()));
    PlacesService.httpClient = scriptedDio(adapter);
  }

  group('autocomplete (Places API New)', () {
    test('POSTs the input with a 50 km location bias and parses suggestions', () async {
      serve((_, _) => (
            200,
            {
              'suggestions': [
                {
                  'placePrediction': {
                    'placeId': 'abc',
                    'text': {'text': 'Osu, Accra, Ghana'},
                  },
                },
                // Query suggestions have no placePrediction and are skipped.
                {'queryPrediction': {}},
              ],
            },
          ));

      final results = await PlacesService.autocomplete(
        'osu',
        locationBias: const LatLng(5.6, -0.2),
      );

      expect(results.map((p) => p.placeId), ['abc']);
      expect(results.single.description, 'Osu, Accra, Ghana');

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.toString(), 'https://places.googleapis.com/v1/places:autocomplete');
      expect(request.headers.containsKey('X-Goog-Api-Key'), isTrue);
      final body = request.data as Map<String, dynamic>;
      expect(body['input'], 'osu');
      expect(body['locationBias']['circle']['radius'], 50000.0);
      expect(body['locationBias']['circle']['center'], {'latitude': 5.6, 'longitude': -0.2});
    });

    test('no matches (an empty object) is an empty list', () async {
      serve((_, _) => (200, <String, dynamic>{}));

      expect(await PlacesService.autocomplete('zzzz'), isEmpty);
    });

    test('a denied or failed request is an empty list, not a throw', () async {
      serve((_, _) => (403, {'error': {'message': 'API key not valid'}}));

      expect(await PlacesService.autocomplete('osu'), isEmpty);
    });

    test('blank input makes no request', () async {
      serve((_, _) => (200, <String, dynamic>{}));

      expect(await PlacesService.autocomplete('   '), isEmpty);
      expect(adapter.requests, isEmpty);
    });
  });

  group('fetchPlaceDetail (Places API New)', () {
    test('GETs the place with a field mask and parses location + address', () async {
      serve((_, _) => (
            200,
            {
              'location': {'latitude': 5.55, 'longitude': -0.18},
              'formattedAddress': '12 Oxford St, Osu, Accra, Ghana',
              'displayName': {'text': 'Oxford Street'},
            },
          ));

      final detail = await PlacesService.fetchPlaceDetail('abc');

      expect(detail!.latLng, const LatLng(5.55, -0.18));
      expect(detail.formattedAddress, '12 Oxford St, Osu, Accra, Ghana');

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.path, '/v1/places/abc');
      expect(request.headers['X-Goog-FieldMask'], 'location,formattedAddress,displayName');
    });

    test('falls back to the place name when there is no formatted address', () async {
      serve((_, _) => (
            200,
            {
              'location': {'latitude': 1.0, 'longitude': 2.0},
              'displayName': {'text': 'Taifa Mosque'},
            },
          ));

      expect((await PlacesService.fetchPlaceDetail('abc'))!.formattedAddress, 'Taifa Mosque');
    });

    test('a failure or a response without a location is null', () async {
      serve((_, _) => (404, {'error': {'message': 'not found'}}));
      expect(await PlacesService.fetchPlaceDetail('abc'), isNull);

      serve((_, _) => (200, {'formattedAddress': 'x'}));
      expect(await PlacesService.fetchPlaceDetail('abc'), isNull);
    });
  });
}
