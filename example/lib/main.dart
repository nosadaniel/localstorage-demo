import 'dart:developer';

import 'package:example/model/threat.dart';
import 'package:flutter/material.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
      home: const MyHomePage(title: 'Threats From that Database'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Threat> threats = <Threat>[];
  StorageController? controller;

  CreateNodeAndNodeValue createNodeAndNodeValue = CreateNodeAndNodeValue();
  Map<String, String> threatMap = {
    "80efffaf-98a1-4e0a-8f5e-gr89388350ma": "Malware",
    "80efffaf-98a1-4e0a-8f5e-gr89388351wb": "Web-based threats",
    "80efffaf-98a1-4e0a-8f5e-gr89388352ph": "phishing",
    "80efffaf-98a1-4e0a-8f5e-gr89388353wa": "Web application threats"
  };

  void getThreatFromDataBase() {
    log(createNodeAndNodeValue.getThreats(controller!).toString());
    setState(() {
      threats = createNodeAndNodeValue.getThreats(controller!);
    });
    log(threats.length.toString());
  }

  void initDatabase() async {
    //create path for database file
    String dbPath = join(await getDatabasesPath(), 'test_database.db');
    //using dummyMapper
    //controller = GenericController('uiTest1', DummyMapper());
    //using persistent database
    controller = GenericController('uiTest6', SqliteMapper(dbPath));
    log(dbPath.toString());
  }

  @override
  void initState() {
    try {
      initDatabase();
    } catch (e) {
      log("$e");
    }
    super.initState();
  }

  @override
  void dispose() {
    //close database connection
    controller!.close();
    super.dispose();
  }

  // build the ui
  @override
  Widget build(BuildContext context) {
    //

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: threats.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                  child: Text(
                "Database is Empty, Pressed the add button to populate the Screen",
                style: TextStyle(color: Colors.red),
                softWrap: true,
              )),
            )
          : ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  subtitle: Text(threats[index].name),
                  title: Text("ID: ${threats[index].threatId}"),
                );
              },
              itemCount: threats.length),
      floatingActionButton: FloatingActionButton(
        onPressed: getThreatFromDataBase,
        tooltip: 'CreateNode',
        child: const Icon(Icons.add),
      ),
    );
  }
}
