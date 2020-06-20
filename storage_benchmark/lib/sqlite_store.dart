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

  Future putInt(String key, int value) {
    return db.insert(
      TABLE_NAME_INT,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

  Future putString(String key, String value) {
    return db.insert(
      TABLE_NAME_STR,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
