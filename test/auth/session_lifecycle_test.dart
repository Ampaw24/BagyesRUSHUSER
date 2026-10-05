import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/helpers/cache_helper.dart';
import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/singletons/cache.dart';
import 'package:bagyesrushappusernew/src/auth/repositories/auth_repository.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_state.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_viewmodel.dart';

import '../core/support/auth_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CountingRealtime realtime;
  late CurrentUserProvider session;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'session_token': 'tok',
      'user_id': '42',
      'user_role': 'customer',
    });
    Cache.instance
      ..setSessionToken('tok')
      ..setUserId('42');
    realtime = CountingRealtime();
    session = CurrentUserProvider();
  });

  tearDown(Cache.instance.resetSession);

  AuthViewmodel build(ScriptedAdapter api) => AuthViewmodel(
        repository: AuthRepository(
          client: scriptedDio(api),
          cacheHelper: CacheHelper(secureStorage: const FlutterSecureStorage()),
        ),
        currentUserProvider: session,
        realtimeService: realtime,
      );

  group('restoreSession', () {
    test('keeps the session when the backend is unreachable', () async {
      final vm = build(ScriptedAdapter((o) => throw DioException(
            requestOptions: o,
            type: DioExceptionType.connectionError,
          )));

      await vm.restoreSession();
      await vm.sessionValidation;

      expect(vm.state, isA<LoggedIn>());
      expect(Cache.instance.sessionToken, 'tok');
      expect(session.user?.id, '42');
    });

    test('keeps the session on a server error', () async {
      final vm = build(ScriptedAdapter((_) => (503, {'message': 'down'})));

      await vm.restoreSession();
      await vm.sessionValidation;

      expect(vm.state, isA<LoggedIn>());
      expect(Cache.instance.sessionToken, 'tok');
    });

    test('ends the session when the backend rejects the token', () async {
      final vm =
          build(ScriptedAdapter((_) => (401, {'message': 'Unauthenticated.'})));

      await vm.restoreSession();
      await vm.sessionValidation;

      expect(vm.state, isA<LoggedOut>());
      expect(Cache.instance.sessionToken, isNull);
      expect(session.user, isNull);
    });
  });

  test('logout deregisters the device before revoking the token', () async {
    final api = ScriptedAdapter((_) => (200, {'ok': true}));
    final vm = build(api);
    await vm.restoreSession();

    await vm.logout();

    expect(api.calls, containsAllInOrder([
      'DELETE ${ApiEndpoints.deviceToken}',
      'POST ${ApiEndpoints.logout}',
    ]));
    expect(realtime.disconnects, 1);
    expect(session.user, isNull);
    expect(Cache.instance.sessionToken, isNull);
    expect(vm.state, isA<LoggedOut>());
  });

  test('handleSessionExpired ends a live session once', () async {
    final vm = build(ScriptedAdapter((_) => (200, {'ok': true})));
    await vm.restoreSession();

    expect(await vm.handleSessionExpired(), isTrue);
    expect(await vm.handleSessionExpired(), isFalse);

    expect(realtime.disconnects, 1);
    expect(session.user, isNull);
    expect(vm.state, isA<LoggedOut>());
  });
}
