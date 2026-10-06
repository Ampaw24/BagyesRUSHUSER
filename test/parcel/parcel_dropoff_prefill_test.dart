import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:bagyesrushappusernew/core/utils/location_helper.dart';
import 'package:bagyesrushappusernew/src/parcel/model/parcel_direction.dart';
import 'package:bagyesrushappusernew/src/parcel/repository/parcel_repository.dart';
import 'package:bagyesrushappusernew/src/parcel/viewmodel/send_parcel_viewmodel.dart';

class _Repository extends Fake implements ParcelRepository {}

LocationResult _fix() => LocationResult(
      status: LocationStatus.success,
      position: Position(
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
      ),
      address: 'Osu, Accra',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var acquisitions = 0;

  setUp(() {
    acquisitions = 0;
    LocationHelper.cachedResult = null;
    // Answers immediately: a real-time delay here would race the fixed
    // number of event-queue turns the tests pump.
    LocationHelper.acquire = (_) async {
      acquisitions++;
      return _fix();
    };
  });

  tearDown(() => LocationHelper.cachedResult = null);

  SendParcelViewModel build(ParcelDirection direction) {
    final vm = SendParcelViewModel(_Repository(), direction: direction);
    addTearDown(vm.dispose);
    return vm;
  }

  test('a receive drop-off with no cached fix gets the current location',
      () async {
    final vm = build(ParcelDirection.receive);
    expect(vm.state.deliveryStops.single.hasLocation, isFalse);

    await pumpEventQueue(times: 40);

    final stop = vm.state.deliveryStops.single;
    expect(stop.address, 'Osu, Accra');
    expect(stop.latLng, const LatLng(5.6, -0.19));
  });

  test('a cached fix is used without acquiring another', () async {
    LocationHelper.cachedResult = _fix();

    final vm = build(ParcelDirection.receive);
    await pumpEventQueue(times: 40);

    expect(acquisitions, 0);
    expect(vm.state.deliveryStops.single.address, 'Osu, Accra');
  });

  test('a stop the customer picked meanwhile is not overwritten', () async {
    final vm = build(ParcelDirection.receive);
    vm.updateDeliveryStop(
      vm.state.deliveryStops.single.id,
      const LatLng(6.0, -1.0),
      'East Legon',
    );

    await pumpEventQueue(times: 40);

    expect(vm.state.deliveryStops.single.address, 'East Legon');
  });

  test('sending a parcel never asks for the location', () async {
    final vm = build(ParcelDirection.send);

    await pumpEventQueue(times: 40);

    expect(acquisitions, 0);
    expect(vm.state.deliveryStops.single.hasLocation, isFalse);
  });
}
