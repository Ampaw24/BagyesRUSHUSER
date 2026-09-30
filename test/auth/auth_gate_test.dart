import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/core/singletons/cache.dart';
import 'package:bagyesrushappusernew/src/auth/models/user.dart';
import 'package:bagyesrushappusernew/src/auth/views/auth_gate.dart';

const _user = User(
  id: '1',
  email: 'guest@example.com',
  phone: '+233241234567',
  role: 'customer',
  status: 'active',
  phoneVerified: true,
  profile: null,
);

void _signIn(CurrentUserProvider session) {
  Cache.instance.setSessionToken('token');
  session.setUser(_user);
}

void main() {
  late CurrentUserProvider session;
  late int actionRuns;

  setUp(() {
    Cache.instance.resetSession();
    session = CurrentUserProvider();
    actionRuns = 0;
  });

  tearDown(Cache.instance.resetSession);

  /// A screen with an account-only button, plus stand-ins for the login
  /// (signs in and pops `true`, like LoginView with returnOnSuccess) and
  /// role-picker routes the gate navigates to.
  Future<void> pumpGate(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => AuthGate.requireAuth(
                  context,
                  reason: 'Sign in to add items to your cart.',
                  action: () => actionRuns++,
                ),
                child: const Text('Add to cart'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () {
                _signIn(session);
                context.pop(true);
              },
              child: const Text('Complete login'),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, _) => const Scaffold(body: Text('Role picker')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<CurrentUserProvider>.value(
        value: session,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  testWidgets('runs the action straight away when signed in', (tester) async {
    _signIn(session);
    await pumpGate(tester);

    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();

    expect(actionRuns, 1);
    expect(find.text('Sign in to continue'), findsNothing);
  });

  testWidgets('asks a guest to sign in and drops the action on "Not now"',
      (tester) async {
    await pumpGate(tester);

    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to add items to your cart.'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(actionRuns, 0);
    expect(find.text('Add to cart'), findsOneWidget);
  });

  testWidgets('continues the action once the guest signs in', (tester) async {
    await pumpGate(tester);

    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete login'));
    await tester.pumpAndSettle();

    expect(actionRuns, 1);
    expect(find.text('Add to cart'), findsOneWidget);
  });

  testWidgets('"Create account" opens registration without the action',
      (tester) async {
    await pumpGate(tester);

    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Role picker'), findsOneWidget);
    expect(actionRuns, 0);
  });

  group('CurrentUserProvider', () {
    test('a profile without a session token is still a guest', () {
      session.setUser(_user);
      expect(session.isAuthenticated, isFalse);

      Cache.instance.setSessionToken('token');
      expect(session.isAuthenticated, isTrue);
    });

    test('sign-in listener fires on sign-in/out only, not profile updates',
        () {
      final changes = <bool>[];
      final stop = session.addSignInListener(changes.add);

      _signIn(session);
      session.setUser(_user.copyWith(email: 'updated@example.com'));
      Cache.instance.resetSession();
      session.clearUser();
      stop();
      _signIn(session);

      expect(changes, [true, false]);
    });
  });
}
