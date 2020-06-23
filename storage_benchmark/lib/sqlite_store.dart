import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class SqfliteStore {
  static const String TABLE_NAME_STR = "kv_str";
  static const String TABLE_NAME_INT = "kv_int";
  Database db;

  Future init() async {
    var dir = await getApplicationDocumentsDirectory();
    var dbPath = path.join(dir.path, 'sqlite.db');
    if (await File(dbPath).exists()) {
      await File(dbPath).delete();
    }
    db = await openDatabase(
      dbPath,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE $TABLE_NAME_STR (key TEXT PRIMARY KEY, value TEXT)',
        );
        await db.execute(
          'CREATE TABLE $TABLE_NAME_INT (key TEXT PRIMARY KEY, value INTEGER)',
        );
      },
      version: 1,
    );
  }

  Future<int> getInt(String key) async {
    var result = await db.query(
      TABLE_NAME_INT,
      where: "key = ?",
      whereArgs: [key],
    );
    return result[0]['value'] as int;
  }

  Future<void> putInts(Map<String, int> entries) async {
    await db.transaction((txn) async {
      final b = txn.batch();

      for (var key in entries.keys) {
        b.insert(
          TABLE_NAME_INT,
          {'key': key, 'value': entries[key]},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await b.commit();
    });
  }

  Future deleteInt(String key) {
    return db.delete(
      TABLE_NAME_INT,
      where: "key = ?",
      whereArgs: [key],
    );
  }

  Future<String> getString(String key) async {
    var result = await db.query(
      TABLE_NAME_STR,
      where: "key = ?",
      whereArgs: [key],
    );
    return result[0]['value'] as String;
  }

  Future<void> putStrings(Map<String, String> entries) async {
    await db.transaction((txn) async {
      final b = txn.batch();

      for (var key in entries.keys) {
        b.insert(
          TABLE_NAME_STR,
          {'key': key, 'value': entries[key]},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await b.commit();
    });
  }

  Future deleteString(String key) {
    return db.delete(
      TABLE_NAME_STR,
      where: "key = ?",
      whereArgs: [key],
    );
  }

  Future close() {
    return db.close();
  }
}
