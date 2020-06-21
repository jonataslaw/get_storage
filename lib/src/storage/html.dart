import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import '../value.dart';

class StorageImpl {
  StorageImpl(this.fileName, [this.path]);
  html.Storage get localStorage => html.window.localStorage;

  final String path, fileName;

  Value<Map<String, dynamic>> subject =
      Value<Map<String, dynamic>>(<String, dynamic>{});

  Future<void> clear() async {
    localStorage.remove(fileName);
    subject.value.clear();

    subject
      ..value.clear()
      ..update("", 2, null);
  }

  Future<bool> _exists() async {
    return localStorage != null && localStorage.containsKey(fileName);
  }

  Future<void> flush() {
    return _writeToStorage(subject.value);
  }

  T read<T>(String key) {
    return subject.value[key] as T;
  }

  Future<void> init([Map<String, dynamic> initialData]) async {
    subject.value = initialData ?? <String, dynamic>{};
    if (await _exists()) {
      await _readFromStorage();
    } else {
      await _writeToStorage(subject.value);
    }
    return;
  }

  Future<void> remove(String key) {
    subject
      ..value.remove(key)
      ..update(key, 1, null);
    return _writeToStorage(subject.value);
  }

  Future<void> write(String key, dynamic value) {
    subject
      ..value[key] = value
      ..update(key, 0, value);
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
