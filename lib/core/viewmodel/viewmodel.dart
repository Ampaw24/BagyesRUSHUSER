import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

abstract class ViewModel<T> extends ChangeNotifier {
  ViewModel(this._state);

  T _state;
  T get state => _state;

  void emit(T newState) {
    _state = newState;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }
}
