import 'dart:io';

import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:test/test.dart';

class UserTest {}

void luongTests() {
  test('20210929-test1', () {
    StorageController geigerToolboxStorageController =
        GenericController('MI-Cyberrange', SqliteMapper('./dbFileName.sqlite'));
    geigerToolboxStorageController.close();
    File('./dbFileName.sqlite').deleteSync();
  });
  test('20210929-test2', () {
    // init
    StorageController geigerToolboxStorageController =
        GenericController('MI-Cyberrange', DummyMapper());

    // sample code
    var newScore = 123;
    var currentUserLevel = 123;
    try {
      Node node = geigerToolboxStorageController.get(':score-node');
      // this is bad coding as it depends on a full transaction database state. Introduced addOrUpdateValue as drop in replacement.
      node.addValue(NodeValueImpl('score', '$newScore'));
      node.addValue(NodeValueImpl('level', '$currentUserLevel'));
      geigerToolboxStorageController.update(node);
    } catch (e) {
      print('Exception while creating node');
      print(e.toString());

      Node node = NodeImpl('score-node');
      geigerToolboxStorageController.add(node);
      node.addValue(NodeValueImpl('score', '$newScore'));
      node.addValue(NodeValueImpl('level', '$currentUserLevel'));
      geigerToolboxStorageController.update(node);
    }
  });
}

void main() {
  luongTests();
}
