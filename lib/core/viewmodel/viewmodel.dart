import 'package:flutter/material.dart';

abstract class ViewModel<T> extends ChangeNotifier {
  T _state;
  ViewModel(this._state);

  T get state => _state;

  void emit(T newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }
}
