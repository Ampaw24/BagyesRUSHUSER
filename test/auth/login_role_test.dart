import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/helpers/cache_helper.dart';
import 'package:bagyesrushappusernew/core/singletons/cache.dart';
import 'package:bagyesrushappusernew/src/auth/repositories/auth_repository.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_state.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_viewmodel.dart';

import '../core/support/auth_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CountingRealtime realtime;
  late CurrentUserProvider session;
  late CacheHelper cacheHelper;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    Cache.instance.resetSession();
    realtime = CountingRealtime();
    session = CurrentUserProvider();
    cacheHelper = CacheHelper(secureStorage: const FlutterSecureStorage());
  });

  tearDown(Cache.instance.resetSession);

  /// A successful login response for an account with [role]. Device-token
  /// registration and anything else after login just gets a 200.
  ScriptedAdapter api(String role) => ScriptedAdapter((options) {
    if (options.path.contains('login')) {
      return (
        200,
        {
          'data': {
            'token': 'tok',
            'refresh_token': 'refresh',
            'user': {
              'id': '42',
              'email': 'user@example.com',
              'phone': '+233241234567',
              'role': role,
              'status': 'active',
              'phone_verified': true,
            },
          },
        },
      );
    }
    return (200, {'data': {}});
  });

  AuthViewmodel build(ScriptedAdapter adapter) => AuthViewmodel(
    repository: AuthRepository(
      client: scriptedDio(adapter),
      cacheHelper: cacheHelper,
    ),
    currentUserProvider: session,
    realtimeService: realtime,
  );

  Future<AuthViewmodel> login(String role) async {
    final vm = build(api(role));
    await vm.login(phoneNumber: '+233241234567', password: 'secret');
    return vm;
  }

  for (final role in ['customer', 'vendor']) {
    test('signs in a $role', () async {
      final vm = await login(role);

      expect(vm.state, isA<LoggedIn>());
      expect(session.user?.role, role);
      expect(await cacheHelper.getSessionToken(), 'tok');
    });
  }

  test('accepts a role regardless of casing, normalized', () async {
    final vm = await login(' Vendor ');

    expect(vm.state, isA<LoggedIn>());
    expect(session.user?.role, 'vendor');
    expect(session.user?.isVendor, isTrue);
    expect(await cacheHelper.getUserRole(), 'vendor');
  });

  for (final role in ['rider', 'admin', '']) {
    test('turns away a "${role.isEmpty ? '<empty>' : role}" account as '
        'invalid credentials, without starting a session', () async {
      final vm = await login(role);

      expect(vm.state, isA<AuthError>());
      final error = vm.state as AuthError;
      expect(
        error.message,
        'Incorrect phone number or password. Please try again.',
      );
      // Must not trip the login screen's "phone not verified" branch.
      expect(error.message.toLowerCase(), isNot(contains('verif')));

      expect(session.user, isNull);
      expect(Cache.instance.sessionToken, isNull);
      expect(await cacheHelper.getSessionToken(), isNull);
      expect(await cacheHelper.getRefreshToken(), isNull);
      expect(await cacheHelper.getUserId(), isNull);
      expect(await cacheHelper.getUserRole(), isNull);
      expect(realtime.connects, 0);
    });
  }
}
