import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/src/customer-wallet/models/wallet_split.dart';

void main() {
  group('WalletSplit.from', () {
    test('wallet off charges the full total to mobile money', () {
      final split = WalletSplit.from(balance: 50, total: 30.4, useWallet: false);
      expect(split.walletAmount, 0);
      expect(split.remaining, 30.4);
      expect(split.usesWallet, isFalse);
      expect(split.coversFully, isFalse);
    });

    test('a partial balance leaves an exact remainder', () {
      final split = WalletSplit.from(balance: 12.35, total: 30.4, useWallet: true);
      expect(split.walletAmount, 12.35);
      expect(split.remaining, 18.05);
      expect(split.coversFully, isFalse);
    });

    test('parts always add back up to the total', () {
      final split = WalletSplit.from(balance: 0.1, total: 0.3, useWallet: true);
      expect(split.walletAmount, 0.1);
      expect(split.remaining, 0.2);
      expect(
        WalletSplit.toMinorUnits(split.walletAmount) +
            WalletSplit.toMinorUnits(split.remaining),
        WalletSplit.toMinorUnits(0.3),
      );
    });

    test('a larger balance covers the total and only deducts the total', () {
      final split = WalletSplit.from(balance: 100, total: 30.4, useWallet: true);
      expect(split.walletAmount, 30.4);
      expect(split.remaining, 0);
      expect(split.coversFully, isTrue);
    });

    test('a balance exactly equal to the total covers it', () {
      final split = WalletSplit.from(balance: 30.4, total: 30.4, useWallet: true);
      expect(split.remaining, 0);
      expect(split.coversFully, isTrue);
    });

    test('nothing is covered while the total is unknown', () {
      final split = WalletSplit.from(balance: 100, total: null, useWallet: true);
      expect(split.usesWallet, isFalse);
      expect(split.coversFully, isFalse);
    });

    test('an empty wallet changes nothing', () {
      final split = WalletSplit.from(balance: 0, total: 30.4, useWallet: true);
      expect(split.walletAmount, 0);
      expect(split.remaining, 30.4);
      expect(split.coversFully, isFalse);
    });
  });
}
