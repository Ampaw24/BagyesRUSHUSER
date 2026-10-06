import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/errors/failure.dart';
import 'package:bagyesrushappusernew/core/singletons/cache.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/repositories/customer_wallet_repository.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/viewmodels/payout_setup_viewmodel.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/views/add_payout_method_view.dart';
import 'package:bagyesrushappusernew/src/payment/model/payout_provider_model.dart';
import 'package:bagyesrushappusernew/src/payment/repository/payment_repository.dart';
import 'package:bagyesrushappusernew/src/payment/viewmodel/payout_providers_viewmodel.dart';

import '../core/support/auth_test_support.dart';
import 'support/withdrawal_test_support.dart';

const _payoutPath = '/customer/wallet/payout-method';

PayoutProviderModel _provider(int id, String name, {String type = 'mobile_money'}) =>
    PayoutProviderModel(
      id: id, type: type, name: name, shortName: name, slug: name.toLowerCase(),
    );

class _FakeProviders extends Fake implements PaymentRepository {
  _FakeProviders({this.fail = false});
  final bool fail;

  @override
  ResultFuture<List<PayoutProviderModel>> getPayoutProviders({String? type}) async {
    if (fail) {
      return const Left(ServerFailure(message: 'down', statusCode: 500, title: 'x'));
    }
    return Right([
      _provider(27, 'MTN Mobile Money'),
      _provider(28, 'Telecel Cash'),
      _provider(90, 'GCB Bank', type: 'bank'),
    ]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScriptedAdapter adapter;
  late PayoutSetupViewModel setup;

  void build({int status = 200}) {
    adapter = ScriptedAdapter((o) {
      if (o.method == 'PUT' && o.path == _payoutPath) {
        return status == 200
            ? (200, {'success': true, 'data': {}})
            : (status, {'message': 'That network isn\'t supported.'});
      }
      return (404, {'message': 'unexpected ${o.method} ${o.path}'});
    });
    setup = PayoutSetupViewModel(
      repository: CustomerWalletRepository(client: Dio()..httpClientAdapter = adapter),
    );
  }

  setUp(() => Cache.instance.setSessionToken('token'));
  tearDown(() => Cache.instance.resetSession());

  group('PayoutSetupViewModel', () {
    test('cannot save before a network is picked', () async {
      build();
      expect(setup.state.canSave, isFalse);
      expect(await setup.save(), isFalse);
      expect(adapter.requests, isEmpty);
      setup.dispose();
    });

    test('saves with PUT and only payout_provider_id', () async {
      build();
      setup.select(27);

      expect(await setup.save(), isTrue);

      expect(adapter.calls, ['PUT $_payoutPath']);
      expect(adapter.requests.single.data, {'payout_provider_id': 27});
      expect(setup.state.isSaving, isFalse);
      setup.dispose();
    });

    test('the server\'s refusal is kept for the screen, and picking again clears it',
        () async {
      build(status: 422);
      setup.select(27);

      expect(await setup.save(), isFalse);
      expect(setup.state.errorMessage, 'That network isn\'t supported.');

      setup.select(28);
      expect(setup.state.errorMessage, isNull);
      setup.dispose();
    });
  });

  group('AddPayoutMethodView', () {
    late CurrentUserProvider session;
    bool? popped;

    Future<void> open(WidgetTester tester, {int status = 200, bool providersFail = false}) async {
      tester.view
        ..devicePixelRatio = 3
        ..physicalSize = const Size(390 * 3, 844 * 3);
      addTearDown(tester.view.reset);

      build(status: status);
      addTearDown(setup.dispose);
      session = CurrentUserProvider()..setUser(signedInUser());
      final providers = PayoutProvidersViewModel(
        repository: _FakeProviders(fail: providersFail),
      );
      addTearDown(providers.dispose);
      popped = null;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: setup),
            ChangeNotifierProvider.value(value: providers),
            ChangeNotifierProvider.value(value: session),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async => popped = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const AddPayoutMethodView()),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Finder save() => find.widgetWithText(ElevatedButton, 'Save payout method');

    testWidgets('shows the verified phone number and only mobile-money networks',
        (tester) async {
      await open(tester);

      expect(find.text('+233241234567'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('MTN Mobile Money'), findsOneWidget);
      expect(find.text('Telecel Cash'), findsOneWidget);
      expect(find.text('GCB Bank'), findsNothing);
    });

    testWidgets('Save is off until a network is picked, then sends its id and pops true',
        (tester) async {
      await open(tester);
      expect(tester.widget<ElevatedButton>(save()).onPressed, isNull);

      await tester.tap(find.text('Telecel Cash'));
      await tester.pump();
      expect(tester.widget<ElevatedButton>(save()).onPressed, isNotNull);

      await tester.tap(save());
      await tester.pumpAndSettle();

      expect(adapter.requests.single.data, {'payout_provider_id': 28});
      expect(popped, isTrue);
    });

    testWidgets('a server refusal stays on the page, inline', (tester) async {
      await open(tester, status: 422);

      await tester.tap(find.text('MTN Mobile Money'));
      await tester.pump();
      await tester.tap(save());
      await tester.pumpAndSettle();

      expect(find.text('That network isn\'t supported.'), findsOneWidget);
      expect(find.byType(AddPayoutMethodView), findsOneWidget);
      expect(popped, isNull);
    });

    testWidgets('a failed network list offers Retry', (tester) async {
      await open(tester, providersFail: true);

      expect(find.text('Couldn\'t load the networks.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
