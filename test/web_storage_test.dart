@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  const container = 'web_storage_test';
  late GetStorage storage;

  setUp(() async {
    await GetStorage.init(container);
    storage = GetStorage(container);
    await storage.erase();
  });

  test('writes, reads, persists, removes, and erases values in localStorage',
      () async {
    expect(storage.hasData('greeting'), isFalse);

    await storage.write('greeting', 'hello wasm');
    await storage.write('count', 42);
    expect(storage.hasData('greeting'), isTrue);
    expect(storage.read<String>('greeting'), 'hello wasm');
    expect(storage.read<int>('count'), 42);
    expect(storage.getKeys<Iterable<String>>(),
        containsAll(['greeting', 'count']));

    await storage.remove('greeting');
    expect(storage.hasData('greeting'), isFalse);
    expect(storage.read<String>('greeting'), isNull);

    await storage.erase();
    expect(storage.getKeys<Iterable<String>>(), isEmpty);
  });
}
