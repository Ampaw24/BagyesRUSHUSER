import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/src/cart/models/cart_model.dart';

CartModel _cart(Map<String, dynamic> totals) =>
    CartModel.fromJson({'vendor_id': 'v1', 'items': [], 'totals': totals});

void main() {
  group('CartModel.estimatedTotalWith', () {
    test('swaps in the quoted fee using the backend identity', () {
      final cart = _cart({
        'subtotal': 174.0,
        'discount': 10.0,
        'delivery_fee': 8.0,
        'service_fee': 8.7,
        'total': 180.7,
      });
      expect(cart.estimatedTotalWith(8.0), cart.total);
      expect(cart.estimatedTotalWith(12.5), 185.2);
    });

    test('treats a missing discount and service fee as zero', () {
      final cart = _cart({'subtotal': 30.4});
      expect(cart.estimatedTotalWith(7.15), 37.55);
    });

    test('is null until the subtotal is known', () {
      expect(_cart({}).estimatedTotalWith(8.0), isNull);
    });
  });
}
