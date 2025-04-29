import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GetStorage box;

  const channel = MethodChannel('plugins.flutter.io/path_provider');
  void setUpMockChannels(MethodChannel channel) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall? methodCall) async {
          if (methodCall?.method == 'getApplicationDocumentsDirectory') {
            return '.';
          }
          return null;
        });
  }

  setUpAll(() async {
    setUpMockChannels(channel);
  });

  setUp(() async {
    await GetStorage.init();
    box = GetStorage();
    await box.erase();
  });

  final counter = 'counter';
  final isDarkMode = 'isDarkMode';
  test('GetStorage read and write operation', () {
    box.write(counter, 0);
    expect(box.read(counter), 0);
  });

  test('save the state of brightness mode of app in GetStorage', () {
    box.write(isDarkMode, true);
    expect(box.read(isDarkMode), true);
  });
}
