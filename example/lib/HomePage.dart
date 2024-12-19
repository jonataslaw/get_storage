import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage_plus/get_storage_plus.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<Controller>();
    return Scaffold(
      appBar: AppBar(title: Text("Get Storage")),
      body: Center(
        child: SwitchListTile(
          value: controller.isDark,
          title: Text("Touch to change ThemeMode"),
          onChanged: controller.changeTheme,
        ),
      ),
    );
  }
}

class Controller extends GetxController {
  final box = GetStorage();
  bool get isDark => box.read('darkmode') ?? false;
  ThemeData get theme => isDark ? ThemeData.dark() : ThemeData.light();
  void changeTheme(bool val) => box.write('darkmode', val);
}
