import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  await GetStorage.init();
  await GetStorage.init('test');
  runApp(App());
}

class App extends StatelessWidget {
  final box = GetStorage();

  @override
  Widget build(BuildContext context) {
    // We will insert a value into the storage if it does not already have one, otherwise it will ignore it.
    box.writeIfNull('darkmode', false);

    return SimpleBuilder(builder: (_) {
      bool isDark = box.read('darkmode');
      return MaterialApp(
        theme: isDark ? ThemeData.dark() : ThemeData.light(),
        home: Scaffold(
          appBar: AppBar(title: Text("Get Storage")),
          body: Center(
            child: SwitchListTile(
              value: isDark,
              title: Text("Touch to change ThemeMode"),
              onChanged: (val) {
                box.write('darkmode', val);
                runTests();
              },
            ),
          ),
        ),
      );
    });
  }

  Future<void> runTests() async {
    final storage = GetStorage('test');
    await storage.erase();

    testReadAllMethod(storage, 1, 'name', 'Peter');
    testReadAllMethod(storage, 2, 'age', 27);
    testReadAllMethod(storage, 3, 'sex', 'male');

    storage.remove('name');
    storage.remove('sex');
    final values = storage.getKeys();
    assert(values.length == 1);
    print(values);
    assert(values.first == 'age');
  }

  void testReadAllMethod(
      GetStorage storage, int expectedLength, String key, dynamic value) {
    storage.write(key, value);
    assert(storage.read(key) == value);
    final Iterable<String> keys = storage.getKeys();
    final Iterable<dynamic> values = storage.getValues();
    print('$keys with length of ${keys.length}');
    print('$values with length of ${values.length}');
    assert(expectedLength == keys.length);
    assert(expectedLength == values.length);
  }
}
