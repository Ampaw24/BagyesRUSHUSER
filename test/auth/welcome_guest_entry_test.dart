import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/core/services/secure_storage_service.dart';
import 'package:bagyesrushappusernew/src/onboarding/services/onboarding_service.dart';
import 'package:bagyesrushappusernew/src/onboarding/viewmodels/onboarding_viewmodel.dart';
import 'package:bagyesrushappusernew/src/onboarding/views/onboarding_view.dart';

void main() {
  Future<void> pumpWelcome(WidgetTester tester, {required String start}) async {
    final router = GoRouter(
      initialLocation: start,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push(AppRoutes.onboarding),
              child: const Text('Guest home'),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, _) => const OnboardingView(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) =>
            OnboardingViewModel(OnboardingService(SecureStorageService())),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('entry welcome screen offers guest mode, which opens home',
      (tester) async {
    await pumpWelcome(tester, start: AppRoutes.onboarding);

    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
    await tester.ensureVisible(find.text('Continue as guest'));
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    expect(find.text('Guest home'), findsOneWidget);
  });

  testWidgets('opened from guest mode it offers back instead of guest entry',
      (tester) async {
    await pumpWelcome(tester, start: AppRoutes.home);
    await tester.tap(find.text('Guest home'));
    await tester.pumpAndSettle();

    expect(find.text('Continue as guest'), findsNothing);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Guest home'), findsOneWidget);
  });
}
