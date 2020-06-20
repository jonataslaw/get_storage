import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  await GetStorage.init();
  runApp(GetMaterialApp(home: Home()));
}

class Controller extends GetController {
  final box = GetStorage();
  int counter;

  @override
  onInit() {
    counter = box.read('key') ?? 0;
    box.listen(() => update());
  }

  void increment() {
    counter++;
    box.write('key', counter);
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Get Storage")),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'You have pushed the button this many times:',
              ),
              GetBuilder<Controller>(
                  init: Controller(),
                  builder: (_) =>
                      Text('${_.counter}', style: Get.textTheme.headline4)),
            ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.find<Controller>().increment(),
        child: Icon(Icons.add),
      ),
    );
  }
}
