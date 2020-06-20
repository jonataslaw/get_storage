import 'dart:math';

import 'package:benchmark/runners/hive.dart';
import 'package:benchmark/runners/moor_ffi.dart';
import 'package:benchmark/runners/runner.dart';
import 'package:benchmark/runners/shared_preferences.dart';
import 'package:benchmark/runners/sqflite.dart';
import 'package:random_string/random_string.dart' as randStr;

import 'runners/get_storage.dart';

const String TABLE_NAME_STR = "kv_str";
const String TABLE_NAME_INT = "kv_int";

class Result {
  final BenchmarkRunner runner;
  int intTime;
  int stringTime;

  Result(this.runner);
}

final runners = [
  GetStorageRunner(),
  HiveRunner(),
  SqfliteRunner(),
  SharedPreferencesRunner(),
  MoorFfiRunner(),
];

List<Result> _createResults() {
  return runners.map((r) => Result(r)).toList();
}

Map<String, int> generateIntEntries(int count) {
  var map = Map<String, int>();
  var random = Random();
  for (var i = 0; i < count; i++) {
    var key = randStr.randomAlphaNumeric(randStr.randomBetween(5, 200));
    var val = random.nextInt(2 ^ 50);
    map[key] = val;
  }
  return map;
}

Map<String, String> generateStringEntries(int count) {
  var map = Map<String, String>();
  for (var i = 0; i < count; i++) {
    var key = randStr.randomAlphaNumeric(randStr.randomBetween(5, 200));
    var val = randStr.randomString(randStr.randomBetween(5, 1000));
    map[key] = val;
  }
  return map;
}

Future<List<Result>> benchmarkRead(int count) async {
  var results = _createResults();

  var intEntries = generateIntEntries(count);
  var intKeys = intEntries.keys.toList()..shuffle();

  for (var result in results) {
    await result.runner.setUp();
    await result.runner.batchWriteInt(intEntries);
    result.intTime = await result.runner.batchReadInt(intKeys);
  }

  var stringEntries = generateStringEntries(count);
  var stringKeys = stringEntries.keys.toList()..shuffle();

  for (var result in results) {
    await result.runner.batchWriteString(stringEntries);
    result.stringTime = await result.runner.batchReadString(stringKeys);
  }

  for (var result in results) {
    await result.runner.tearDown();
  }

  return results;
}

Future<List<Result>> benchmarkWrite(int count) async {
  final results = _createResults();
  var intEntries = generateIntEntries(count);
  var stringEntries = generateStringEntries(count);

  for (var result in results) {
    await result.runner.setUp();
    result.intTime = await result.runner.batchWriteInt(intEntries);
    result.stringTime = await result.runner.batchWriteString(stringEntries);

    await result.runner.tearDown();
  }

  return results;
}

Future<List<Result>> benchmarkDelete(int count) async {
  final results = _createResults();

  var intEntries = generateIntEntries(count);
  var intKeys = intEntries.keys.toList()..shuffle();
  for (var result in results) {
    await result.runner.setUp();
    await result.runner.batchWriteInt(intEntries);
    result.intTime = await result.runner.batchDeleteInt(intKeys);
  }

  var stringEntries = generateStringEntries(count);
  var stringKeys = stringEntries.keys.toList()..shuffle();
  for (var result in results) {
    await result.runner.batchWriteString(stringEntries);
    result.stringTime = await result.runner.batchDeleteString(stringKeys);
  }

  for (var result in results) {
    await result.runner.tearDown();
  }

  return results;
}
