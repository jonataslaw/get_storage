import 'dart:developer' as developer;
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../value.dart';
import 'storage_backend.dart';
import 'storage_codec.dart';
import 'storage_frame.dart';

final class StorageImpl implements StorageBackend {
  StorageImpl(this.fileName, [this.path]);

  final String? path;
  final String fileName;
  final StorageCodec _codec = const JsonStorageCodec();

  // #2: resolved File handles are cached after the first flush so we stop
  // calling getApplicationDocumentsDirectory() and re-creating the parent dir
  // on every save.
  File? _boxFile;
  File? _backupFile;

  // #6: unique temp suffix (pid + monotonic counter) so overlapping writers —
  // multiple isolates or app processes on the same box — never clobber a shared
  // "<file>.tmp".
  int _tempCounter = 0;

  // #3: skip re-encoding and re-writing when nothing changed since the last
  // successful flush. Starts dirty so the first flush always persists.
  bool _dirty = true;

  @override
  final ValueStorage<Map<String, dynamic>> subject =
      ValueStorage<Map<String, dynamic>>(<String, dynamic>{});

  @override
  void clear() {
    subject
      ..value.clear()
      ..changeValue("", null);
    _dirty = true;
  }

  @override
  Future<void> deleteBox() async {
    final box = await _fileDb(isBackup: false);
    final backup = await _fileDb(isBackup: true);
    await Future.wait(
        <Future<void>>[_deleteIfExists(box), _deleteIfExists(backup)]);
  }

  @override
  Future<void> flush() async {
    // #3: nothing changed since the last durable write — no re-encode, no I/O.
    if (!_dirty) return;

    // #7: frame the payload with a checksum so a torn or bit-rotted file is
    // detected on the next read instead of silently loading garbage.
    final encoded = StorageFrame.frame(_codec.encode(subject.value));
    final box = await _getFile(false);
    final backup = await _getFile(true);

    // Write the backup first so a crash mid-write to the primary file leaves a
    // recoverable copy on disk. Each write is atomic: a temp file is written
    // and renamed into place, with a direct-write fallback for cross-filesystem
    // renames (e.g. on Android). Parent directories are created recursively so
    // nested container names such as "objects/4/0" work on every platform.
    await _writeAtomically(backup, encoded);
    await _writeAtomically(box, encoded);

    // #4: fsync the directory so the rename metadata itself survives power
    // loss, not just the file contents. Best-effort — never fails the flush.
    _syncDirectory(box.parent.path);

    _dirty = false;
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
      _dirty = true;
      return flush();
    }

    await _readFile();
    _dirty = false; // in-memory now matches disk
  }

  @override
  void remove(String key) {
    subject
      ..value.remove(key)
      ..changeValue(key, null);
    _dirty = true;
  }

  @override
  void write(String key, dynamic value) {
    subject
      ..value[key] = value
      ..changeValue(key, value);
    _dirty = true;
  }

  Future<void> _readFile() async {
    try {
      final file = await _getFile(false);
      subject.value = _codec.decode(StorageFrame.deframe(await file.readAsString()));
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
    final cached = isBackup ? _backupFile : _boxFile;
    if (cached != null) return cached;

    final fileDb = await _fileDb(isBackup: isBackup);
    await fileDb.parent.create(recursive: true);
    if (isBackup) {
      _backupFile = fileDb;
    } else {
      _boxFile = fileDb;
    }
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

    return p.isAbsolute(customPath)
        ? customPath
        : p.join(defaultPath, customPath);
  }

  String _getPath(bool isBackup, String path) {
    return p.join(path, isBackup ? '$fileName.bak' : '$fileName.gs');
  }

  Future<void> _recoverFromBackup() async {
    final backup = await _getFile(true);

    try {
      subject.value = _codec.decode(StorageFrame.deframe(await backup.readAsString()));
    } catch (error, stackTrace) {
      developer.log(
        'Can not recover corrupted box',
        name: 'get_storage_ce',
        error: error,
        stackTrace: stackTrace,
      );
      subject.value = <String, dynamic>{};
    }

    _dirty = true;
    await flush();
  }

  Future<void> _writeAtomically(File file, String contents) async {
    // Parent dir already ensured by _getFile; only re-create on the rare
    // fallback paths below.
    final temporaryFile = File('${file.path}.$pid.${_tempCounter++}.tmp');
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

  // #4: POSIX directory fsync via libc. No-op on Windows (NTFS journals its
  // metadata) and anywhere the syscalls are missing. Wrapped so a failure here
  // can never break a flush — worst case is the pre-existing durability.
  //
  // ponytail: runs the syscalls on the calling isolate. fsync can block; if it
  // ever janks the UI, move this to a background isolate.
  void _syncDirectory(String dirPath) {
    if (!(Platform.isLinux ||
        Platform.isAndroid ||
        Platform.isMacOS ||
        Platform.isIOS)) {
      return;
    }
    try {
      final libc = ffi.DynamicLibrary.process();
      final open = libc.lookupFunction<_COpenNative, _COpenDart>('open');
      final fsync = libc.lookupFunction<_CFsyncNative, _CFsyncDart>('fsync');
      final close = libc.lookupFunction<_CCloseNative, _CCloseDart>('close');

      final pathPtr = dirPath.toNativeUtf8();
      try {
        const oRdonly = 0; // O_RDONLY on Linux/Android/macOS/iOS
        final fd = open(pathPtr.cast<ffi.Char>(), oRdonly);
        if (fd < 0) return;
        try {
          fsync(fd);
        } finally {
          close(fd);
        }
      } finally {
        malloc.free(pathPtr);
      }
    } catch (_) {
      // best-effort durability; ignore.
    }
  }
}

typedef _COpenNative = ffi.Int Function(ffi.Pointer<ffi.Char>, ffi.Int);
typedef _COpenDart = int Function(ffi.Pointer<ffi.Char>, int);
typedef _CFsyncNative = ffi.Int Function(ffi.Int);
typedef _CFsyncDart = int Function(int);
typedef _CCloseNative = ffi.Int Function(ffi.Int);
typedef _CCloseDart = int Function(int);
