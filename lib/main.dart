import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:exp1/cipher.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

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
  int _counter = 0;
  String deviceId = 'Loading...';
  String appId = 'Loading...';
  String version = 'Loading...';
  String timestamp = "0";
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final Uint8List keys = getKey();
  final Uint8List iv = getInitVector();
  final serverURL = 'http://10.0.2.2:8000';
  final formKey = GlobalKey<FormState>();

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  Future<void> _loadDeviceInfo() async {
    // Get device information
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    // Get package information
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      deviceId = androidInfo.id; // Device ID
      appId = packageInfo.packageName; // Application ID
      version = packageInfo.version; // Version ID
    });
  }

  void getTimestamp() {
    int timestampNow = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    setState(() {
      timestamp = timestampNow.toString();
    });
  }

  String encrypt() {
    String data =
        '${usernameController.text}%${passwordController.text}%$deviceId%$appId%$version%$timestamp';
    final paddedPlainText = padPlaintext(utf8.encode(data));
    final cipherText = aesCbcEncrypt(keys, iv, paddedPlainText);
    return base64.encode(cipherText);
  }

  String? validateInput(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter some text';
    }
    return null;
  }

  bool validateUserInfo(
      String username, String password, BuildContext context) {
    if (username == password) {
      showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                title:
                    const Text("Mât khẩu không được trùng với tên đăng nhập"),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Đóng"))
                ],
              ));
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Form(
        key: formKey,
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              // TRY THIS: Try changing the color here to a specific color (to
              // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
              // change color while the other colors stay the same.
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              // Here we take the value from the MyHomePage object that was created by
              // the App.build method, and use it to set our appbar title.
              title: Text(widget.title),
            ),
            body: Column(
              children: [
                TextFormField(
                  validator: validateInput,
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your username',
                  ),
                ),
                TextFormField(
                  validator: validateInput,
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                  ),
                ),
                ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate() == true &&
                          validateUserInfo(usernameController.text,
                                  passwordController.text, context) ==
                              true) {
                        getTimestamp();
                        await _loadDeviceInfo();
                        final encryptedData = encrypt();
                        final result = await http.post(
                          Uri.parse('$serverURL/login'),
                          headers: <String, String>{
                            'Content-Type': 'application/json; charset=UTF-8',
                          },
                          body: jsonEncode(<String, String>{
                            'data': encryptedData,
                            'key': base64.encode(keys),
                            'iv': base64.encode(iv),
                          }),
                        );
                        print(result.body);
                      }
                    },
                    child: const Text('Login'))
              ],
            ) // This trailing comma makes auto-formatting nicer for build methods.
            ),
      ),
    );
  }
}
