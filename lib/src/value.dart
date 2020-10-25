import 'package:get/state_manager.dart';

class ValueStorage<T> extends Value<T> {
  ValueStorage(T value) : super(value);

  Map<String, dynamic> changes = <String, dynamic>{};

  void changeValue(String key, dynamic value) {
    changes = {key: value};
    refresh();
  }
}
