import 'package:get/state_manager.dart';

class ValueStorage<T> extends Value<T> {
  ValueStorage(super.value);

  Map<String, dynamic> changes = {};

  void changeValue(String key, dynamic value) {
    changes = {key: value};
    refresh();
  }
}
