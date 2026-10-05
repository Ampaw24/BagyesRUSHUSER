import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

abstract class ViewModel<T> extends ChangeNotifier {
  ViewModel(this._state);

  T _state;
  T get state => _state;

  bool _disposed = false;

  /// True once the owning screen (or provider) has disposed this view model.
  bool get isDisposed => _disposed;

  void emit(T newState) {
    if (_disposed) return;
    _state = newState;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
    } else {
      notifyListeners();
    }
  }

  /// A request that finishes after its screen was popped must not notify —
  /// that throws "used after being disposed". Guarding here also covers the
  /// deferred post-frame notify above and direct calls from subclasses.
  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
