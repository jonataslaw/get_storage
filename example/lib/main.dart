import 'package:example/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage_plus/get_storage_plus.dart';

void main() async {
  await GetStorage.init();
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(Controller());
    return Observer(builder: (_) {
      return MaterialApp(
          theme: controller.theme, home: MyHomePage(title: "Get_storage_plus"));
    });
  }
}
