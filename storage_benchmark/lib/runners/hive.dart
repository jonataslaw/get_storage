import 'dart:io';

import 'package:hive/hive.dart';
import 'package:benchmark/runners/runner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class HiveRunner implements BenchmarkRunner {
  HiveRunner();

  @override
  String get name => 'Hive';

  @override
  Future<void> setUp() async {
    var dir = await getApplicationDocumentsDirectory();
    var homePath = path.join(dir.path, 'hive');
    if (await Directory(homePath).exists()) {
      await Directory(homePath).delete(recursive: true);
    }
    await Directory(homePath).create();
    Hive.init(homePath);
  }

  @override
  Future<void> tearDown() async {
    await Hive.close();
  }

  @override
  Future<int> batchReadInt(List<String> keys) async {
    final box = await Hive.openBox('box');
    final s = Stopwatch()..start();
    for (var key in keys) {
      box.get(key);
    }
    s.stop();
    await box.close();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchReadString(List<String> keys) {
    return batchReadInt(keys); // implementation is the same for hive
  }

  @override
  Future<int> batchWriteString(Map<String, dynamic> entries) async {
    var box = await Hive.openBox('box');
    var s = Stopwatch()..start();
    for (var key in entries.keys) {
      await box.put(key, entries[key]);
    }
    s.stop();
    await box.close();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchWriteInt(Map<String, int> entries) {
    return batchWriteString(entries);
  }

  @override
  Future<int> batchDeleteInt(List<String> keys) async {
    var box = await Hive.openBox('box');
    var s = Stopwatch()..start();
    for (var key in keys) {
      await box.delete(key);
    }
    s.stop();
    await box.close();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchDeleteString(List<String> keys) {
    return batchDeleteInt(keys);
  }
}
