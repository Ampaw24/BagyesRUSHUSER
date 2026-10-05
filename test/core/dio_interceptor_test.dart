import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/core/helpers/cache_helper.dart';
import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/services/dio_interceptor.dart';
import 'package:bagyesrushappusernew/core/singletons/cache.dart';

import 'support/auth_test_support.dart';

const _unauthenticated = (401, {'message': 'Unauthenticated.'});

void main() {
  late CacheHelper cacheHelper;
  late int expiredCount;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'session_token': 'old',
      'refresh_token': 'r1',
    });
    cacheHelper = CacheHelper(secureStorage: const FlutterSecureStorage());
    Cache.instance.setSessionToken('old');
    expiredCount = 0;
  });

  tearDown(Cache.instance.resetSession);

  Dio build(ScriptedAdapter api, ScriptedAdapter refresh) {
    final dio = scriptedDio(api);
    dio.interceptors.add(DioInterceptor(
      cacheHelper: cacheHelper,
      dio: dio,
      onSessionExpired: () => expiredCount++,
      refreshClient: scriptedDio(refresh),
    ));
    return dio;
  }

  (int, Object) acceptOnly(RequestOptions options, String token) =>
      options.headers['Authorization'] == 'Bearer $token'
          ? (200, {'ok': true})
          : _unauthenticated;

  test('concurrent 401s share one refresh, then replay with the new token',
      () async {
    final api = ScriptedAdapter((o) => acceptOnly(o, 'new'));
    final refresh = ScriptedAdapter(
      (_) => (200, {'data': {'token': 'new', 'refresh_token': 'r2'}}),
    );
    final dio = build(api, refresh);

    final responses = await Future.wait([
      dio.get('/customer/orders'),
      dio.get('/customer/wallet'),
    ]);

    expect(responses.map((r) => r.statusCode), [200, 200]);
    expect(refresh.requests, hasLength(1));
    expect(refresh.requests.single.data, {'refresh_token': 'r1'});
    expect(Cache.instance.sessionToken, 'new');
    expect(expiredCount, 0);
  });

  test('a replay that 401s again ends the session instead of looping',
      () async {
    final api = ScriptedAdapter((_) => _unauthenticated);
    final refresh = ScriptedAdapter((_) => (200, {'data': {'token': 'new'}}));
    final dio = build(api, refresh);

    await expectLater(
      dio.get('/customer/orders'),
      throwsA(isA<DioException>()
          .having((e) => e.response?.statusCode, 'status', 401)),
    );

    expect(api.requests, hasLength(2), reason: 'original + one replay');
    expect(refresh.requests, hasLength(1));
    expect(expiredCount, 1);
    expect(Cache.instance.sessionToken, isNull);
  });

  test('a failed refresh expires the session once for a burst of 401s',
      () async {
    final api = ScriptedAdapter((_) => _unauthenticated);
    final refresh = ScriptedAdapter((_) => _unauthenticated);
    final dio = build(api, refresh);

    await Future.wait([
      for (var i = 0; i < 3; i++)
        dio.get('/customer/orders').then((_) {}, onError: (_) {}),
    ]);

    expect(refresh.requests, hasLength(1));
    expect(expiredCount, 1);
    expect(Cache.instance.sessionToken, isNull);
  });

  test("a guest's 401 passes through without refresh or expiry", () async {
    Cache.instance.resetSession();
    final api = ScriptedAdapter((_) => _unauthenticated);
    final refresh = ScriptedAdapter((_) => (200, {'data': {'token': 'new'}}));
    final dio = build(api, refresh);

    await expectLater(dio.get('/customer/orders'), throwsA(isA<DioException>()));

    expect(api.requests.single.headers.containsKey('Authorization'), isFalse);
    expect(refresh.requests, isEmpty);
    expect(expiredCount, 0);
  });

  test('a 401 from login means bad credentials, not an expired session',
      () async {
    final api = ScriptedAdapter((_) => _unauthenticated);
    final refresh = ScriptedAdapter((_) => (200, {'data': {'token': 'new'}}));
    final dio = build(api, refresh);

    await expectLater(
      dio.post(ApiEndpoints.login, data: {'phone': '0', 'password': 'x'}),
      throwsA(isA<DioException>()),
    );

    expect(refresh.requests, isEmpty);
    expect(expiredCount, 0);
    expect(Cache.instance.sessionToken, 'old');
  });

  test('public auth calls omit the bearer token; account calls keep it',
      () async {
    final api = ScriptedAdapter((_) => (200, {'ok': true}));
    final dio = build(api, ScriptedAdapter((_) => (500, {})));

    await dio.post(ApiEndpoints.login, data: {});
    await dio.post(ApiEndpoints.signup, data: {});
    await dio.post(ApiEndpoints.passwordChange, data: {});
    await dio.post(ApiEndpoints.accountDelete, data: {});

    final auth = [for (final r in api.requests) r.headers['Authorization']];
    expect(auth, [null, null, 'Bearer old', 'Bearer old']);
  });

  test('every credential-bearing endpoint is redacted from logs', () {
    const sensitive = [
      ApiEndpoints.login,
      ApiEndpoints.signup,
      ApiEndpoints.vendorRegister,
      ApiEndpoints.refreshToken,
      ApiEndpoints.phoneSendCode,
      ApiEndpoints.phoneVerify,
      ApiEndpoints.passwordForgot,
      ApiEndpoints.forgotPassword,
      ApiEndpoints.passwordChange,
      ApiEndpoints.accountDelete,
    ];
    for (final path in sensitive) {
      expect(DioInterceptor.isSensitivePath(path), isTrue, reason: path);
    }
    expect(DioInterceptor.isSensitivePath('/customer/orders'), isFalse);
  });
}
