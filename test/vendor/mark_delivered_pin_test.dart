import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/utils/network_utility.dart';
import 'package:bagyesrushappusernew/src/vendor/model/vendor_order.dart';
import 'package:bagyesrushappusernew/src/vendor/repository/vendor_dashboard_repository_impl.dart';
import 'package:bagyesrushappusernew/src/vendor/viewmodel/orders_viewmodel.dart';

import '../core/support/auth_test_support.dart';

const _path = 'PATCH /vendor/me/orders/7/delivered';

Map<String, dynamic> _orderJson(String status) => {
      'id': 7,
      'order_number': 'BR-7',
      'status': status,
      'customer': {'name': 'Ama'},
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScriptedAdapter adapter;
  late OrdersViewModel orders;

  void setUpOrders((int, Object) Function() deliveredResponse) {
    adapter = ScriptedAdapter((o) {
      if ('${o.method} ${o.path}' == _path) return deliveredResponse();
      return (404, {'message': 'unexpected ${o.method} ${o.path}'});
    });
    orders = OrdersViewModel(
      VendorDashboardRepositoryImpl(NetworkUtility(scriptedDio(adapter))),
      CurrentUserProvider(),
    )..upsertOrder(VendorOrder.fromJson(_orderJson('out_for_delivery')));
  }

  OrderStatus statusOnScreen() => orders.state.orders.single.status;

  test('sends the PIN as a string so a leading zero survives', () async {
    setUpOrders(() => (200, {'data': _orderJson('delivered')}));

    await orders.markDelivered('7', deliveryPin: '0472');

    expect(adapter.requests.single.data, {'delivery_pin': '0472'});
  });

  test('a wrong PIN returns the server message and leaves the order undelivered',
      () async {
    setUpOrders(() => (422, {'message': 'Incorrect delivery PIN.'}));

    final error = await orders.markDelivered('7', deliveryPin: '1111');

    expect(error, 'Incorrect delivery PIN.');
    expect(statusOnScreen(), OrderStatus.outForDelivery);
  });

  test('a lockout from too many attempts is surfaced, not treated as success',
      () async {
    setUpOrders(() => (429, {'message': 'Too many attempts. Try later.'}));

    final error = await orders.markDelivered('7', deliveryPin: '2222');

    expect(error, 'Too many attempts. Try later.');
    expect(statusOnScreen(), OrderStatus.outForDelivery);
  });

  test('the correct PIN marks the order delivered', () async {
    setUpOrders(() => (200, {'data': _orderJson('delivered')}));

    final error = await orders.markDelivered('7', deliveryPin: '0472');

    expect(error, isNull);
    expect(statusOnScreen(), OrderStatus.delivered);
  });
}
