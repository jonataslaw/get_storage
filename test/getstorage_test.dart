import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/src/storage_impl.dart';

void main() async {
  var container1 = await GetStorage.init();
  final g = GetStorage();
  g.erase();

  test('write, read listen, e removeListen', () async {
    String valueListen = "";
    g.write('test', 'a');

    void boxListener() => valueListen = g.read('test');
    g.listen(boxListener);

    expect('a', g.read('test'));

    await g.write('test', 'b');
    expect('b', g.read<String>('test'));
    expect('b', valueListen);

    g.removeListen(boxListener);

    await g.write('test', 'c');

    expect('c', g.read<String>('test'));
    expect('b', valueListen);
    await g.write('test', 'd');

    expect('d', g.read<String>('test'));
  });

  test('Write and read', () {
    g.erase();
    var list = new List<int>.generate(50, (i) {
      int count = i + 1;
      g.write('write', count);
      print(count);
      return count;
    });

    expect(list.last, g.read('write'));
  });

  test('Write, read, remove and exists', () {
    g.erase();
    expect(null, g.read('write'));

    var list = new List<int>.generate(50, (i) {
      int count = i + 1;
      g.write('write', count);
      print(count);
      return count;
    });
    expect(list.last, g.read('write'));
    g.remove('write');
    expect(null, g.read('write'));
  });

  test('newContainer', () async {
    await GetStorage.init('newContainer');
    final newContainer = GetStorage('newContainer');

    /// Attempting to start a Container that has already started must return the container already created.
    var container2 = await GetStorage.init();
    expect(container1 == container2, true);

    newContainer.write('test', '1234');
    g.write('test', 'a');
    expect(g.read('test') == newContainer.read('test'), false);
    g.erase();
  });
}
