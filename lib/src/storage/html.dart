import 'package:web/web.dart' as web;

import '../value.dart';
import 'storage_backend.dart';
import 'storage_codec.dart';

final class StorageImpl implements StorageBackend {
  StorageImpl(this.fileName, [this.path]);

  web.Storage get localStorage => web.window.localStorage;

  final String? path;
  final String fileName;
  final StorageCodec _codec = const JsonStorageCodec();

  @override
  final ValueStorage<Map<String, dynamic>> subject = ValueStorage<Map<String, dynamic>>(<String, dynamic>{});

  @override
  void clear() {
    localStorage.removeItem(fileName);
    subject.value.clear();

    subject
      ..value.clear()
      ..changeValue("", null);
  }

  @override
  Future<void> deleteBox() async {
    localStorage.removeItem(fileName);
  }

  @override
  Future<void> flush() {
    return _writeToStorage(subject.value);
  }

  @override
  T? read<T>(String key) {
    final value = subject.value[key];
    return value is T ? value : null;
  }

  @override
  Iterable<String> getKeys() {
    return subject.value.keys;
  }

  @override
  Iterable<dynamic> getValues() {
    return subject.value.values;
  }

  @override
  Future<void> init([Map<String, dynamic>? initialData]) async {
    subject.value = initialData ?? <String, dynamic>{};
    final source = localStorage.getItem(fileName);
    if (source == null) {
      await _writeToStorage(subject.value);
    } else {
      _readFromStorage(source);
    }
  }

  @override
  void remove(String key) {
    subject
      ..value.remove(key)
      ..changeValue(key, null);
  }

  @override
  void write(String key, dynamic value) {
    subject
      ..value[key] = value
      ..changeValue(key, value);
  }

  Future<void> _writeToStorage(Map<String, dynamic> data) async {
    localStorage.setItem(fileName, _codec.encode(data));
  }

  void _readFromStorage(String source) {
    subject.value = _codec.decode(source);
  }
}
