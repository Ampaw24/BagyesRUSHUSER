import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';

void main() {
  ConsumerOrder parse(Map<String, dynamic> extra) =>
      ConsumerOrder.fromJson({'id': 31, 'status': 'delivered', ...extra});

  group('parcel detection', () {
    test('a food order with a vendor stays a food order', () {
      final order = parse({
        'vendor': {'id': 4, 'name': 'KFC'},
        'items': [
          {'menu_item_id': 1, 'name': 'Zinger', 'quantity': 1},
        ],
      });
      expect(order.isParcel, isFalse);
    });

    test('an explicit parcel type flag marks a parcel', () {
      expect(parse({'order_type': 'parcel'}).isParcel, isTrue);
      expect(parse({'type': 'parcel_delivery'}).isParcel, isTrue);
    });

    test('a direction marks a parcel and keeps its value', () {
      final order = parse({'direction': 'receive'});
      expect(order.isParcel, isTrue);
      expect(order.isReceiveParcel, isTrue);
    });

    test('vendorless stops mark a parcel and are parsed', () {
      final order = parse({
        'pickup_address': 'Osu, Accra',
        'stops': [
          {
            'address': 'East Legon',
            'recipient_name': 'Ama',
            'size': 'small',
            'is_fragile': true,
          },
        ],
      });
      expect(order.isParcel, isTrue);
      expect(order.parcelDirection, 'send');
      expect(order.pickupAddress, 'Osu, Accra');
      expect(order.stops.single.recipientName, 'Ama');
    });

    test('a vendorless order with no items is a parcel', () {
      expect(parse({'items': [], 'total': 63.89}).isParcel, isTrue);
    });

    test('a slim track payload without items is not marked a parcel', () {
      expect(parse({'payment_status': 'paid'}).isParcel, isFalse);
    });

    test('status timestamps are read from a timeline and flat keys', () {
      final order = parse({
        'type': 'parcel',
        'timeline': [
          {'status': 'picked_up', 'at': '2026-10-07T10:15:00Z'},
        ],
        'delivered_at': '2026-10-07T10:40:00Z',
      });
      expect(order.statusTimes.keys,
          containsAll([OrderStatus.pickedUp, OrderStatus.delivered]));
    });
  });
}
