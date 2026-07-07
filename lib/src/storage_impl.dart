import 'dart:async';

import 'package:flutter/widgets.dart';

import 'storage/flush_scheduler.dart';
import 'storage/html.dart' if (dart.library.io) 'storage/io.dart';
import 'storage/storage_backend.dart';
import 'value.dart';

/// Instantiate GetStorage to access storage driver apis
final class GetStorage {
  factory GetStorage([
    String container = 'GetStorage',
    String? path,
    Map<String, dynamic>? initialData,
  ]) {
    return _sync.putIfAbsent(
      container,
      () => GetStorage._internal(container, path, initialData),
    );
  }

  GetStorage._internal(
    String key, [
    String? path,
    Map<String, dynamic>? initialData,
  ]) : _initialData = initialData {
    _concrete = StorageImpl(key, path);

    initStorage = Future<bool>(() async {
      await _init();
      return true;
    });
  }

  static final Map<String, GetStorage> _sync = {};

  final FlushScheduler _flushScheduler = FlushScheduler();

  /// Start the storage drive. It's important to use await before calling this API, or side effects will occur.
  static Future<bool> init([String container = 'GetStorage']) {
    WidgetsFlutterBinding.ensureInitialized();
    return GetStorage(container).initStorage;
  }

  Future<void> _init() async {
    await _concrete.init(_initialData);
  }

  /// Reads a value in your container with the given key.
  T? read<T>(String key) {
    return _concrete.read(key);
  }

  Iterable<String> getKeys() {
    return _concrete.getKeys();
  }

  Iterable<dynamic> getValues() {
    return _concrete.getValues();
  }

  /// return data true if value is different of null;
  bool hasData(String key) {
    return read<dynamic>(key) != null;
  }

  Map<String, dynamic> get changes => _concrete.subject.changes;

  /// Listen changes in your container
  VoidCallback listen(VoidCallback value) {
    return _concrete.subject.addListener(value);
  }

  final Map<Function, VoidCallback> _keyListeners = <Function, VoidCallback>{};

  VoidCallback listenKey(String key, ValueSetter<dynamic> callback) {
    final VoidCallback listen = () {
      final change = _concrete.subject.change;
      if (change case (key: final changedKey, value: final value) when changedKey == key) {
        callback(value);
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
  Future<void> write(String key, dynamic value) {
    writeInMemory(key, value);
    return _tryFlush();
  }

  void writeInMemory(String key, dynamic value) {
    _concrete.write(key, value);
  }

  /// Write data on your only if data is null
  Future<void> writeIfNull(String key, dynamic value) {
    if (read<dynamic>(key) != null) return Future<void>.value();
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
    return _flushScheduler.schedule(_flush);
  }

  Future<void> _flush() async {
    try {
      await _concrete.flush();
    } catch (e) {
      rethrow;
    }
    return;
  }

  late final StorageBackend _concrete;

  /// listenable of container
  ValueStorage<Map<String, dynamic>> get listenable => _concrete.subject;

  /// Start the storage drive. Important: use await before calling this api, or side effects will happen.
  late final Future<bool> initStorage;

  final Map<String, dynamic>? _initialData;
}

@Deprecated('Use FlushScheduler instead. This compatibility type will be removed in a future release.')
final class Microtask {
  int _version = 0;
  int _microtask = 0;

  void exec(void Function() callback) {
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

typedef KeyCallback = void Function(String key);
