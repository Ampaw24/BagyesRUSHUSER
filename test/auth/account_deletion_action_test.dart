import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gopady/core/router/app_routes.dart';
import 'package:gopady/src/auth/views/account_deletion_action.dart';
import 'package:gopady/src/legal/models/legal_document.dart';

/// Account deletion happens on the GoPady website; the app only warns the
/// user and opens that page in its legal web view.
Future<void> _pumpPrompt(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => confirmAccountDeletion(context),
            child: const Text('Delete Account'),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.deleteAccount,
        builder: (_, _) => const Scaffold(body: Text('Deletion page')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.tap(find.text('Delete Account'));
  await tester.pumpAndSettle();
}

void main() {
  test('the deletion page is the website one, under the legal routes', () {
    expect(
      LegalDocument.deleteAccount.url,
      'https://gopady.com/delete-account',
    );
    expect(LegalDocument.deleteAccount.routePath, AppRoutes.deleteAccount);
  });

  testWidgets('Continue opens the website deletion page', (tester) async {
    await _pumpPrompt(tester);
    expect(find.textContaining('GoPady website'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Deletion page'), findsOneWidget);
  });

  testWidgets('Cancel stays put', (tester) async {
    await _pumpPrompt(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Deletion page'), findsNothing);
    expect(find.text('Delete Account'), findsOneWidget);
  });
}
