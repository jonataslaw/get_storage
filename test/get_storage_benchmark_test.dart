import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory benchmarkDirectory;

  setUpAll(() async {
    benchmarkDirectory = await Directory.systemTemp.createTemp(
      'get_storage_ce_benchmark_',
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return benchmarkDirectory.path;
        }
        return null;
      },
    );
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);

    if (await benchmarkDirectory.exists()) {
      await benchmarkDirectory.delete(recursive: true);
    }
  });

  test('read and write throughput', () async {
    final results = <BenchmarkResult>[];

    final readBox = await _freshBox('read');
    await readBox.write('read_key', 1);

    const readIterations = 1000000;
    var readChecksum = 0;
    results.add(
      _measureSync('read existing int key', readIterations, () {
        for (var index = 0; index < readIterations; index++) {
          readChecksum += readBox.read<int>('read_key') ?? 0;
        }
      }),
    );
    expect(readChecksum, readIterations);

    final memoryWriteBox = await _freshBox('memory_write');
    const memoryWriteIterations = 100000;
    results.add(
      _measureSync('writeInMemory same key', memoryWriteIterations, () {
        for (var index = 0; index < memoryWriteIterations; index++) {
          memoryWriteBox.writeInMemory('memory_key', index);
        }
      }),
    );
    expect(memoryWriteBox.read<int>('memory_key'), memoryWriteIterations - 1);

    final batchedBox = await _freshBox('batched');
    const batchedWrites = 10000;
    results.add(
      _measureSync('writeInMemory unique keys', batchedWrites, () {
        for (var index = 0; index < batchedWrites; index++) {
          batchedBox.writeInMemory('key_$index', index);
        }
      }),
    );
    results.add(
      await _measureAsync('save box with 10k keys', 1, batchedBox.save),
    );

    final durableBox = await _freshBox('durable_same_key');
    const durableWrites = 200;
    results.add(
      await _measureAsync('await write same key', durableWrites, () async {
        for (var index = 0; index < durableWrites; index++) {
          await durableBox.write('durable_key', index);
        }
      }),
    );

    final growingBox = await _freshBox('durable_unique_keys');
    const durableGrowingWrites = 100;
    results.add(
      await _measureAsync('await write unique keys', durableGrowingWrites,
          () async {
        for (var index = 0; index < durableGrowingWrites; index++) {
          await growingBox.write('key_$index', index);
        }
      }),
    );

    _printResults(results);
  });
}

Future<GetStorage> _freshBox(String label) async {
  final container =
      'benchmark_${label}_${DateTime.now().microsecondsSinceEpoch}';
  await GetStorage.init(container);
  final box = GetStorage(container);
  await box.erase();
  return box;
}

BenchmarkResult _measureSync(
  String name,
  int operations,
  void Function() body,
) {
  final stopwatch = Stopwatch()..start();
  body();
  stopwatch.stop();

  return BenchmarkResult(name, operations, stopwatch.elapsed);
}

Future<BenchmarkResult> _measureAsync(
  String name,
  int operations,
  Future<void> Function() body,
) async {
  final stopwatch = Stopwatch()..start();
  await body();
  stopwatch.stop();

  return BenchmarkResult(name, operations, stopwatch.elapsed);
}

void _printResults(List<BenchmarkResult> results) {
  stdout.writeln('\nGetStorage benchmark results');
  stdout.writeln(
    'metric,operations,total_ms,us_per_operation,operations_per_second',
  );

  for (final result in results) {
    stdout.writeln(result.toCsvRow());
  }
}

final class BenchmarkResult {
  const BenchmarkResult(this.name, this.operations, this.elapsed);

  final String name;
  final int operations;
  final Duration elapsed;

  double get totalMilliseconds => elapsed.inMicroseconds / 1000;

  double get microsecondsPerOperation => elapsed.inMicroseconds / operations;

  double get operationsPerSecond =>
      operations / (elapsed.inMicroseconds / Duration.microsecondsPerSecond);

  String toCsvRow() {
    return [
      name,
      operations.toString(),
      totalMilliseconds.toStringAsFixed(3),
      microsecondsPerOperation.toStringAsFixed(3),
      operationsPerSecond.toStringAsFixed(2),
    ].join(',');
  }
}
