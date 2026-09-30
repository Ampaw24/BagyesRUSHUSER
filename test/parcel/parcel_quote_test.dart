import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/src/parcel/model/parcel_quote.dart';

void main() {
  test('ParcelQuote charges the total and keeps the fee breakdown', () {
    final quote = ParcelQuote.fromJson({
      'delivery_quote_id': 5141,
      'fee': 28,
      'service_fee': 2.4,
      'total': 30.4,
      'currency': 'GHS',
      'eta_minutes': 18,
      'distance_km': 6.4,
      'expires_at': '2026-09-26T09:17:44.000000Z',
      'rider': {
        'id': 31,
        'name': 'Kofi O.',
        'photo_url': 'https://api.bagyesrushdelivery.com/api/v1/media/riders/kofi.jpg',
        'rating': 4.8,
        'review_count': 132,
        'deliveries_completed': 486,
        'vehicle_type_id': 1,
        'vehicle_type': 'motorbike',
        'vehicle_type_label': 'Motorbike',
        'distance_away_km': 1.1,
      },
    });

    expect(quote.id, 5141);
    expect(quote.price, 30.4);
    expect(quote.deliveryFee, 28);
    expect(quote.serviceFee, 2.4);
    expect(quote.etaMinutes, 18);
    expect(quote.rider?.id, '31');
    expect(quote.rider?.photoUrl, contains('kofi.jpg'));
    expect(quote.rider?.rating, 4.8);
    expect(quote.rider?.reviewCount, 132);
    expect(quote.rider?.deliveriesCompleted, 486);
    expect(quote.rider?.vehicleTypeLabel, 'Motorbike');
    expect(quote.rider?.distanceAwayKm, 1.1);
  });
}
