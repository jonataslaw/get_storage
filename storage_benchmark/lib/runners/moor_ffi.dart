import 'dart:io';

import 'package:benchmark/runners/runner.dart';
import 'package:moor_ffi/database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../benchmark.dart';

class MoorFfiRunner implements BenchmarkRunner {
  @override
  String get name => 'Moor';

  Database db;

  @override
  Future<void> setUp() async {
    var dir = await getApplicationDocumentsDirectory();
    var homePath = path.join(dir.path, 'ffi.db');
    final file = File(homePath);

    if (await file.exists()) {
      await file.delete();
    }

    db = Database.openFile(file);

    db.execute(
        'CREATE TABLE $TABLE_NAME_STR (key TEXT PRIMARY KEY, value TEXT)');
    db.execute(
        'CREATE TABLE $TABLE_NAME_INT (key TEXT PRIMARY KEY, value INTEGER)');
  }

  @override
  Future<void> tearDown() async {
    db.close();
  }

  Future<int> _batchRead(String table, List<String> keys) async {
    var s = Stopwatch()..start();
    final stmt = db.prepare('SELECT * FROM $table WHERE key = ?');

    for (var key in keys) {
      final result = stmt.select([key]);
      // read all rows because that would be required during a real read
      result.forEach((row) => row['value']);
    }

    s.stop();
    stmt.close();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchReadInt(List<String> keys) async {
    return _batchRead(TABLE_NAME_INT, keys);
  }

  @override
  Future<int> batchReadString(List<String> keys) {
    return _batchRead(TABLE_NAME_STR, keys);
  }

  @override
  Future<int> batchWriteInt(Map<String, int> entries) async {
    var s = Stopwatch()..start();
    final stmt = db.prepare(
        'INSERT OR REPLACE INTO $TABLE_NAME_INT (key, value) VALUES (?, ?)');

    entries.forEach((key, value) {
      stmt.execute([key, value]);
    });

    stmt.close();
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchWriteString(Map<String, String> entries) async {
    var s = Stopwatch()..start();
    final stmt = db.prepare(
        'INSERT OR REPLACE INTO $TABLE_NAME_STR (key, value) VALUES (?, ?)');

    entries.forEach((key, value) {
      stmt.execute([key, value]);
    });

    stmt.close();
    s.stop();
    return s.elapsedMilliseconds;
  }

  Future<int> _deleteFromTable(String table, List<String> keys) async {
    var s = Stopwatch()..start();
    final stmt = db.prepare('DELETE FROM $table WHERE key = ?');

    for (var key in keys) {
      stmt.execute([key]);
    }

    stmt.close();
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchDeleteInt(List<String> keys) {
    return _deleteFromTable(TABLE_NAME_INT, keys);
  }

  @override
  Future<int> batchDeleteString(List<String> keys) {
    return _deleteFromTable(TABLE_NAME_STR, keys);
  }
}
