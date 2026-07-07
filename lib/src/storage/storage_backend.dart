import '../value.dart';

abstract interface class StorageBackend {
  ValueStorage<Map<String, dynamic>> get subject;

  Future<void> init([Map<String, dynamic>? initialData]);

  Future<void> flush();

  Future<void> deleteBox();

  T? read<T>(String key);

  Iterable<String> getKeys();

  Iterable<dynamic> getValues();

  void remove(String key);

  void write(String key, dynamic value);

  void clear();
}
