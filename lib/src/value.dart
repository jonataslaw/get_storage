import 'package:flutter/foundation.dart';

import 'storage_change.dart';

final class ValueStorage<T> {
  ValueStorage(T value) : _value = value;

  final _StorageNotifier _notifier = _StorageNotifier();
  T _value;

  Map<String, dynamic> changes = <String, dynamic>{};

  StorageChange? change;

  void changeValue(String key, dynamic value) {
    change = (key: key, value: value);
    changes = <String, dynamic>{key: value,};
    _notifier.notify();
  }

  T get value => _value;

  set value(T value) {
    _value = value;
  }

  VoidCallback addListener(VoidCallback callback) {
    _notifier.addListener(callback);

    return () => _notifier.removeListener(callback);
  }
}

final class _StorageNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}
