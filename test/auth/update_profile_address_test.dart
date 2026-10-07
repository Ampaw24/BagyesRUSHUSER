import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/helpers/cache_helper.dart';
import 'package:bagyesrushappusernew/core/singletons/cache.dart';
import 'package:bagyesrushappusernew/presentation/profile/edit_profile.dart';
import 'package:bagyesrushappusernew/src/auth/models/user.dart';
import 'package:bagyesrushappusernew/src/auth/repositories/auth_repository.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_viewmodel.dart';

import '../core/support/auth_test_support.dart';

User _user({
  String email = 'ama@example.com',
  String phone = '+233241234567',
}) => User(
  id: '42',
  email: email,
  phone: phone,
  role: 'customer',
  status: 'active',
  phoneVerified: true,
  profile: const CustomerProfile(
    id: 'p1',
    userId: '42',
    firstName: 'Ama',
    lastName: 'Mensah',
    address: 'Old Road, Accra',
    profilePictureUrl: null,
    referralCode: '',
    referralCount: 0,
    createdAt: null,
    updatedAt: null,
    v: 0,
  ),
);

/// `PUT customer/me` answers with the bare profile document.
DataMapResponse _profileDoc({String? address}) => {
  'data': {
    'user_id': '42',
    'first_name': 'Ama',
    'last_name': 'Mensah',
    'address': ?address,
  },
};

typedef DataMapResponse = Map<String, Object?>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CurrentUserProvider session;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    Cache.instance.setSessionToken('tok');
    session = CurrentUserProvider()..setUser(_user());
  });

  tearDown(Cache.instance.resetSession);

  AuthViewmodel build(ScriptedAdapter api) => AuthViewmodel(
    repository: AuthRepository(
      client: scriptedDio(api),
      cacheHelper: CacheHelper(secureStorage: const FlutterSecureStorage()),
    ),
    currentUserProvider: session,
    realtimeService: CountingRealtime(),
  );

  String? addressOf(User? user) => (user?.profile as CustomerProfile?)?.address;

  Future<dynamic> save(
    AuthViewmodel vm, {
    String address = 'New Street, Kumasi',
  }) => vm.updateProfile(
    firstName: 'Ama',
    lastName: 'Mensah',
    email: 'ama@example.com',
    phone: session.user!.phone,
    address: address,
  );

  group('updateProfile address', () {
    test('saves when the server keeps the new address', () async {
      final vm = build(
        ScriptedAdapter(
          (_) => (200, _profileDoc(address: 'New Street, Kumasi')),
        ),
      );

      final result = await save(vm);

      expect(result.isRight(), isTrue);
      expect(addressOf(session.user), 'New Street, Kumasi');
    });

    test('ignores whitespace/casing differences in the echo', () async {
      final vm = build(
        ScriptedAdapter(
          (_) => (200, _profileDoc(address: ' new street,  kumasi ')),
        ),
      );

      expect((await save(vm)).isRight(), isTrue);
    });

    test('saves when the response does not echo an address', () async {
      final vm = build(ScriptedAdapter((_) => (200, _profileDoc())));

      expect((await save(vm)).isRight(), isTrue);
      expect(addressOf(session.user), 'New Street, Kumasi');
    });

    test(
      'reports the address as not saved when the server kept the old one',
      () async {
        final vm = build(
          ScriptedAdapter(
            (_) => (200, _profileDoc(address: 'Old Road, Accra')),
          ),
        );

        final result = await save(vm);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AddressNotSavedFailure>()),
          (_) {},
        );
        // The cache shows what the server really has, not the rejected edit.
        expect(addressOf(session.user), 'Old Road, Accra');
      },
    );

    test('never sends a blank phone from a placeholder user', () async {
      session.setUser(_user(phone: ''));
      final api = ScriptedAdapter(
        (_) => (200, _profileDoc(address: 'New Street, Kumasi')),
      );
      final vm = build(api);

      await save(vm);

      final body = api.requests.single.data;
      final sent = body is String ? jsonDecode(body) : body as Map;
      expect(sent.containsKey('phone'), isFalse);
      expect(sent['address'], 'New Street, Kumasi');
    });
  });

  group('EditProfile', () {
    Future<ScriptedAdapter> pumpScreen(WidgetTester tester) async {
      tester.view
        ..devicePixelRatio = 3
        ..physicalSize = const Size(360 * 3, 640 * 3);
      addTearDown(tester.view.reset);

      final api = ScriptedAdapter(
        (_) => (200, _profileDoc(address: 'New Street, Kumasi')),
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: session),
            ChangeNotifierProvider.value(value: build(api)),
          ],
          child: const MaterialApp(home: EditProfile()),
        ),
      );
      await tester.pump();
      return api;
    }

    testWidgets('a blocked save says why instead of doing nothing', (
      tester,
    ) async {
      // Placeholder email, as right after a cold start.
      session.setUser(_user(email: ''));
      final api = await pumpScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Old Road, Accra'),
        'New Street, Kumasi',
      );
      await tester.pump();
      // The user is down at the bottom button, with Name/Email out of view.
      final list = find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Save Changes'),
        300,
        scrollable: list,
      );
      await tester.pumpAndSettle();

      // On screen = below the pinned header and above the bottom edge.
      bool emailOnScreen() {
        final header = tester.getRect(
          find.descendant(
            of: find.byType(SliverAppBar),
            matching: find.byType(AppBar),
          ),
        );
        final label = tester.getRect(find.text('Email'));
        return label.top >= header.bottom &&
            label.bottom <=
                tester.view.physicalSize.height / tester.view.devicePixelRatio;
      }

      expect(emailOnScreen(), isFalse);

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Scrolled back to the field that blocked the save.
      expect(emailOnScreen(), isTrue);

      expect(find.text('Please fix the highlighted fields'), findsOneWidget);
      expect(find.text('Please enter your email address'), findsOneWidget);
      expect(api.requests, isEmpty);
    });
  });
}
