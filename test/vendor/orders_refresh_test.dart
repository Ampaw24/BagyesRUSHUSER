import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/errors/failure.dart';
import 'package:bagyesrushappusernew/src/vendor/model/vendor_order.dart';
import 'package:bagyesrushappusernew/src/vendor/repository/vendor_dashboard_repository.dart';
import 'package:bagyesrushappusernew/src/vendor/view/vendor_orders_view.dart';
import 'package:bagyesrushappusernew/src/vendor/viewmodel/dashboard_viewmodel.dart';
import 'package:bagyesrushappusernew/src/vendor/viewmodel/orders_viewmodel.dart';

VendorOrder _order(String id, OrderStatus status) => VendorOrder(
  id: id,
  orderNumber: id,
  items: '1 item',
  amount: 'GH₵ 10.00',
  timeAgo: 'now',
  status: status,
);

const _failure = ServerFailure(
  message: 'boom',
  statusCode: 500,
  title: 'Error',
);

/// Each `fetchAllOrders` call parks on its own completer, so a test decides
/// when (and in which order) responses land.
class _Repo extends Fake implements VendorDashboardRepository {
  final fetches = <Completer<Either<Failure, List<VendorOrder>>>>[];
  final searches = <String?>[];
  Either<Failure, VendorOrder>? acceptResult;

  @override
  Future<Either<Failure, List<VendorOrder>>> fetchAllOrders({
    String? status,
    String? type,
    String? paymentStatus,
    String? search,
    DateTime? from,
    DateTime? to,
    int? perPage,
  }) {
    searches.add(search);
    final completer = Completer<Either<Failure, List<VendorOrder>>>();
    fetches.add(completer);
    return completer.future;
  }

  @override
  Future<Either<Failure, VendorOrder>> acceptOrder(
    String orderId, {
    int? estimatedPrepMinutes,
  }) async => acceptResult!;

  @override
  Future<Either<Failure, VendorOrder>> markReady(String orderId) async =>
      Right(_order(orderId, OrderStatus.ready));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Repo repo;
  late OrdersViewModel vm;

  setUp(() {
    repo = _Repo();
    vm = OrdersViewModel(repo, CurrentUserProvider());
  });

  Future<void> loadInitial(List<VendorOrder> orders) async {
    final load = vm.loadOrders();
    repo.fetches.last.complete(Right(orders));
    await load;
  }

  group('OrdersViewModel.loadOrders(silent: true)', () {
    test('refreshes in place without a loading state', () async {
      await loadInitial([_order('a', OrderStatus.pending)]);

      final statuses = <OrdersStatus>[];
      vm.addListener(() => statuses.add(vm.state.status));

      final refresh = vm.loadOrders(silent: true);
      expect(vm.state.status, OrdersStatus.loaded);
      repo.fetches.last.complete(Right([_order('a', OrderStatus.accepted)]));
      await refresh;

      expect(statuses, isNot(contains(OrdersStatus.loading)));
      expect(vm.state.orders.single.status, OrderStatus.accepted);
    });

    test('keeps the current list when a background refresh fails', () async {
      await loadInitial([_order('a', OrderStatus.pending)]);

      final refresh = vm.loadOrders(silent: true);
      repo.fetches.last.complete(const Left(_failure));
      await refresh;

      expect(vm.state.status, OrdersStatus.loaded);
      expect(vm.state.errorMessage, isNull);
      expect(vm.state.orders.single.id, 'a');
    });

    test('shows the spinner when there is nothing on screen yet', () async {
      final refresh = vm.loadOrders(silent: true);
      expect(vm.state.status, OrdersStatus.loading);
      repo.fetches.last.complete(Right([_order('a', OrderStatus.pending)]));
      await refresh;
      expect(vm.state.status, OrdersStatus.loaded);
    });
  });

  group('out-of-order responses', () {
    test('a slower, older request does not overwrite a newer one', () async {
      await loadInitial([_order('a', OrderStatus.pending)]);

      final poll = vm.loadOrders(silent: true);
      final search = vm.loadOrders(search: 'b');
      repo.fetches[2].complete(Right([_order('b', OrderStatus.pending)]));
      await search;
      repo.fetches[1].complete(Right([_order('a', OrderStatus.pending)]));
      await poll;

      expect(vm.state.orders.map((o) => o.id), ['b']);
    });

    test('a failed background refresh that superseded a foreground load '
        'does not leave the list stuck loading', () async {
      await loadInitial([_order('a', OrderStatus.pending)]);

      final foreground = vm.loadOrders();
      expect(vm.state.status, OrdersStatus.loading);
      final background = vm.loadOrders(silent: true);
      repo.fetches[2].complete(const Left(_failure));
      await background;
      repo.fetches[1].complete(Right([_order('a', OrderStatus.pending)]));
      await foreground;

      expect(vm.state.status, isNot(OrdersStatus.loading));
    });
  });

