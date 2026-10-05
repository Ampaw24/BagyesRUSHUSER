import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/constant/config.dart';
import 'package:bagyesrushappusernew/core/widgets/config_error_app.dart';

void main() {
  test('Config.validate names the flag when API_BASE_URL is missing', () {
    // `flutter test` runs without the dart-defines, like a bare IDE run.
    expect(
      Config.validate,
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('--dart-define-from-file=env/app.json'),
        ),
      ),
    );
  });

  testWidgets('shows the cause on screen instead of stalling', (tester) async {
    await tester.pumpWidget(const ConfigErrorApp(message: 'Run with the flag.'));

    expect(find.text('App configuration missing'), findsOneWidget);
    expect(find.text('Run with the flag.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
