import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/src/parcel/model/parcel.dart';
import 'package:bagyesrushappusernew/src/parcel/model/parcel_quote.dart';
import 'package:bagyesrushappusernew/src/parcel/viewmodel/send_parcel_viewmodel.dart';

ParcelQuote _quote({double total = 30.4, DateTime? expiresAt}) =>
    ParcelQuote.fromJson({
      'delivery_quote_id': 5141,
      'fee': 28,
      'service_fee': 2.4,
      'total': total,
      'currency': 'GHS',
      if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
      'rider': {'id': 31, 'name': 'Kofi O.'},
    });

SendParcelState _summary({
  double walletBalance = 0,
  bool useWallet = false,
  List<ParcelQuote>? quotes,
  bool isFetchingQuote = false,
}) =>
    SendParcelState(
      currentStep: ParcelStep.summary,
      riderQuotes: quotes ?? [_quote()],
      selectedRiderId: '31',
      useWallet: useWallet,
      walletBalance: walletBalance,
      isFetchingQuote: isFetchingQuote,
    );

void main() {
  group('ParcelQuote.isBookableAt', () {
    final now = DateTime.utc(2026, 9, 30, 12);

    test('is bookable well before it expires', () {
      final quote = _quote(expiresAt: now.add(const Duration(minutes: 5)));
      expect(quote.isBookableAt(now), isTrue);
    });

    test('is not bookable inside the safety margin', () {
      final quote = _quote(expiresAt: now.add(const Duration(seconds: 10)));
      expect(quote.isBookableAt(now), isFalse);
    });

    test('is not bookable once expired', () {
      final quote = _quote(expiresAt: now.subtract(const Duration(minutes: 1)));
      expect(quote.isBookableAt(now), isFalse);
    });

    test('a quote without an expiry is never assumed valid', () {
      expect(_quote().isBookableAt(now), isFalse);
    });
  });

  group('Parcel.needsPayment', () {
    Parcel parcel(Map<String, dynamic> extra) =>
        Parcel.fromJson({'id': 90, 'status': 'pending', ...extra});

    test('payment.requires_payment false means nothing is owed', () {
      expect(parcel({'payment': {'requires_payment': false}}).needsPayment,
          isFalse);
    });

    test('payment.is_paid means nothing is owed', () {
      expect(parcel({'payment': {'is_paid': true}}).needsPayment, isFalse);
    });

    test('a zero amount due means nothing is owed', () {
      expect(parcel({'amount_due': 0}).needsPayment, isFalse);
    });

    test('a positive amount due is still owed', () {
      expect(parcel({'payment': {'amount_due': 18.05}}).needsPayment, isTrue);
    });

    test('is unknown when the response says nothing', () {
      expect(parcel({}).needsPayment, isNull);
    });
  });

  group('Parcel summary with the wallet', () {
    test('a covering wallet can confirm', () {
      final state = _summary(walletBalance: 50, useWallet: true);
      expect(state.walletSplit.coversFully, isTrue);
      expect(state.walletSplit.remaining, 0);
      expect(state.walletBalanceAfter, 19.6);
      expect(state.canProceed, isTrue);
    });

    test('a partial wallet leaves the exact remainder for Paystack, and '
        'confirming needs no payment method', () {
      final state = _summary(walletBalance: 12.35, useWallet: true);
      expect(state.walletSplit.walletAmount, 12.35);
      expect(state.walletSplit.remaining, 18.05);
      expect(state.walletBalanceAfter, 0);
      // The remainder is paid on Paystack's page — nothing to pick here.
      expect(state.canProceed, isTrue);
    });

    test('wallet off charges the full total', () {
      final state = _summary(walletBalance: 50);
      expect(state.walletSplit.usesWallet, isFalse);
      expect(state.walletSplit.remaining, 30.4);
      expect(state.walletBalanceAfter, 50);
    });

    test('cannot confirm without a visible price', () {
      expect(
        _summary(walletBalance: 50, useWallet: true, quotes: const [])
            .canProceed,
        isFalse,
      );
      expect(
        _summary(walletBalance: 50, useWallet: true, isFetchingQuote: true)
            .canProceed,
        isFalse,
      );
    });
  });
}
