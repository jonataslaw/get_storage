import 'package:get_storage/src/storage_impl.dart';

typedef StorageFactory = GetStorage Function();

class ReadWriteValue<T> {
  final String key;
  final T defaultValue;
  final StorageFactory getBox;
  final EncodeObject encoder;

  ReadWriteValue(
    this.key,
    this.defaultValue, [
    this.getBox,
    this.encoder,
  ]);

  T get val => (getBox() ?? GetStorage()).read(key) ?? defaultValue;
  set val(T newVal) => (getBox() ?? GetStorage()).write(key, newVal, encoder);
}

extension Data<T> on T {
  ReadWriteValue<T> val(
    String valueKey, {
    StorageFactory getBox,
    T defVal,
  }) {
    return ReadWriteValue(
      valueKey,
      defVal ?? this,
      getBox ?? () => GetStorage(),
    );
  }
}
