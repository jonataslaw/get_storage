import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/src/storage/storage_frame.dart';

void main() {
  test('frame/deframe round trips', () {
    const json = '{"a":1,"b":"x"}';
    expect(StorageFrame.deframe(StorageFrame.frame(json)), json);
  });

  test('reads legacy unframed json for backward compatibility', () {
    const legacy = '{"a":1}';
    expect(StorageFrame.deframe(legacy), legacy);
  });

  test('detects corrupted payload', () {
    final framed = StorageFrame.frame('{"a":1}');
    final corrupted = framed.replaceFirst('"a"', '"b"');
    expect(() => StorageFrame.deframe(corrupted), throwsFormatException);
  });

  test('detects truncated payload', () {
    final framed = StorageFrame.frame('{"hello":"world"}');
    final truncated = framed.substring(0, framed.length - 3);
    expect(() => StorageFrame.deframe(truncated), throwsFormatException);
  });

  test('empty input stays empty', () {
    expect(StorageFrame.deframe(''), '');
  });

  test('adler32 matches known vector', () {
    // Adler-32 of "Wikipedia" == 0x11E60398.
    expect(StorageFrame.adler32('Wikipedia'.codeUnits), 0x11E60398);
  });
}
