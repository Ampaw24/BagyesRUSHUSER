import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';

class _CounterViewModel extends ViewModel<int> {
  _CounterViewModel() : super(0);

  void notifyDirectly() => notifyListeners();
}

void main() {
  testWidgets('a request finishing after the screen is gone does not throw',
      (tester) async {
    final vm = _CounterViewModel();
    var notifications = 0;
    vm
      ..addListener(() => notifications++)
      ..dispose();

    vm.emit(1);
    vm.notifyDirectly();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(notifications, 0);
    expect(vm.isDisposed, isTrue);
    
  });

  testWidgets(
      'emit during build, then dispose before the deferred notify, is safe',
      (tester) async {
    final vm = _CounterViewModel();

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          // Emitting while the framework is building defers the notify to a
          // post-frame callback; dispose lands before it runs.
          vm
            ..emit(1)
            ..dispose();
          return const SizedBox.shrink();
        },
      ),
    );

    expect(tester.takeException(), isNull);
  });

  test('a live view model still notifies listeners', () {
    final vm = _CounterViewModel();
    var notifications = 0;
    vm.addListener(() => notifications++);

    vm
      ..emit(1)
      ..emit(2);

    expect(vm.state, 2);
    expect(notifications, 2);
    vm.dispose();
  });
}
