import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/src/customer-wallet/models/withdraw_eligibility.dart';

import 'support/withdrawal_test_support.dart';

void main() {
  test('a funded wallet with payout details can withdraw', () {
    expect(wallet().withdrawBlock, isNull);
  });

  test('each blocker is reported, most fundamental first', () {
    expect(wallet(enabled: false, hasPayoutDetails: false).withdrawBlock,
        WithdrawBlock.unavailable);
    expect(wallet(hasPayoutDetails: false).withdrawBlock,
        WithdrawBlock.noPayoutDetails);
    expect(wallet(withdrawable: 0).withdrawBlock,
        WithdrawBlock.nothingWithdrawable);
    expect(wallet(withdrawable: 3, minimum: 5).withdrawBlock,
        WithdrawBlock.belowMinimum);
    expect(wallet(canWithdraw: false).withdrawBlock, WithdrawBlock.notAllowed);
  });

  test('messages quote the backend figures', () {
    final w = wallet(withdrawable: 3, minimum: 5);

    expect(
      w.blockMessage(WithdrawBlock.belowMinimum),
      'The minimum withdrawal is GHS 5.00. You can withdraw GHS 3.00 right now.',
    );
    expect(
      w.blockMessage(WithdrawBlock.noPayoutDetails),
      contains('payout details'),
    );
  });
}
