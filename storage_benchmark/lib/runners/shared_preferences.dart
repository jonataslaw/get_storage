import 'package:benchmark/runners/runner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesRunner implements BenchmarkRunner {
  SharedPreferences prefs;

  @override
  String get name => 'SP';

  @override
  Future<void> setUp() async {
    prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  @override
  Future<void> tearDown() async {
    // nothing to do here, cleared in setUp
  }

  @override
  Future<int> batchReadInt(List<String> keys) async {
    var prefs = await SharedPreferences.getInstance();
    var s = Stopwatch()..start();
    for (var key in keys) {
      prefs.getInt(key);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchReadString(List<String> keys) async {
    var prefs = await SharedPreferences.getInstance();
    var s = Stopwatch()..start();
    for (var key in keys) {
      prefs.getString(key);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchWriteInt(Map<String, int> entries) async {
    var s = Stopwatch()..start();
    var prefs = await SharedPreferences.getInstance();
    for (var key in entries.keys) {
      await prefs.setInt(key, entries[key]);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchWriteString(Map<String, String> entries) async {
    var s = Stopwatch()..start();
    var prefs = await SharedPreferences.getInstance();
    for (var key in entries.keys) {
      await prefs.setString(key, entries[key]);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchDeleteInt(List<String> keys) async {
    var s = Stopwatch()..start();
    var prefs = await SharedPreferences.getInstance();
    for (var key in keys) {
      await prefs.remove(key);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchDeleteString(List<String> keys) {
    return batchDeleteInt(keys);
  }
}
