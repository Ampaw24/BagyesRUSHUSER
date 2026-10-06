import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/singletons/cache.dart';
import 'package:bagyesrushappusernew/src/auth/models/user.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/models/customer_wallet_model.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/repositories/customer_wallet_repository.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/viewmodels/customer_withdrawals_viewmodel.dart';

import '../../core/support/auth_test_support.dart';

const withdrawalsPath = '/customer/withdrawals';

Map<String, dynamic> withdrawalJson(
  int id, {
  String status = 'pending',
  num amount = 50,
}) => {
  'id': id,
  'amount': amount,
  'currency': 'GHS',
  'status': status,
  'reference': 'WD-$id',
  'created_at': '2026-10-05T09:00:00Z',
};

CustomerWalletModel wallet({
  double balance = 200,
  double withdrawable = 150,
  double minimum = 5,
  double pending = 0,
  bool canWithdraw = true,
  bool hasPayoutDetails = true,
  bool enabled = true,
}) => CustomerWalletModel(
  balance: balance,
  currency: 'GHS',
  withdrawable: withdrawable,
  spendableOnly: balance - withdrawable,
  lifetimeEarned: 0,
  lifetimeWithdrawn: 0,
  pendingEarnings: 0,
  pendingWithdrawal: pending,
  minimumWithdrawal: minimum,
  canWithdraw: canWithdraw,
  hasPayoutDetails: hasPayoutDetails,
  withdrawalsEnabled: enabled,
);

User signedInUser() => User(
  id: '1',
  email: 'a@example.com',
  phone: '+233241234567',
  role: 'customer',
  status: 'active',
  phoneVerified: true,
  profile: null,
);

/// A view model wired to a scripted backend, plus the handles tests need.
class WithdrawalHarness {
  WithdrawalHarness(ScriptedAdapter Function() script) {
    Cache.instance.setSessionToken('token');
    session = CurrentUserProvider()..setUser(signedInUser());
    adapter = script();
    vm = CustomerWithdrawalsViewModel(
      repository: CustomerWalletRepository(
        client: Dio()..httpClientAdapter = adapter,
      ),
      session: session,
    );
  }

  late final ScriptedAdapter adapter;
  late final CurrentUserProvider session;
  late final CustomerWithdrawalsViewModel vm;

  void dispose() {
    vm.dispose();
    Cache.instance.resetSession();
  }
}
