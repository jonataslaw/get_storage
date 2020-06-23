import 'package:get_storage/get_storage.dart';
import 'package:benchmark/runners/runner.dart';

class GetStorageRunner implements BenchmarkRunner {
  GetStorage prefs = GetStorage();

  @override
  String get name => 'GS';

  @override
  Future<void> setUp() async {
    await GetStorage.init();
  }

  @override
  Future<void> tearDown() async {
    await prefs.erase();
  }

  @override
  Future<int> batchReadInt(List<String> keys) async {
    var s = Stopwatch()..start();
    for (var key in keys) {
      prefs.read(key);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchReadString(List<String> keys) async {
    var s = Stopwatch()..start();
    for (var key in keys) {
      prefs.read(key);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchWriteInt(Map<String, int> entries) async {
    var s = Stopwatch()..start();
    for (var key in entries.keys) {
      prefs.writeInMemory(key, entries[key]);
    }

    await prefs.save();

    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchWriteString(Map<String, String> entries) async {
    var s = Stopwatch()..start();
    for (var key in entries.keys) {
      prefs.writeInMemory(key, entries[key]);
    }

    await prefs.save();

    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchDeleteInt(List<String> keys) async {
    var s = Stopwatch()..start();
    for (var key in keys) {
      prefs.remove(key);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchDeleteString(List<String> keys) {
    return batchDeleteInt(keys);
  }
}
