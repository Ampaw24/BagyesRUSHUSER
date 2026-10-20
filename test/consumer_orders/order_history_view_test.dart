import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:gopady/core/common/app/current_user_provider.dart';
import 'package:gopady/core/router/app_routes.dart';
import 'package:gopady/src/consumer_orders/repositories/consumer_orders_repository.dart';
import 'package:gopady/src/consumer_orders/viewmodels/orders_viewmodel.dart';
import 'package:gopady/src/consumer_orders/views/order_history_view.dart';

import '../core/support/auth_test_support.dart';
import 'support/order_test_support.dart';

Map<String, dynamic> _order(
  int id,
  String status,
  String createdAt, {
  String vendor = 'Auntie Muni',
}) => {
  ...fullOrder(status: status),
  'id': id,
  'vendor': {'id': 7, 'name': vendor, 'logo_url': ''},
  'created_at': createdAt,
};

(int, Object) _page(List<Map<String, dynamic>> orders) => (
  200,
  {
    'data': orders,
    'meta': {'current_page': 1, 'last_page': 1, 'total': orders.length},
  },
);

Future<void> _pumpHistory(
  WidgetTester tester,
  ScriptedAdapter adapter,
) async {
  final orders = OrdersViewModel(
    ConsumerOrdersRepository(client: Dio()..httpClientAdapter = adapter),
    FakeRealtime(),
    CurrentUserProvider(),
  );
  addTearDown(() async {
    await pumpEventQueue();
    orders.dispose();
  });

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const OrderHistoryView()),
      GoRoute(
        path: AppRoutes.trackOrder,
        builder: (_, state) => Text('tracking ${state.extra}'),
      ),
    ],
  );
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: orders,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await _settle(tester);
}

/// The scripted server answers after a short delay on the test clock.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump();
}

void main() {
  testWidgets('lists only finished orders, grouped under their month', (
    tester,
  ) async {
    await _pumpHistory(
      tester,
      ScriptedAdapter(
        (_) => _page([
          _order(1, 'preparing', '2026-09-20T12:00:00Z', vendor: 'Live Order'),
          _order(2, 'delivered', '2026-09-15T12:00:00Z', vendor: 'Auntie Muni'),
          _order(3, 'cancelled', '2026-08-15T12:00:00Z', vendor: 'Kofi Grill'),
        ]),
      ),
    );

    expect(find.text('Order History'), findsOneWidget);
    expect(find.text('Live Order'), findsNothing);
    expect(find.text('Auntie Muni'), findsOneWidget);
    expect(find.text('Kofi Grill'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('GHS 60.00'), findsNWidgets(2));
    expect(find.text('Sep 2026'), findsOneWidget);
    expect(find.text('Aug 2026'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Sep 2026')).dy,
      lessThan(tester.getTopLeft(find.text('Aug 2026')).dy),
    );
  });

  testWidgets('shows an empty state when nothing has finished yet', (
    tester,
  ) async {
    await _pumpHistory(
      tester,
      ScriptedAdapter(
        (_) => _page([_order(1, 'preparing', '2026-09-20T12:00:00Z')]),
      ),
    );

    expect(find.text('No order history yet'), findsOneWidget);
  });

  testWidgets('a failed load offers a retry that recovers', (tester) async {
    var calls = 0;
    await _pumpHistory(
      tester,
      ScriptedAdapter((_) {
        calls++;
        if (calls == 1) return (500, {'message': 'boom'});
        return _page([_order(2, 'delivered', '2026-09-15T12:00:00Z')]);
      }),
    );

    expect(find.text("Couldn't load your orders"), findsOneWidget);
    expect(find.textContaining('boom'), findsNothing);

    await tester.tap(find.text('Try again'));
    await _settle(tester);

    expect(find.text("Couldn't load your orders"), findsNothing);
    expect(find.text('Auntie Muni'), findsOneWidget);
  });

  testWidgets('tapping an order opens it', (tester) async {
    await _pumpHistory(
      tester,
      ScriptedAdapter(
        (_) => _page([_order(2, 'delivered', '2026-09-15T12:00:00Z')]),
      ),
    );

    await tester.tap(find.text('Auntie Muni'));
    await tester.pumpAndSettle();

    expect(find.text('tracking 2'), findsOneWidget);
  });
}
