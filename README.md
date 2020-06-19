# get_storage
A fast, extra light and synchronous key-value storage to Get framework written entirely in Dart.

Supports Android, iOS, Web, Mac, Linux, and fuchsia (Wip on Windows). 

Add to your pubspec:
```
dependencies:
  get_storage:
```

Initialize storage driver with await:
```dart
main() async {
  await GetStorage.init();
  runApp(App());
}
```
use GetStorage as instance:
```dart
GetStorage getx = GetStorage();
```
And use it. To write information you must use `write` :
```dart
 getx.write('quote', 'GetX is the best');
```

To read values you use `read`:
```dart
print(getx.read('quote'));
// out: GetX is the best

```
To remove a key, you can use `remove`:

```dart
 getx.remove('quote');
```

To listen changes you can use `listen`:
```dart
 getx.listen((event) {print(event);});
```
If you subscribe to events, be sure to dispose them when using:
```dart
 getx.dispose();
```

If you want to create different containers, simply give it a name. You can listen to specific containers, and also delete them.

```dart
GetStorage g = GetStorage('MyStorage');
```

To initialize specific container:
```dart
 await GetStorage.init('MyStorage');
 ```


