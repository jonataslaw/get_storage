import 'dart:async';

abstract class StorageInterface {
  StorageInterface(this.fileName, [this.path]);

  final String path, fileName;

  Future<void> init([Map<String, dynamic> initialData]);

  T read<T>(String key);

  Future<bool> exists();

  Future<void> write(String key, dynamic value);

  Future<void> clear();

  Future<void> remove(String key);

  Future<void> flush();
}
