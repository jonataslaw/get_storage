import 'package:flutter/foundation.dart';

class Value<T> extends ValueNotifier<T> {
  Value(T value) : super(value);

  Map<String, dynamic> changes = <String, dynamic>{};

  void update(String key, int op, dynamic value) {
    if (hasListeners) changes = {key: value};
    notifyListeners();
  }
}
