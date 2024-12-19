import 'dart:async';

import 'package:flutter/widgets.dart';

import 'storage/html.dart' if (dart.library.io) 'storage/io.dart';
import 'value.dart';

/// Instantiate GetStorage to access storage driver apis
class GetStorage {
  factory GetStorage(
      [String container = 'GetStorage',
      String? path,
      Map<String, dynamic>? initialData]) {
    if (_sync.containsKey(container)) {
      return _sync[container]!;
    } else {
      final instance = GetStorage._internal(container, path, initialData);
      _sync[container] = instance;
      return instance;
    }
  }

  GetStorage._internal(String key,
      [String? path, Map<String, dynamic>? initialData]) {
    _concrete = StorageImpl(key, path);
    _initialData = initialData;

    initStorage = Future<bool>(() async {
      await _init();
      return true;
    });
  }

  static final Map<String, GetStorage> _sync = {};

  final microtask = Microtask();

  /// Start the storage drive. It's important to use await before calling this API, or side effects will occur.
  static Future<bool> init([String container = 'GetStorage']) {
    WidgetsFlutterBinding.ensureInitialized();
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
  T? read<T>(String key) {
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
  VoidCallback listen(VoidCallback value) {
    return _concrete.subject.addListener(value);
  }

  Map<Function, Function> _keyListeners = <Function, Function>{};

  VoidCallback listenKey(String key, ValueSetter callback) {
    final VoidCallback listen = () {
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
  Future<void> write(String key, dynamic value) async {
    writeInMemory(key, value);
    // final _encoded = json.encode(value);
    // await _concrete.write(key, json.decode(_encoded));

    return _tryFlush();
  }

  void writeInMemory(String key, dynamic value) {
    _concrete.write(key, value);
  }

  /// Write data on your only if data is null
  Future<void> writeIfNull(String key, dynamic value) async {
    if (read(key) != null) return;
    return write(key, value);
  }

  /// remove data from container by key
  Future<void> remove(String key) async {
    _concrete.remove(key);
    return _tryFlush();
  }

  /// clear all data on your container
  Future<void> erase() async {
    _concrete.clear();
    return _tryFlush();
  }

  Future<void> save() async {
    return _tryFlush();
  }

  Future<void> _tryFlush() async {
    return microtask.exec(_addToQueue);
  }

  Future _addToQueue() {
    return queue.add(_flush);
  }

  Future<void> _flush() async {
    try {
      await _concrete.flush();
    } catch (e) {
      rethrow;
    }
    return;
  }

  late StorageImpl _concrete;

  GetQueue queue = GetQueue();

  /// listenable of container
  ValueStorage<Map<String, dynamic>> get listenable => _concrete.subject;

  /// Start the storage drive. Important: use await before calling this api, or side effects will happen.
  late Future<bool> initStorage;

  Map<String, dynamic>? _initialData;
}

class Microtask {
  int _version = 0;
  int _microtask = 0;

  void exec(Function callback) {
    if (_microtask == _version) {
      _microtask++;
      scheduleMicrotask(() {
        _version++;
        _microtask = _version;
        callback();
      });
    }
  }
}

typedef KeyCallback = Function(String);

class GetQueue {
  final List<_Item> _queue = [];
  bool _active = false;

  Future<T> add<T>(Function job) {
    var completer = Completer<T>();
    _queue.add(_Item(completer, job));
    _check();
    return completer.future;
  }

  void cancelAllJobs() {
    _queue.clear();
  }

  void _check() async {
    if (!_active && _queue.isNotEmpty) {
      _active = true;
      var item = _queue.removeAt(0);
      try {
        item.completer.complete(await item.job());
      } on Exception catch (e) {
        item.completer.completeError(e);
      }
      _active = false;
      _check();
    }
  }
}

class _Item {
  final dynamic completer;
  final dynamic job;

  _Item(this.completer, this.job);
}
