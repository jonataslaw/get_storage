import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/src/storage_impl.dart';

Future<void> main() async {
  await GetStorage.init();
  final g = GetStorage();

  test('adds one to input values', () async {
    g.write('test', 'aaaaaaaa');
    g.listen(() {
      print(g.read('test'));
    });

    expect('aaaaaaaa', g.read<String>('test'));

    await g.write('test', 'bbbbbbb');
    await g.write('test', 'cccccccc');
    await g.write('test', 'ddddddd');
  });
}
