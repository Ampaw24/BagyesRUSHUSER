import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/core/utils/active_poller.dart';

const _interval = Duration(seconds: 15);

void main() {
  late int polls;
  late DateTime clock;
  late ActivePoller poller;

  setUp(() {
    polls = 0;
    clock = DateTime(2026, 10, 5, 9);
    poller = ActivePoller(
      interval: _interval,
      onPoll: () => polls++,
      now: () => clock,
    );
  });

  /// Disposes the poller when the body ends — the framework checks for
  /// leftover timers before any tearDown runs.
  void pollerTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
      } finally {
        poller.dispose();
      }
    });
  }

  void background(WidgetTester tester) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  }

  void resume(WidgetTester tester) =>
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

  pollerTest('polls on the interval while active in the foreground', (tester) async {
    poller.attach(active: true);

    await tester.pump(_interval * 3);

    expect(polls, 3);
  });

  pollerTest('does not poll while its screen is hidden', (tester) async {
    poller.attach(active: false);

    await tester.pump(_interval * 4);

    expect(polls, 0);
  });

  pollerTest('showing the screen again polls straight away, then on schedule', (tester) async {
    poller.attach(active: false);
    await tester.pump(_interval * 2);

    poller.setActive(true);
    expect(polls, 1, reason: 'immediate refresh on return');

    await tester.pump(_interval);
    expect(polls, 2);
  });

  pollerTest('hiding the screen stops the timer', (tester) async {
    poller.attach(active: true);
    await tester.pump(_interval);
    expect(polls, 1);

    poller.setActive(false);
    await tester.pump(_interval * 4);

    expect(polls, 1);
  });

  pollerTest('stops in the background and refreshes on a long absence', (tester) async {
    poller.attach(active: true);

    background(tester);
    await tester.pump(_interval * 3);
    expect(polls, 0, reason: 'no polling while backgrounded');

    clock = clock.add(_interval * 3);
    resume(tester);
    expect(polls, 1, reason: 'refresh on return after a long absence');

    await tester.pump(_interval);
    expect(polls, 2, reason: 'timer running again');
  });

  pollerTest('a brief blip (e.g. a system dialog) does not refetch', (tester) async {
    poller.attach(active: true);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    clock = clock.add(const Duration(seconds: 2));
    resume(tester);

    expect(polls, 0);
  });

  pollerTest('returning to the app on another tab does not poll', (tester) async {
    poller.attach(active: false);

    background(tester);
    clock = clock.add(_interval * 3);
    resume(tester);
    await tester.pump(_interval * 2);

    expect(polls, 0);
  });

  pollerTest('dispose cancels the timer and stops listening', (tester) async {
    poller.attach(active: true);
    poller.dispose();

    await tester.pump(_interval * 3);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    expect(polls, 0);
  });
}
