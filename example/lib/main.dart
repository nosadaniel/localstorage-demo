import 'package:example/controllers/demo_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Demo(title: 'Threats From that Database'),
    );
  }
}

class Demo extends StatelessWidget {
  Demo({Key? key, required this.title}) : super(key: key);

  final String title;
  final DemoController _demoController = Get.put(DemoController());
  // build the ui
  @override
  Widget build(BuildContext context) {
    //

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Obx(() {
        return _demoController.threats.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Pressed the add button to populate threats to the Screen",
                      style: TextStyle(color: Colors.red),
                    ),
                    ElevatedButton(
                      onPressed: _demoController.getThreatFromDataBase,
                      child: const Text("get data"),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                          itemBuilder: (BuildContext context, int index) {
                            return Card(
                              child: ListTile(
                                subtitle:
                                    Text(_demoController.threats[index].name),
                                title: Text(
                                    "ID: ${_demoController.threats[index].threatId}"),
                              ),
                            );
                          },
                          itemCount: _demoController.threats.length),
                    ),
                  ],
                ),
              );
      }),
    );
  }
}
