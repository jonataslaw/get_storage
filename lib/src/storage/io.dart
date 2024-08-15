import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../value.dart';

class StorageImpl {
  StorageImpl(this.fileName, [this.path]);

  final String? path;
  final String fileName;

  final ValueStorage<Map<String, dynamic>> subject =
      ValueStorage<Map<String, dynamic>>(<String, dynamic>{});

  RandomAccessFile? _randomAccessfile;

  void clear() async {
    subject
      ..value?.clear()
      ..changeValue("", null);
  }

  Future<void> deleteBox() async {
    final box = await _fileDb(isBackup: false);
    final backup = await _fileDb(isBackup: true);
    await Future.wait([box.delete(), backup.delete()]);
  }

  Future<void> flush() async {
    final buffer = utf8.encode(json.encode(subject.value));
    final length = buffer.length;
    RandomAccessFile _file = await _getRandomFile();

    _randomAccessfile = await _file.lock();
    _randomAccessfile = await _randomAccessfile!.setPosition(0);
    _randomAccessfile = await _randomAccessfile!.writeFrom(buffer);
    _randomAccessfile = await _randomAccessfile!.truncate(length);
    _randomAccessfile = await _file.unlock();
    _madeBackup();
  }

  void _madeBackup() {
    _getFile(true).then(
      (value) => value.writeAsString(
        json.encode(subject.value),
        flush: true,
      ),
    );
  }

  T? read<T>(String key) {
    return subject.value?[key] as T?;
  }

  T getKeys<T>() {
    return subject.value?.keys as T;
  }

  T getValues<T>() {
    return subject.value?.values as T;
  }

  Future<void> init([Map<String, dynamic>? initialData]) async {
    subject.value = initialData ?? <String, dynamic>{};

    RandomAccessFile _file = await _getRandomFile();
    return _file.lengthSync() == 0 ? flush() : _readFile();
  }

  void remove(String key) {
    subject
      ..value?.remove(key)
      ..changeValue(key, null);
  }

  void write(String key, dynamic value) {
    subject
      ..value?[key] = value
      ..changeValue(key, value);
  }

  Future<void> _readFile() async {
    try {
      RandomAccessFile _file = await _getRandomFile();
      _file = await _file.setPosition(0);
      final buffer = new Uint8List(await _file.length());
      await _file.readInto(buffer);
      subject.value = json.decode(utf8.decode(buffer));
    } catch (e) {
      Get.log('Corrupted box, recovering backup file', isError: true);
      final _file = await _getFile(true);

      final content = await _file.readAsString()
        ..trim();

      if (content.isEmpty) {
        subject.value = {};
      } else {
        try {
          subject.value = (json.decode(content) as Map<String, dynamic>?) ?? {};
        } catch (e) {
          Get.log('Can not recover Corrupted box', isError: true);
          subject.value = {};
        }
      }
      flush();
    }
  }

  Future<RandomAccessFile> _getRandomFile() async {
    if (_randomAccessfile != null) return _randomAccessfile!;
    final fileDb = await _getFile(false);
    _randomAccessfile = await fileDb.open(mode: FileMode.append);

    return _randomAccessfile!;
  }

  Future<File> _getFile(bool isBackup) async {
    final fileDb = await _fileDb(isBackup: isBackup);
    if (!fileDb.existsSync()) {
      fileDb.createSync(recursive: true);
    }
    return fileDb;
  }

  Future<File> _fileDb({required bool isBackup}) async {
    final pathStr = path ?? (await _getImplicitDir()).path;
    final _path = await _getPath(isBackup, pathStr);
    final _file = File(_path);
    return _file;
  }

  Future<Directory> _getImplicitDir() async {
    try {
      return getApplicationDocumentsDirectory();
    } catch (err) {
      throw err;
    }
  }

  Future<String> _getPath(bool isBackup, String? path) async {
    final _isWindows = GetPlatform.isWindows;
    final _separator = _isWindows ? '\\' : '/';
    return isBackup
        ? '$path$_separator$fileName.bak'
        : '$path$_separator$fileName.gs';
  }
}
