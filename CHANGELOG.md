## [4.0.0]
- Breaking: raise the minimum Flutter SDK constraint to `>=3.10.0`.
- Migrate the web storage backend from `dart:html` to `package:web`, dropping the deprecated `avoid_web_libraries_in_flutter` workaround.
- Frame persisted payloads with an Adler-32 checksum and length header so a truncated or bit-rotted box file is detected on read instead of being silently loaded; legacy unframed boxes keep loading unchanged.
- Write the backup file before the primary file on flush and best-effort `fsync` the containing directory (via FFI on Linux/Android/macOS/iOS) so rename metadata survives power loss.
- Cache resolved box/backup `File` handles and skip re-encoding and re-writing when nothing changed since the last successful flush.
- Use unique per-write temporary file names (pid + counter) so overlapping writers can no longer clobber a shared `.tmp` file, with a direct-write fallback when cross-filesystem renames fail.
- Support nested container paths (e.g. `objects/4/0`) and resolve custom storage paths with the `path` package instead of manual string concatenation.
- Add the `ffi` dependency for directory fsync support and a `test` dev dependency.
- Add `test/storage_frame_test.dart` covering frame/deframe round-tripping, legacy compatibility, and corruption detection.
- Add a read/write throughput performance benchmark (`test/get_storage_benchmark_test.dart`).

## [3.0.0]
- Breaking: raise the minimum SDK constraint to Dart 3 (`>=3.0.0 <4.0.0`).
- Breaking: modernize `getKeys()` and `getValues()` to return typed iterable APIs instead of generic casts.
- Refactor storage internals around explicit backend, codec, typed change, and flush scheduler contracts.
- Ensure awaited write, remove, erase, and save operations wait for durable persistence work to complete.
- Improve IO persistence with async file operations, atomic temp-file writes, platform path separators, and awaited backup writes.
- Improve web persistence with direct `localStorage` key access and shared JSON codec validation.
- Replace internal GetX value notification usage with a lightweight Flutter `ChangeNotifier` wrapper.
- Add strict analyzer configuration for the package and example app.
- Add regression coverage for awaited primary and backup persistence.
- Add performance benchmark coverage for read, in-memory write, batched save, and durable write paths.
- Ignore GetStorage runtime and atomic-write temp files generated during tests or local benchmarking.

## [2.1.1] 
- Fix null exception in previous getx versions

## [2.1.0] 
- Add support to Getx5

## [2.0.3] 
- update to lastest getx

## [2.0.2] 
- update dependencies

## [2.0.0] 
- Null-safety support (@Ascenio) and fixes #49, #53 and #54 (@SquishyOctopus)

## [1.4.0] 
- Added failure recover backup

## [1.3.2] 
- Added compatibility with Getx 3.15.0

## [1.3.1] 
- Added compatibility with Getx 3.10.2

## [1.3.0] 
- Added ReadWriteValue

## [1.2.0] 
- Added writeInMemory and save methods

## [1.1.4] 
- Prevent spaces on database.gs

## [1.1.3] 
- Fix unnecessary imports

## [1.1.2] 
- Added Benchmarks

## [1.1.1] 
- Added Examples

## [1.1.0] 
- Added Container listeners

## [1.0.3] 
- Added repo

## [1.0.2] 
- Added docs

## [1.0.1] 
- Added docs

## [1.0.0] 
- Release to Get 3.0