  group('local changes vs. an in-flight refresh', () {
    test(
      'an action made mid-refresh is not undone by its stale response',
      () async {
        await loadInitial([_order('a', OrderStatus.preparing)]);

        final poll = vm.loadOrders(silent: true);
        await vm.markReady('a');
        expect(vm.state.orders.single.status, OrderStatus.ready);

        // The poll was answered before the server saw "ready".
        repo.fetches.last.complete(Right([_order('a', OrderStatus.preparing)]));
        await poll;

        expect(vm.state.orders.single.status, OrderStatus.ready);
      },
    );

    test('a refresh started after the action uses the server data', () async {
      await loadInitial([_order('a', OrderStatus.preparing)]);
      await vm.markReady('a');

      final poll = vm.loadOrders(silent: true);
      repo.fetches.last.complete(
        Right([_order('a', OrderStatus.outForDelivery)]),
      );
      await poll;

      expect(vm.state.orders.single.status, OrderStatus.outForDelivery);
    });

    test('an in-flight search keeps its results', () async {
      await loadInitial([_order('a', OrderStatus.preparing)]);

      final search = vm.loadOrders(search: 'x');
      vm.upsertOrder(_order('z', OrderStatus.accepted));
      repo.fetches.last.complete(Right([_order('x', OrderStatus.pending)]));
      await search;

      // Filtered response: the upserted order isn't forced into it.
      expect(vm.state.orders.map((o) => o.id), ['x']);
    });
  });

  group('upsertOrder', () {
    test('replaces an order already in the list', () async {
      await loadInitial([
        _order('a', OrderStatus.pending),
        _order('b', OrderStatus.delivered),
      ]);

      vm.upsertOrder(_order('a', OrderStatus.accepted));

      expect(vm.state.orders.map((o) => (o.id, o.status)), [
        ('a', OrderStatus.accepted),
        ('b', OrderStatus.delivered),
      ]);
    });

    test('adds a new order to the top', () async {
      await loadInitial([_order('b', OrderStatus.delivered)]);

      vm.upsertOrder(_order('a', OrderStatus.accepted));

      expect(vm.state.orders.map((o) => o.id), ['a', 'b']);
      expect(vm.state.status, OrdersStatus.loaded);
    });

    test('survives a refresh that was already in flight', () async {
      await loadInitial([_order('b', OrderStatus.delivered)]);

      final poll = vm.loadOrders(silent: true);
      vm.upsertOrder(_order('a', OrderStatus.accepted));
      repo.fetches.last.complete(Right([_order('b', OrderStatus.delivered)]));
      await poll;

      expect(vm.state.orders.map((o) => o.id), ['a', 'b']);
    });
  });

  group('DashboardViewModel.acceptOrder', () {
    test('returns the accepted order', () async {
      final dashboard = DashboardViewModel(repo, CurrentUserProvider());
      repo.acceptResult = Right(_order('a', OrderStatus.accepted));

      final accepted = await dashboard.acceptOrder('a');

      expect(accepted?.status, OrderStatus.accepted);
      expect(dashboard.state.errorMessage, isNull);
    });

    test('returns null and reports the error on failure', () async {
      final dashboard = DashboardViewModel(repo, CurrentUserProvider());
      repo.acceptResult = const Left(_failure);

      expect(await dashboard.acceptOrder('a'), isNull);
      expect(dashboard.state.errorMessage, 'boom');
    });
  });

  group('VendorOrdersView', () {
    Future<void> pumpView(WidgetTester tester, {required bool isActive}) {
      tester.view
        ..devicePixelRatio = 3
        ..physicalSize = const Size(390 * 3, 844 * 3);
      addTearDown(tester.view.reset);
      return tester.pumpWidget(
        ChangeNotifierProvider<OrdersViewModel>.value(
          value: vm,
          child: MaterialApp(
            home: Scaffold(body: VendorOrdersView(isActive: isActive)),
          ),
        ),
      );
    }

    testWidgets('refreshes when its tab becomes active', (tester) async {
      await pumpView(tester, isActive: false);
      await tester.pump();
      expect(repo.fetches, hasLength(1));
      repo.fetches.single.complete(Right([_order('a', OrderStatus.pending)]));
      await tester.pump();

      // Accepted from the dashboard, then the tab is switched to.
      vm.upsertOrder(_order('a', OrderStatus.accepted));
      await pumpView(tester, isActive: true);

      expect(repo.fetches, hasLength(2));
      expect(find.byType(CircularProgressIndicator), findsNothing);

      repo.fetches.last.complete(
        Right([
          _order('b', OrderStatus.pending),
          _order('a', OrderStatus.accepted),
        ]),
      );
      await tester.pump();
      expect(vm.state.orders.map((o) => o.id), ['b', 'a']);

      // Leaving the tab stops polling.
      await pumpView(tester, isActive: false);
      await tester.pump(const Duration(seconds: 20));
      expect(repo.fetches, hasLength(2));

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('polls while active, keeping the search', (tester) async {
      await pumpView(tester, isActive: true);
      await tester.pump();
      repo.fetches.single.complete(Right([_order('a', OrderStatus.pending)]));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump(const Duration(milliseconds: 400));
      repo.fetches.last.complete(Right([_order('a', OrderStatus.pending)]));
      await tester.pump();

      await tester.pump(const Duration(seconds: 15));
      expect(repo.searches.last, 'abc');
      repo.fetches.last.complete(Right([_order('a', OrderStatus.accepted)]));
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
    });
  });
}
