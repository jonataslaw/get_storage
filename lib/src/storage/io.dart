import 'dart:developer' as developer;
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../value.dart';
import 'storage_backend.dart';
import 'storage_codec.dart';

final class StorageImpl implements StorageBackend {
  StorageImpl(this.fileName, [this.path]);

  final String? path;
  final String fileName;
  final StorageCodec _codec = const JsonStorageCodec();

  @override
  final ValueStorage<Map<String, dynamic>> subject = ValueStorage<Map<String, dynamic>>(<String, dynamic>{});

  @override
  void clear() {
    subject
      ..value.clear()
      ..changeValue("", null);
  }

  @override
  Future<void> deleteBox() async {
    final box = await _fileDb(isBackup: false);
    final backup = await _fileDb(isBackup: true);
    await Future.wait(<Future<void>>[_deleteIfExists(box), _deleteIfExists(backup)]);
  }

  @override
  Future<void> flush() async {
    final encoded = _codec.encode(subject.value);
    final box = await _getFile(false);
    final backup = await _getFile(true);

    await _writeAtomically(box, encoded);
    await _writeAtomically(backup, encoded);
  }

  @override
  T? read<T>(String key) {
    final value = subject.value[key];
    return value is T ? value : null;
  }

  @override
  Iterable<String> getKeys() {
    return subject.value.keys;
  }

  @override
  Iterable<dynamic> getValues() {
    return subject.value.values;
  }

  @override
  Future<void> init([Map<String, dynamic>? initialData]) async {
    subject.value = initialData ?? <String, dynamic>{};

    final file = await _getFile(false);
    if (!await file.exists() || await file.length() == 0) {
      return flush();
    }

    return _readFile();
  }

  @override
  void remove(String key) {
    subject
      ..value.remove(key)
      ..changeValue(key, null);
  }

  @override
  void write(String key, dynamic value) {
    subject
      ..value[key] = value
      ..changeValue(key, value);
  }

  Future<void> _readFile() async {
    try {
      final file = await _getFile(false);
      subject.value = _codec.decode(await file.readAsString());
    } catch (error, stackTrace) {
      developer.log(
        'Corrupted box, recovering backup file',
        name: 'get_storage_ce',
        error: error,
        stackTrace: stackTrace,
      );
      await _recoverFromBackup();
    }
  }

  Future<File> _getFile(bool isBackup) async {
    final fileDb = await _fileDb(isBackup: isBackup);
    await fileDb.parent.create(recursive: true);
    return fileDb;
  }

  Future<File> _fileDb({required bool isBackup}) async {
    final dir = await _getImplicitDir();
    final basePath = _resolveBasePath(path, dir.path);
    return File(_getPath(isBackup, basePath));
  }

  Future<Directory> _getImplicitDir() async {
    return getApplicationDocumentsDirectory();
  }

  String _resolveBasePath(String? customPath, String defaultPath) {
    if (customPath == null || customPath.isEmpty) {
      return defaultPath;
    }

    return p.isAbsolute(customPath) ? customPath : p.join(defaultPath, customPath);
  }

  String _getPath(bool isBackup, String path) {
    return p.join(path, isBackup ? '$fileName.bak' : '$fileName.gs');
  }

  Future<void> _recoverFromBackup() async {
    final backup = await _getFile(true);

    try {
      subject.value = _codec.decode(await backup.readAsString());
    } catch (error, stackTrace) {
      developer.log(
        'Can not recover corrupted box',
        name: 'get_storage_ce',
        error: error,
        stackTrace: stackTrace,
      );
      subject.value = <String, dynamic>{};
    }

    await flush();
  }

  Future<void> _writeAtomically(File file, String contents) async {
    await file.parent.create(recursive: true);

    final temporaryFile = File('${file.path}.tmp');
    try {
      await temporaryFile.writeAsString(contents, flush: true);
      try {
        await _renameTemporaryFile(temporaryFile, file);
      } on FileSystemException {
        await _writeDirectly(file, contents);
      }
    } finally {
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }
    }
  }

  Future<void> _renameTemporaryFile(File temporaryFile, File file) async {
    try {
      await temporaryFile.rename(file.path);
    } on FileSystemException {
      await file.parent.create(recursive: true);
      await temporaryFile.rename(file.path);
    }
  }

  Future<void> _writeDirectly(File file, String contents) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(contents, flush: true);
  }

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}
