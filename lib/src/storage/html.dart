import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import '../storage_interface.dart';
import '../value.dart';

class StorageImpl implements StorageInterface {
  StorageImpl(this.fileName, [this.path]);
  html.Storage get localStorage => html.window.localStorage;

  @override
  final String path, fileName;

  Value<Map<String, dynamic>> subject =
      Value<Map<String, dynamic>>(<String, dynamic>{});

  @override
  Future<void> clear() async {
    localStorage.remove(fileName);
    subject.value.clear();
  }

  @override
  Future<bool> exists() async {
    return localStorage != null && localStorage.containsKey(fileName);
  }

  @override
  Future<void> flush() {
    return _writeToStorage(subject.value);
  }

  @override
  T read<T>(String key) {
    return subject.value[key] as T;
  }

  @override
  Future<void> init([Map<String, dynamic> initialData]) async {
    subject.value = initialData ?? <String, dynamic>{};
    if (await exists()) {
      await _readFromStorage();
    } else {
      await _writeToStorage(subject.value);
    }
    return;
  }

  @override
  Future<void> remove(String key) {
    subject
      ..value.remove(key)
      ..update();
    return _writeToStorage(subject.value);
  }

  @override
  Future<void> write(String key, dynamic value) {
    subject
      ..value[key] = value
      ..update();
    return _writeToStorage(subject.value);
  }

  Future<void> _writeToStorage(Map<String, dynamic> data) async {
    localStorage.update(fileName, (val) => json.encode(subject.value),
        ifAbsent: () => json.encode(subject.value));
  }

  Future<void> _readFromStorage() async {
    final dataFromLocal = localStorage.entries.firstWhere(
      (value) {
        return value.key == fileName;
      },
      orElse: () => null,
    );
    if (dataFromLocal != null) {
      subject.value = json?.decode(dataFromLocal.value) as Map<String, dynamic>;
    } else {
      await _writeToStorage(<String, dynamic>{});
    }
  }
}
