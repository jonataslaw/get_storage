import 'package:flutter/foundation.dart';

class Value<T> extends ValueNotifier<T> {
  Value(T value) : super(value);

  void update() {
    notifyListeners();
  }
}
