import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'storage/html.dart' if (dart.library.io) 'storage/io.dart';
import 'value.dart';

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
    } catch (err) {
      throw err;
    }
  }

  /// Reads a value in your container with the given key.
  T read<T>(String key) {
    return _concrete.read(key);
  }

  T getKeys<T>() {
    return _concrete.getKeys();
  }

  T getValues<T>() {
    return _concrete.getValues();
  }

  /// return data true if value is different of null;
  bool hasData(String key) {
    return (read(key) == null ? false : true);
  }

  Map<String, dynamic> get changes => _concrete.subject.changes;

  /// Listen changes in your container
  Disposer listen(void Function() value) {
    return _concrete.subject.addListener((e) => value);
  }

  Map<Function, Function> _keyListeners = <Function, Function>{};

  Disposer listenKey(String key, Function(dynamic) callback) {
    final listen = (e) {
      if (changes.keys.first == key) {
        callback(changes[key]);
      }
    };

    _keyListeners[callback] = listen;
    return _concrete.subject.addListener(listen);
  }

  // /// Remove listen of your container
  // void removeKeyListen(Function(Map<String, dynamic>) callback) {
  //   _concrete.subject.removeListener(_keyListeners[callback]);
  // }

  // /// Remove listen of your container
  // void removeListen(void Function() listener) {
  //   _concrete.subject.removeListener(listener);
  // }

  /// Write data on your container
  Future<void> write(String key, dynamic value,
      [EncodeObject objectToEncode]) async {
    final _encoded =
        json.encode(objectToEncode != null ? objectToEncode(value) : value);
    await _concrete.write(key, json.decode(_encoded));

    return _tryFlush();
  }

  void writeInMemory(String key, dynamic value) {
    _concrete.writeInMemory(key, value);
  }

  /// Write data on your only if data is null
  Future<void> writeIfNull(String key, dynamic value,
      [EncodeObject objectToEncode]) async {
    if (read(key) != null) return;
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

  Future<void> save() async {
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

  /// listenable of container
  ValueStorage<Map<String, dynamic>> get listenable => _concrete.subject;

  /// Start the storage drive. Importate: use await before calling this api, or side effects will happen.
  Future<bool> initStorage;

  Future<void> _lockDatabase;

  Map<String, dynamic> _initialData;
}

typedef EncodeObject = Object Function(Object);

typedef KeyCallback = Function(String);
