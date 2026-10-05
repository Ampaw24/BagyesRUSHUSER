import 'dart:async';

import 'package:flutter/widgets.dart';

/// Calls [onPoll] every [interval], but only while the poll is [active] (its
/// screen is the one being looked at) and the app is in the foreground.
///
/// Becoming active again — or returning to the app after at least one
/// interval in the background — polls straight away, so data never waits out
/// a fresh interval after the vendor comes back.
class ActivePoller with WidgetsBindingObserver {
  ActivePoller({
    required this.interval,
    required this.onPoll,
    @visibleForTesting DateTime Function() now = DateTime.now,
  }) : _now = now;

  final Duration interval;
  final VoidCallback onPoll;
  final DateTime Function() _now;

  Timer? _timer;
  bool _active = false;
  bool _foreground = true;
  DateTime? _backgroundedAt;

  /// Starts watching the app lifecycle and polling (no immediate poll — the
  /// caller loads its own initial data).
  void attach({required bool active}) {
    WidgetsBinding.instance.addObserver(this);
    _active = active;
    _sync();
  }

  /// Switches polling on/off as the screen is shown/hidden. Showing it again
  /// polls immediately.
  void setActive(bool active) {
    if (active == _active) return;
    _active = active;
    if (active) onPoll();
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final since = _backgroundedAt;
      _foreground = true;
      _backgroundedAt = null;
      if (_active && since != null && _now().difference(since) >= interval) {
        onPoll();
      }
    } else if (_foreground) {
      // inactive → paused arrive in sequence; the first one is the exit.
      _foreground = false;
      _backgroundedAt = _now();
    }
    _sync();
  }

  void _sync() {
    final shouldRun = _active && _foreground;
    if (shouldRun && _timer == null) {
      _timer = Timer.periodic(interval, (_) => onPoll());
    } else if (!shouldRun) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
  }
}
