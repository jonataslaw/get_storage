import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  final counter = 'counter';
  final isDarkMode = 'isDarkMode';
  GetStorage box = GetStorage();
  test('GetStorage read and write operation', () {
    box.write(counter, 0);
    expect(box.read(counter), 0);
  });

  test('save the state of brightness mode of app in GetStorage', () {
    box.write(isDarkMode, true);
    expect(box.read(isDarkMode), true);
  });
}
