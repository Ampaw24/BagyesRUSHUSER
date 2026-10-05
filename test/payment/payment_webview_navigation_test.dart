import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/src/payment/views/screens/payment_webview_screen.dart';

GatewayNavigation _decide(String url, {bool isMainFrame = true}) =>
    decideGatewayNavigation(Uri.tryParse(url), isMainFrame: isMainFrame);

void main() {
  group('inside the Paystack gateway', () {
    test('stays on Paystack hosts', () {
      expect(_decide('https://checkout.paystack.com/abc'), GatewayNavigation.allow);
      expect(_decide('https://standard.paystack.co/pay'), GatewayNavigation.allow);
    });

    test('never follows non-https links', () {
      for (final url in [
        'http://checkout.paystack.com/abc',
        'tel:+233241234567',
        'intent://scan/#Intent;scheme=zxing;end',
        'javascript:alert(1)',
      ]) {
        expect(_decide(url), GatewayNavigation.block, reason: url);
      }
      expect(decideGatewayNavigation(null, isMainFrame: true), GatewayNavigation.block);
    });
  });

  group('leaving the gateway', () {
    test('the page redirecting to the merchant callback completes the charge',
        () {
      expect(
        _decide('https://api.bagyesrushdelivery.com/payment/callback?reference=r1'),
        GatewayNavigation.complete,
      );
    });

    test('an embedded frame loading another host does not close checkout', () {
      expect(
        _decide('https://3ds.some-bank.com/challenge', isMainFrame: false),
        GatewayNavigation.allow,
      );
    });

    test('a non-https frame is still blocked', () {
      expect(
        _decide('http://tracker.example/pixel', isMainFrame: false),
        GatewayNavigation.block,
      );
    });
  });
}
