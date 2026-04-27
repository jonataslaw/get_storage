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
