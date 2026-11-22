import 'package:flutter/widgets.dart';
import 'package:get/state_manager.dart';

class ValueStorage<T> {
  ValueStorage(T value) : this._value = Value(value);

  final Value _value;

  Map<String, dynamic> changes = <String, dynamic>{};

  void changeValue(String key, dynamic value) {
    changes = {key: value};
    // ignore: invalid_use_of_protected_member
    _value.refresh();
  }

  T get value => _value.value;

  set value(T value) {
    _value.value = value;
  }

  VoidCallback addListener(VoidCallback callback) {
    _value.addListener(callback);

    return () => _value.removeListener(callback);
  }
}
