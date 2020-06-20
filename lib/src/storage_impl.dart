import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'storage/html.dart' if (dart.library.io) 'storage/io.dart';

/// Instantiate GetStorage to access storage driver apis
class GetStorage {
  factory GetStorage(
      [String container = 'GetStorage',
      String path,
      Map<String, dynamic> initialData]) {
    if (_sync.containsKey(container)) {
      return _sync[container];
    } else {
      final instance = GetStorage._internal(container, path, initialData);
      _sync[container] = instance;
      return instance;
    }
  }

  GetStorage._internal(String key,
      [String path, Map<String, dynamic> initialData]) {
    _concrete = StorageImpl(key, path);
    _initialData = initialData;

    initStorage = Future<bool>(() async {
      await _init();
      return true;
    });
  }

  static final Map<String, GetStorage> _sync = {};

  /// Start the storage drive. Importate: use await before calling this api, or side effects will happen.
  static Future<bool> init([String container = 'GetStorage']) {
    WidgetsFlutterBinding.ensureInitialized();
    if (container == null) {
      throw 'key can not be null';
    }
    return GetStorage(container).initStorage;
  }

  Future<void> _init() async {
    try {
      await _concrete.init(_initialData);
    } on Error catch (err) {
      throw err;
    }
  }

  /// Reads a value in your container with the given key.
  T read<T>(String key) {
    return _concrete.read(key);
  }

  /// Listen changes in your container
  void listen(void Function() value) {
    _concrete.subject.addListener(value);
  }

  /// Remove listen of your container
  void removeListen(void Function() listener) {
    _concrete.subject.removeListener(listener);
  }

  /// Write data on your container
  Future<void> write(String key, dynamic value,
      [EncodeObject objectToEncode]) async {
    final _encoded =
        json.encode(objectToEncode != null ? objectToEncode(value) : value);
    await _concrete.write(key, json.decode(_encoded));

    return _tryFlush();
  }

  /// remove data from container by key
  Future<void> remove(String key) async {
    await _concrete.remove(key);
    return _tryFlush();
  }

  /// clear all data on your container
  Future<void> erase() async {
    await _concrete.clear();
    return _tryFlush();
  }

  Future<void> _tryFlush() async {
    if (_lockDatabase != null) {
      await _lockDatabase;
    }
    _lockDatabase = _flush();
    return _lockDatabase;
  }

  Future<void> _flush() async {
    try {
      await _concrete.flush();
    } catch (e) {
      rethrow;
    }
    return;
  }

  StorageImpl _concrete;

  /// Start the storage drive. Importate: use await before calling this api, or side effects will happen.
  Future<bool> initStorage;

  Future<void> _lockDatabase;

  Map<String, dynamic> _initialData;
}

typedef EncodeObject = Object Function(Object);
