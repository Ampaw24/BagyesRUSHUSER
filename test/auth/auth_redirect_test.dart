import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/core/router/app_router.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/src/auth/models/user.dart';

User _user({String role = 'customer', bool phoneVerified = true}) => User(
      id: '1',
      email: 'user@example.com',
      phone: '+233241234567',
      role: role,
      status: 'active',
      phoneVerified: phoneVerified,
      profile: null,
    );

/// Mirrors how the router calls it: [pattern] is the route template
/// (`state.fullPath`), [location] the concrete path.
String? _guest(String location, [String? pattern]) => resolveAuthRedirect(
      location: location,
      routePattern: pattern ?? location,
      hasToken: false,
    );

String? _signedIn(String location, {User? user, String? pattern}) =>
    resolveAuthRedirect(
      location: location,
      routePattern: pattern ?? location,
      hasToken: true,
      user: user ?? _user(),
    );

void main() {
  group('guest', () {
    test('can browse without being sent to login', () {
      expect(_guest(AppRoutes.splash), isNull);
      expect(_guest(AppRoutes.home), isNull);
      expect(
        _guest(
          AppRoutes.restaurantDetailPath('01HABC'),
          AppRoutes.restaurantDetail,
        ),
        isNull,
      );
      expect(_guest(AppRoutes.consumerSearch), isNull);
      expect(_guest(AppRoutes.helpSupport), isNull);
      expect(_guest(AppRoutes.privacyPolicy), isNull);
      expect(_guest(AppRoutes.termsConditions), isNull);
      expect(_guest(AppRoutes.refundPolicy), isNull);
      expect(_guest(AppRoutes.login), isNull);
      expect(_guest(AppRoutes.signup), isNull);
      expect(_guest(AppRoutes.onboarding), isNull);
    });

    test('is sent to login for account-only routes', () {
      for (final route in [
        AppRoutes.cart,
        AppRoutes.checkout,
        AppRoutes.trackOrder,
        AppRoutes.notifications,
        AppRoutes.wallet,
        AppRoutes.profile,
        AppRoutes.editProfile,
        AppRoutes.customerPaymentMethods,
        AppRoutes.sendPackages,
        AppRoutes.chatList,
        AppRoutes.myReports,
        AppRoutes.inviteFriend,
        AppRoutes.vendorHome,
      ]) {
        expect(_guest(route), AppRoutes.login, reason: route);
      }
    });
  });

  group('signed in', () {
    test('keeps using browse routes', () {
      expect(_signedIn(AppRoutes.home), isNull);
      expect(_signedIn(AppRoutes.cart), isNull);
    });

    test('a vendor is sent from the consumer home to vendor home', () {
      final vendor = _user(role: 'vendor');
      expect(_signedIn(AppRoutes.home, user: vendor), AppRoutes.vendorHome);
      expect(_signedIn(AppRoutes.vendorHome, user: vendor), isNull);
    });

    test('can stay on login so a sign-in prompt can pop back', () {
      expect(_signedIn(AppRoutes.login), isNull);
    });

    test('is still bounced off signup to their role home', () {
      expect(_signedIn(AppRoutes.signup), AppRoutes.home);
      expect(
        _signedIn(AppRoutes.signup, user: _user(role: 'vendor')),
        AppRoutes.vendorHome,
      );
    });

    test('unverified phone is still gated to KYC, browse routes included',
        () {
      final unverified = _user(phoneVerified: false);
      expect(
        _signedIn(AppRoutes.home, user: unverified),
        AppRoutes.kycVerification,
      );
      expect(
        _signedIn(AppRoutes.privacyPolicy, user: unverified),
        isNull,
      );
    });
  });
}
