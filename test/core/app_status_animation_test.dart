import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

import 'package:gopady/core/widgets/app_status_animation.dart';

Widget _host(Widget child, {Size size = const Size(390, 844), bool reduceMotion = false}) {
  return MediaQuery(
    data: MediaQueryData(size: size, disableAnimations: reduceMotion),
    child: MaterialApp(home: Scaffold(body: Center(child: child))),
  );
}

/// Lets the asset load and the composition parse, then settles a frame.
Future<void> _load(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump();
}

AnimationController _controllerOf(WidgetTester tester) =>
    tester.widget<Lottie>(find.byType(Lottie)).controller! as AnimationController;

void main() {
  group('brand Lottie assets', () {
    const expected = {
      AppStatus.success: Duration(milliseconds: 1600),
      AppStatus.error: Duration(milliseconds: 1600),
      AppStatus.warning: Duration(milliseconds: 1600),
      AppStatus.info: Duration(milliseconds: 1600),
      AppStatus.processing: Duration(milliseconds: 1200),
      AppStatus.searching: Duration(milliseconds: 2000),
    };

    for (final status in AppStatus.values) {
      test('${status.name} parses as a 200×200 composition', () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        final data = await rootBundle.load(status.asset);
        final composition = await LottieComposition.fromByteData(data);
        expect([composition.bounds.width, composition.bounds.height], [200, 200]);
        expect(composition.duration, expected[status]);
      });
    }
  });

  group('AppStatusAnimation', () {
    testWidgets('one-shot plays through and reports completion once', (tester) async {
      var completions = 0;
      await tester.pumpWidget(_host(
        AppStatusAnimation(AppStatus.success, onCompleted: () => completions++),
      ));
      await _load(tester);

      final controller = _controllerOf(tester);
      expect(controller.isAnimating, isTrue);
      await tester.pump(const Duration(milliseconds: 1700));
      expect(controller.value, 1);
      expect(completions, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(completions, 1);
    });

    testWidgets('looping statuses keep running', (tester) async {
      await tester.pumpWidget(_host(const AppStatusAnimation(AppStatus.processing)));
      await _load(tester);

      final controller = _controllerOf(tester);
      await tester.pump(const Duration(seconds: 5));
      expect(controller.isAnimating, isTrue);
      // Replace the looping widget so the test can end cleanly.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('reduce motion lands on the final frame without animating', (tester) async {
      var completions = 0;
      await tester.pumpWidget(_host(
        AppStatusAnimation(AppStatus.error, onCompleted: () => completions++),
        reduceMotion: true,
      ));
      await _load(tester);

      final controller = _controllerOf(tester);
      expect(controller.isAnimating, isFalse);
      expect(controller.value, 1);
      expect(completions, 1);
    });

    testWidgets('reduce motion holds a loop still', (tester) async {
      await tester.pumpWidget(_host(
        const AppStatusAnimation(AppStatus.searching),
        reduceMotion: true,
      ));
      await _load(tester);
      expect(_controllerOf(tester).isAnimating, isFalse);
    });

    testWidgets('waits for the delay before playing', (tester) async {
      await tester.pumpWidget(_host(
        const AppStatusAnimation(AppStatus.info, delay: Duration(milliseconds: 300)),
      ));
      await _load(tester);
      expect(_controllerOf(tester).isAnimating, isFalse);
      await tester.pump(const Duration(milliseconds: 320));
      expect(_controllerOf(tester).isAnimating, isTrue);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('switching status restarts with the new animation', (tester) async {
      final status = ValueNotifier(AppStatus.processing);
      await tester.pumpWidget(_host(ValueListenableBuilder(
        valueListenable: status,
        builder: (_, value, _) => AppStatusAnimation(value),
      )));
      await _load(tester);
      status.value = AppStatus.success;
      await tester.pump();
      await _load(tester);

      final controller = _controllerOf(tester);
      await tester.pump(const Duration(milliseconds: 1700));
      expect(controller.value, 1);
      expect(controller.isAnimating, isFalse);
    });

    testWidgets('sizes from the shortest side and clamps on large screens', (tester) async {
      await tester.pumpWidget(_host(const AppStatusAnimation(AppStatus.warning)));
      expect(tester.getSize(find.byType(AppStatusAnimation)), const Size.square(390 * 0.28));

      await tester.pumpWidget(_host(
        const AppStatusAnimation(AppStatus.warning),
        size: const Size(1366, 1024),
      ));
      expect(tester.getSize(find.byType(AppStatusAnimation)), const Size.square(200));

      await tester.pumpWidget(_host(const AppStatusAnimation(AppStatus.warning, size: 64)));
      expect(tester.getSize(find.byType(AppStatusAnimation)), const Size.square(64));
      await _load(tester);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('exposes a semantic label', (tester) async {
      await tester.pumpWidget(_host(
        const AppStatusAnimation(AppStatus.success, semanticLabel: 'Payment successful'),
      ));
      expect(find.bySemanticsLabel('Payment successful'), findsOneWidget);
      await _load(tester);
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('AppStatusView', () {
    testWidgets('shows title, message and action', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_host(AppStatusView(
        status: AppStatus.error,
        title: 'Couldn\'t load',
        message: 'Check your connection.',
        actionLabel: 'Retry',
        onAction: () => tapped = true,
      )));
      await _load(tester);
      expect(find.text('Couldn\'t load'), findsOneWidget);
      expect(find.text('Check your connection.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(tapped, isTrue);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('omits the button without an action', (tester) async {
      await tester.pumpWidget(_host(
        const AppStatusView(status: AppStatus.info, title: 'Nothing here', actionLabel: 'Go'),
      ));
      expect(find.byType(FilledButton), findsNothing);
      await _load(tester);
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
