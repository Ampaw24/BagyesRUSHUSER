import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gopady/core/widgets/keyboard_dismisser.dart';

void main() {
  late FocusNode field;
  late FocusNode other;
  var buttonTaps = 0;

  Widget app() => MaterialApp(
        builder: (context, child) => KeyboardDismisser(child: child!),
        home: Scaffold(
          body: ListView(
            children: [
              TextField(key: const Key('field'), focusNode: field),
              TextField(key: const Key('other'), focusNode: other),
              ElevatedButton(
                key: const Key('button'),
                onPressed: () => buttonTaps++,
                child: const Text('Tap'),
              ),
              TextFieldTapRegion(
                child: IconButton(
                  key: const Key('send'),
                  onPressed: () {},
                  icon: const Icon(Icons.send),
                ),
              ),
              const SizedBox(key: Key('empty'), height: 1500),
            ],
          ),
        ),
      );

  setUp(() {
    field = FocusNode();
    other = FocusNode();
    buttonTaps = 0;
  });
  tearDown(() {
    field.dispose();
    other.dispose();
  });

  Future<void> focusField(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();
    expect(field.hasFocus, isTrue);
  }

  testWidgets('tapping empty space closes the keyboard', (tester) async {
    await focusField(tester);
    await tester.tapAt(
      tester.getTopLeft(find.byKey(const Key('empty'))) + const Offset(40, 40),
    );
    await tester.pump();
    expect(field.hasFocus, isFalse);
  });

  testWidgets('tapping a button closes the keyboard and still presses it',
      (tester) async {
    await focusField(tester);
    await tester.tap(find.byKey(const Key('button')));
    await tester.pump();
    expect(field.hasFocus, isFalse);
    expect(buttonTaps, 1);
  });

  testWidgets('scrolling keeps the keyboard open', (tester) async {
    await focusField(tester);
    await tester.drag(find.byKey(const Key('empty')), const Offset(0, -200));
    await tester.pump();
    expect(field.hasFocus, isTrue);
  });

  testWidgets('tapping another field moves focus to it', (tester) async {
    await focusField(tester);
    await tester.tap(find.byKey(const Key('other')));
    await tester.pump();
    expect(other.hasFocus, isTrue);
  });

  testWidgets('a control inside the field tap region keeps focus',
      (tester) async {
    await focusField(tester);
    await tester.tap(find.byKey(const Key('send')));
    await tester.pump();
    expect(field.hasFocus, isTrue);
  });
}
