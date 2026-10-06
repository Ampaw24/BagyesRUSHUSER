import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/src/customer-wallet/models/customer_withdrawal_model.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/viewmodels/customer_withdrawals_state.dart';

import '../core/support/auth_test_support.dart';
import 'support/withdrawal_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomerWithdrawalModel', () {
    test('only a pending request can be cancelled', () {
      for (final entry in {
        'pending': true,
        'processing': false,
        'completed': false,
        'failed': false,
        'cancelled': false,
      }.entries) {
        final model = CustomerWithdrawalModel.tryFromJson(
          withdrawalJson(1, status: entry.key),
        )!;
        expect(model.isCancellable, entry.value, reason: entry.key);
      }
    });

    test('an unknown status is final (never cancellable) and keeps the '
        'server wording', () {
      final model = CustomerWithdrawalModel.tryFromJson({
        ...withdrawalJson(1, status: 'on_hold'),
        'status_label': 'On hold',
      })!;

      expect(model.status, CustomerWithdrawalStatus.unknown);
      expect(model.isCancellable, isFalse);
      expect(model.displayStatus, 'On hold');
    });

    test('a payload without an id is not a withdrawal', () {
      expect(CustomerWithdrawalModel.tryFromJson({'message': 'ok'}), isNull);
    });
  });

  group('CustomerWithdrawalsViewModel', () {
    late WithdrawalHarness h;
    late List<Map<String, dynamic>> serverList;

    /// A backend that serves [serverList] and records accepted actions.
    ScriptedAdapter backend({
      int Function()? postStatus,
      Map<String, dynamic> Function()? postBody,
      int Function()? cancelStatus,
    }) => ScriptedAdapter((o) {
      final key = '${o.method} ${o.path}';
      if (key == 'GET $withdrawalsPath') {
        return (
          200,
          {
            'data': {'items': serverList},
            'meta': {'page': 1, 'pages': 2, 'total': 25},
          },
        );
      }
      if (key == 'POST $withdrawalsPath') {
        final status = postStatus?.call() ?? 201;
        if (status != 201) return (status, postBody!.call());
        serverList = [withdrawalJson(9, amount: 40), ...serverList];
        return (201, {'data': withdrawalJson(9, amount: 40)});
      }
      if (key.startsWith('PATCH $withdrawalsPath/') && key.endsWith('/cancel')) {
        final status = cancelStatus?.call() ?? 200;
        if (status != 200) return (status, {'message': 'Cannot cancel'});
        final id = o.path.split('/')[3];
        serverList = [
          for (final w in serverList)
            if ('${w['id']}' == id) {...w, 'status': 'cancelled'} else w,
        ];
        return (200, {'message': 'Cancelled'});
      }
      return (404, {'message': 'not found'});
    });

    setUp(() => serverList = [withdrawalJson(1), withdrawalJson(2, status: 'completed')]);
    tearDown(() => h.dispose());

    test('fetch reads the list, nested envelope and pagination', () async {
      h = WithdrawalHarness(backend);

      await h.vm.fetch();

      expect(h.vm.state.status, WithdrawalsStatus.loaded);
      expect(h.vm.state.withdrawals.map((w) => w.id), ['1', '2']);
      expect(h.vm.state.hasMore, isTrue, reason: 'page 1 of 2');
      expect(h.vm.state.pendingCount, 1);
    });

    test('requesting sends only the amount, then refreshes the list',
        () async {
      h = WithdrawalHarness(backend);
      await h.vm.fetch();

      final error = await h.vm.request(40);

      expect(error, isNull);
      final post = h.adapter.requests.firstWhere((r) => r.method == 'POST');
      expect(post.data, {'amount': 40});
      expect(h.vm.state.withdrawals.first.id, '9', reason: 'new request shown');
      expect(h.vm.state.isRequesting, isFalse);
    });

    test('a rejected request returns the server message and changes nothing',
        () async {
      h = WithdrawalHarness(
        () => backend(
          postStatus: () => 422,
          postBody: () => {'message': 'Add a payout method first.'},
        ),
      );
      await h.vm.fetch();

      final error = await h.vm.request(40);

      expect(error, 'Add a payout method first.');
      expect(h.vm.state.withdrawals.length, 2);
      expect(h.vm.state.isRequesting, isFalse);
    });

    test('cancelling PATCHes the right path and shows it cancelled',
        () async {
      h = WithdrawalHarness(backend);
      await h.vm.fetch();

      final error = await h.vm.cancel('1');

      expect(error, isNull);
      expect(
        h.adapter.calls,
        contains('PATCH $withdrawalsPath/1/cancel'),
      );
      final first = h.vm.state.withdrawals.firstWhere((w) => w.id == '1');
      expect(first.status, CustomerWithdrawalStatus.cancelled);
      expect(first.isCancellable, isFalse);
      expect(h.vm.state.cancellingId, isNull);
    });

    test('a refused cancellation returns the message and leaves it pending',
        () async {
      h = WithdrawalHarness(() => backend(cancelStatus: () => 422));
      await h.vm.fetch();

      final error = await h.vm.cancel('1');

      expect(error, 'Cannot cancel');
      expect(
        h.vm.state.withdrawals.firstWhere((w) => w.id == '1').isCancellable,
        isTrue,
      );
      expect(h.vm.state.cancellingId, isNull);
    });

    test('only one cancellation runs at a time', () async {
      h = WithdrawalHarness(backend);
      await h.vm.fetch();

      final results = await Future.wait([h.vm.cancel('1'), h.vm.cancel('1')]);

      expect(results, [null, null]);
      expect(
        h.adapter.calls.where((c) => c.startsWith('PATCH')).length,
        1,
      );
    });

    test('logging out drops the previous account\'s withdrawals', () async {
      h = WithdrawalHarness(backend);
      await h.vm.fetch();
      expect(h.vm.state.withdrawals, isNotEmpty);

      h.session.clearUser();

      expect(h.vm.state, const CustomerWithdrawalsState());
    });
  });
}
