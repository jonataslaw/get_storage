import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../value.dart';

class StorageImpl {
  StorageImpl(this.fileName, [this.path]);

  final String path, fileName;

  final ValueStorage<Map<String, dynamic>> subject =
      ValueStorage<Map<String, dynamic>>(<String, dynamic>{});

  Future<void> clear() async {
    File _file = await _getFile();
    subject
      ..value.clear()
      ..change("", null);
    subject.value.clear();
    return _file.deleteSync();
  }

  // Future<bool> _exists() async {
  //   File _file = await _getFile();
  //   return _file.existsSync();
  // }

  Future<void> flush() async {
    final serialized = json.encode(subject.value);
    File _file = await _getFile();
    await _file.writeAsString(serialized, flush: true);
    return;
  }

  T read<T>(String key) {
    return subject.value[key] as T;
  }

  T getKeys<T>() {
    return subject.value.keys as T;
  }

  T getValues<T>() {
    return subject.value.values as T;
  }

  Future<void> init([Map<String, dynamic> initialData]) async {
    subject.value = initialData ?? <String, dynamic>{};
    File _file = await _getFile();
    if (_file.existsSync()) {
      return _readFile();
    } else {
      return _writeFile(subject.value);
    }
  }

  Future<void> remove(String key) async {
    subject
      ..value.remove(key)
      ..change(key, null);
    await _writeFile(subject.value);
  }

  Future<void> write(String key, dynamic value) async {
    writeInMemory(key, value);
    await _writeFile(subject.value);
  }

  void writeInMemory(String key, dynamic value) {
    subject
      ..value[key] = value
      ..change(key, value);
  }

  Future<void> _writeFile(Map<String, dynamic> data) async {
    File _file = await _getFile();
    _file.writeAsString(json.encode(data), flush: true);
  }

  Future<void> _readFile() async {
    File _file = await _getFile();
    final content = await _file.readAsString()
      ..trim();
    subject.value =
        json?.decode(content == "" ? "{}" : content) as Map<String, dynamic>;
  }

  Future<File> _getFile() async {
    final dir = await _getDocumentDir();
    final _path = path ?? dir.path;
    final _file = File('$_path/$fileName.gs');
    return _file;
  }

  Future<Directory> _getDocumentDir() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (err) {
      throw err;
    }
  }
}
