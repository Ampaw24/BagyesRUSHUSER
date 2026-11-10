import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gopady/core/router/app_router.dart';
import 'package:gopady/core/router/app_routes.dart';
import 'package:gopady/core/router/auth_redirect_refresh.dart';
import 'package:gopady/src/auth/models/user.dart';

/// Stand-in for CurrentUserProvider: notifies on every change, exactly like
/// the real one does for login, logout and every profile merge.
class _Session extends ChangeNotifier {
  User? user;

  bool get signedIn => user != null;

  User _build(String role) => User(
        id: '1',
        email: 'user@example.com',
        phone: '+233241234567',
        role: role,
        status: 'active',
        phoneVerified: true,
        profile: null,
      );

  void signIn({String role = 'customer'}) {
    user = _build(role);
    notifyListeners();
  }

  void mergeProfile() => notifyListeners();

  void signOut() {
    user = null;
    notifyListeners();
  }
}

/// A screen that finishes sign-in the way LoginView does: the session changes
/// first (which is what refreshes the router), then it navigates.
class _LoginStub extends StatelessWidget {
  const _LoginStub({required this.session, required this.returnOnSuccess});

  final _Session session;
  final bool returnOnSuccess;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () {
          session.signIn();
          if (returnOnSuccess) {
            context.pop(true);
          } else {
            context.go(AppRoutes.home);
          }
        },
        child: const Text('login-screen'),
      );
}

GoRouter _buildRouter(_Session session, String initialLocation) {
  late final GoRouter router;
  router = GoRouter(
    initialLocation: initialLocation,
    refreshListenable: AuthRedirectRefresh(
      source: session,
      isAuthenticated: () => session.signedIn,
      wouldRedirect: () => authRedirectWouldFire(
        router,
        hasToken: session.signedIn,
        user: session.user,
      ),
    ),
    redirect: (context, state) => resolveAuthRedirect(
      location: state.matchedLocation,
      routePattern: state.fullPath,
      hasToken: session.signedIn,
      user: session.user,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const Text('onboarding-screen'),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const Text('home-screen'),
      ),
      GoRoute(
        path: AppRoutes.vendorHome,
        builder: (_, _) => const Text('vendor-home-screen'),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => const Text('profile-screen'),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, state) {
          final extra = state.extra;
          final returnOnSuccess = extra is Map<String, dynamic>
              ? extra['returnOnSuccess'] as bool? ?? false
              : false;
          return _LoginStub(
            session: session,
            returnOnSuccess: returnOnSuccess,
          );
        },
      ),
    ],
  );
  return router;
}

Future<void> _mount(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

Future<void> _tapLogin(WidgetTester tester) async {
  await tester.tap(find.text('login-screen'));
  await tester.pumpAndSettle();
}

void main() {
  group('login returns to the screen that asked for sign-in', () {
    testWidgets('guest prompt: pop(true) closes login and resolves the push',
        (tester) async {
      final session = _Session();
      final router = _buildRouter(session, AppRoutes.home);
      await _mount(tester, router);

      bool? signedIn;
      router
          .push<bool>(AppRoutes.login, extra: {'returnOnSuccess': true})
          .then((value) => signedIn = value);
      await tester.pumpAndSettle();
      expect(find.text('login-screen'), findsOneWidget);

      await _tapLogin(tester);

      expect(find.text('login-screen'), findsNothing);
      expect(find.text('home-screen'), findsOneWidget);
      expect(signedIn, isTrue);
    });

    testWidgets('a profile merge while a page is pushed does not break its pop',
        (tester) async {
      final session = _Session()..user = null;
      final router = _buildRouter(session, AppRoutes.home);
      await _mount(tester, router);
      session.signIn();
      await tester.pumpAndSettle();

      bool? result;
      router
          .push<bool>(AppRoutes.login, extra: {'returnOnSuccess': true})
          .then((value) => result = value);
      await tester.pumpAndSettle();

      session.mergeProfile(); // e.g. a background profile refresh
      await tester.pumpAndSettle();
      router.pop(true);
      await tester.pumpAndSettle();

      expect(find.text('login-screen'), findsNothing);
      expect(find.text('home-screen'), findsOneWidget);
      expect(result, isTrue);
    });
  });

  group('login still lands on home when it was not pushed over a screen', () {
    testWidgets('onboarding -> login -> home', (tester) async {
      final session = _Session();
      final router = _buildRouter(session, AppRoutes.onboarding);
      await _mount(tester, router);

      router.push(AppRoutes.login);
      await tester.pumpAndSettle();
      await _tapLogin(tester);

      expect(find.text('home-screen'), findsOneWidget);
    });

    testWidgets('cold login screen -> home', (tester) async {
      final session = _Session();
      final router = _buildRouter(session, AppRoutes.login);
      await _mount(tester, router);

      await _tapLogin(tester);

      expect(find.text('home-screen'), findsOneWidget);
    });
  });

  group('redirects that must still fire', () {
    testWidgets('a vendor session on the consumer home goes to vendor home',
        (tester) async {
      final session = _Session();
      final router = _buildRouter(session, AppRoutes.home);
      await _mount(tester, router);

      session.signIn(role: 'vendor');
      await tester.pumpAndSettle();

      expect(find.text('vendor-home-screen'), findsOneWidget);
    });

    testWidgets('signing out on an account-only screen goes to login',
        (tester) async {
      final session = _Session()..user = null;
      final router = _buildRouter(session, AppRoutes.home);
      await _mount(tester, router);
      session.signIn();
      await tester.pumpAndSettle();
      router.go(AppRoutes.profile);
      await tester.pumpAndSettle();
      expect(find.text('profile-screen'), findsOneWidget);

      session.signOut();
      await tester.pumpAndSettle();

      expect(find.text('login-screen'), findsOneWidget);
    });
  });
}
