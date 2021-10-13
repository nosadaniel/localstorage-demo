import 'dart:developer';

import 'package:example/model/threat.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DemoController extends GetxController {
  RxList<Threat> threats = <Threat>[].obs;
  StorageController? _storageController;
  CreateNodeAndNodeValue createNodeAndNodeValue = CreateNodeAndNodeValue();

  final Map<String, String> _threatMap = {
    "80efffaf-98a1-4e0a-8f5e-gr89388350ma": "Malware",
    "80efffaf-98a1-4e0a-8f5e-gr89388351wb": "Web-based threats",
    "80efffaf-98a1-4e0a-8f5e-gr89388352ph": "phishing",
    "80efffaf-98a1-4e0a-8f5e-gr89388353wa": "Web application threats"
  };

  void getThreatFromDataBase() {
    log(createNodeAndNodeValue
        .getThreats(_storageController!, _threatMap)
        .toString());
    threats.value =
        createNodeAndNodeValue.getThreats(_storageController!, _threatMap);

    log(threats.length.toString());
  }

  void _initDatabase() async {
    //create path for database file
    String dbPath = join(await getDatabasesPath(), 'doggie_database.db');
    //using dummyMapper
    //controller = GenericController('uiTest1', DummyMapper());
    //using persistent database
    try {
      _storageController = GenericController('uiTest2', SqliteMapper(dbPath));
      log(dbPath.toString());
    } catch (e, s) {
      log("Error: $e \ntrace:$s");
    }
  }

  @override
  void onInit() {
    _initDatabase();
    super.onInit();
  }

  @override
  void onClose() {
    _storageController!.close();
    super.onClose();
  }
}
