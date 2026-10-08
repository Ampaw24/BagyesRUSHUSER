import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:bagyesrushappusernew/core/errors/failure.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/parcel/model/parcel_direction.dart';
import 'package:bagyesrushappusernew/src/parcel/model/parcel_quote.dart';
import 'package:bagyesrushappusernew/src/parcel/model/parcel_stop.dart';
import 'package:bagyesrushappusernew/src/parcel/repository/parcel_repository.dart';
import 'package:bagyesrushappusernew/src/parcel/viewmodel/send_parcel_viewmodel.dart';

/// Answers quote requests with whatever [answer] is set to.
class _Repository extends Fake implements ParcelRepository {
  Either<Failure, List<ParcelQuote>> answer = Right([_quote()]);
  Future<void>? hold;
  int quoteRequests = 0;

  @override
  ResultFuture<List<ParcelQuote>> getParcelQuotes({
    required String pickupAddress,
    required double pickupLatitude,
    required double pickupLongitude,
    required List<ParcelStop> stops,
  }) async {
    quoteRequests++;
    await hold;
    return answer;
  }
}

ParcelQuote _quote() => ParcelQuote.fromJson({
      'delivery_quote_id': 1,
      'fee': 28,
      'total': 30.4,
      'currency': 'GHS',
      'rider': {'id': 31, 'name': 'Kofi O.'},
    });

Failure _refusal(String message, {int status = 422}) =>
    ServerFailure(message: message, statusCode: status, title: 'Error');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Repository repo;
  late SendParcelViewModel vm;

  /// A complete send-parcel booking, parked on the delivery step.
  Future<void> reachDeliveryStep() async {
    vm.selectPackageType('parcel');
    await vm.advance();
    vm.setWeight('2');
    await vm.advance();
    vm.setPickupLocation(const LatLng(5.6, -0.19), 'Osu, Accra');
    await vm.advance();
    final id = vm.state.deliveryStops.single.id;
    vm.updateDeliveryStop(id, const LatLng(5.7, -0.2), 'Madina, Accra');
    vm.updateDeliveryStopDetails(
      id,
      itemDescription: 'Documents',
      quantity: 1,
      recipientName: 'Ama',
      recipientPhone: '0241234567',
      specialInstructions: '',
      selectedImageIndices: const [],
    );
    expect(vm.state.currentStep, ParcelStep.deliveryLocation);
  }

  setUp(() {
    repo = _Repository();
    vm = SendParcelViewModel(repo, direction: ParcelDirection.send);
    addTearDown(vm.dispose);
  });

  test('a successful quote opens the rider list', () async {
    await reachDeliveryStep();

    await vm.advance();

    expect(vm.state.currentStep, ParcelStep.availableRiders);
    expect(vm.state.riderQuotes, hasLength(1));
    expect(vm.state.quoteBlockedMessage, isNull);
    expect(repo.quoteRequests, 1, reason: 'the list opens already loaded');
  });

  test('the server\'s refusal is shown as-is and the customer stays on the delivery step',
      () async {
    await reachDeliveryStep();
    repo.answer = Left(_refusal('We don\'t deliver to Madina yet.'));

    await vm.advance();

    expect(vm.state.currentStep, ParcelStep.deliveryLocation);
    expect(vm.state.quoteBlockedMessage, 'We don\'t deliver to Madina yet.');
    expect(vm.state.isFetchingQuote, isFalse);
  });

  test('no riders available also stays put, with a message', () async {
    await reachDeliveryStep();
    repo.answer = const Right([]);

    await vm.advance();

    expect(vm.state.currentStep, ParcelStep.deliveryLocation);
    expect(vm.state.quoteBlockedMessage, contains('No riders are available'));
  });

  test('no connection stays put with the connectivity message', () async {
    await reachDeliveryStep();
    repo.answer = Left(_refusal('No internet connection.', status: 499));

    await vm.advance();

    expect(vm.state.currentStep, ParcelStep.deliveryLocation);
    expect(vm.state.quoteBlockedMessage, 'No internet connection.');
  });

  test('editing the stop clears the message, and a corrected address goes through',
      () async {
    await reachDeliveryStep();
    repo.answer = Left(_refusal('We don\'t deliver to Madina yet.'));
    await vm.advance();
    expect(vm.state.quoteBlockedMessage, isNotNull);

    vm.updateDeliveryStop(
      vm.state.deliveryStops.single.id,
      const LatLng(5.55, -0.2),
      'Osu, Accra',
    );
    expect(vm.state.quoteBlockedMessage, isNull);

    repo.answer = Right([_quote()]);
    await vm.advance();

    expect(vm.state.currentStep, ParcelStep.availableRiders);
  });

  test('Continue is locked while the quote loads, so it can\'t be sent twice',
      () async {
    await reachDeliveryStep();
    final release = Future<void>.delayed(const Duration(milliseconds: 20));
    repo.hold = release;

    final first = vm.advance();
    expect(vm.state.canProceed, isFalse);
    await vm.advance(); // ignored
    await first;

    expect(repo.quoteRequests, 1);
    expect(vm.state.currentStep, ParcelStep.availableRiders);
  });

  test('going back while the quote loads leaves them on the earlier step',
      () async {
    await reachDeliveryStep();
    repo.hold = Future<void>.delayed(const Duration(milliseconds: 20));

    final pending = vm.advance();
    vm.goBack();
    await pending;

    expect(vm.state.currentStep, ParcelStep.pickupLocation);
  });

  test('going back clears the message', () async {
    await reachDeliveryStep();
    repo.answer = Left(_refusal('Nope.'));
    await vm.advance();

    vm.goBack();

    expect(vm.state.quoteBlockedMessage, isNull);
  });
}
