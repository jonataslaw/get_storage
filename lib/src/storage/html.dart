import 'dart:async';
import 'dart:convert';
import 'package:web/web.dart' as html;

import '../value.dart';

class StorageImpl {
  StorageImpl(this.fileName, [this.path]);
  html.Storage get localStorage => html.window.localStorage;

  final String? path;
  final String fileName;

  ValueStorage<Map<String, dynamic>> subject =
      ValueStorage<Map<String, dynamic>>(<String, dynamic>{});

  void clear() {
    localStorage.removeItem(fileName);
    subject.value.clear();

    subject
      ..value.clear()
      ..changeValue("", null);
  }

  Future<void> flush() {
    return _writeToStorage(subject.value);
  }

  T? read<T>(String key) {
    return subject.value[key] as T?;
  }

  T getKeys<T>() {
    return subject.value.keys as T;
  }

  T getValues<T>() {
    return subject.value.values as T;
  }

  Future<void> init([Map<String, dynamic>? initialData]) async {
    subject.value = initialData ?? <String, dynamic>{};
    final dataFromLocal = localStorage.getItem(fileName);
    if (dataFromLocal != null) {
      subject.value = json.decode(dataFromLocal) as Map<String, dynamic>;
    } else {
      await _writeToStorage(subject.value);
    }
    return;
  }

  void remove(String key) {
    subject
      ..value.remove(key)
      ..changeValue(key, null);
    //  return _writeToStorage(subject.value);
  }

  void write(String key, dynamic value) {
    subject
      ..value[key] = value
      ..changeValue(key, value);
    //return _writeToStorage(subject.value);
  }

  // void writeInMemory(String key, dynamic value) {

  // }

  Future<void> _writeToStorage(Map<String, dynamic> data) async {
    localStorage.setItem(fileName, json.encode(subject.value));
  }
}
