import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:bagyesrushappusernew/core/utils/location_helper.dart';

Position _position() => Position(
      longitude: -0.19,
      latitude: 5.6,
      timestamp: DateTime(2026),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

LocationResult _success([String address = 'Osu, Accra']) => LocationResult(
      status: LocationStatus.success,
      position: _position(),
      address: address,
    );

const _failure = LocationResult(
  status: LocationStatus.permissionDenied,
  position: null,
  address: 'Location unavailable',
);

void main() {
  var acquisitions = 0;

  Future<LocationResult> Function(Duration) fake(
    FutureOr<LocationResult> Function() result,
  ) =>
      (_) async {
        acquisitions++;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return result();
      };

  setUp(() {
    acquisitions = 0;
    LocationHelper.cachedResult = null;
  });

  tearDown(() => LocationHelper.cachedResult = null);

  test('concurrent callers share one acquisition', () async {
    LocationHelper.acquire = fake(_success);

    final results = await Future.wait([
      LocationHelper.current(),
      LocationHelper.current(),
      LocationHelper.current(),
    ]);

    expect(acquisitions, 1);
    expect(results.map((r) => r.address), everyElement('Osu, Accra'));
  });

  test('a successful fix is cached, so later callers do not re-acquire',
      () async {
    LocationHelper.acquire = fake(_success);

    await LocationHelper.current();
    final again = await LocationHelper.current();

    expect(acquisitions, 1);
    expect(again.address, 'Osu, Accra');
    expect(LocationHelper.cachedResult?.isSuccess, isTrue);
  });

  test('a failed attempt is not cached — the next caller retries', () async {
    LocationHelper.acquire = fake(() => _failure);
    final first = await LocationHelper.current();
    expect(first.isSuccess, isFalse);
    expect(LocationHelper.cachedResult, isNull);

    LocationHelper.acquire = fake(_success);
    final second = await LocationHelper.current();

    expect(second.isSuccess, isTrue);
    expect(acquisitions, 2);
  });
}
