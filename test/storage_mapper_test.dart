import 'dart:io';

import 'package:intl/locale.dart';
import 'package:geiger_localstorage/src/storage_exception.dart';
import 'package:geiger_localstorage/src/db/storage_mapper.dart';
import 'package:geiger_localstorage/src/db/data/node_implementation.dart';
import 'package:geiger_localstorage/src/db/data/node_value_implementation.dart';
import 'package:geiger_localstorage/src/db/mapper/dummy_mapper.dart';
import 'package:geiger_localstorage/src/db/mapper/sqlite_mapper.dart';
import 'package:test/test.dart';

class StorageMapperTest {}

void _testPrep(List<StorageMapper> mapperList) {
  for (final mapper in mapperList) {
    mapper.zap();
  }
}

void _testTearDown(List<StorageMapper> mapperList) {
  for (final mapper in mapperList) {
    mapper.flush();
  }
}

void main() {
  late List<StorageMapper> mapperList;

  setUp(() {
    mapperList = [DummyMapper(), SqliteMapper('./testdb.sqlite')];
    _testPrep(mapperList);
  });

  test('Adding node', () {
    for (final mapper in mapperList) {
      print('## Testing mapper $mapper in UNKNOWN');
      var node = NodeImpl('testNode1', '');
      node.setOwner('myOwner');
      print("### adding new node");
      mapper.add(node);

      // make sure that lastupdated and owner is not updated upon add
      print("### retrieving previously written node");
      var node2 = mapper.get(':testNode1');
      print("### testing node content");
      expect(node2.equals(node), true,
          reason: 'Last updated was unexpectedly updated');
    }
  });

  test('add root node null', () {
    for (final mapper in mapperList) {
      print('## Testing mapper ' + mapper.toString() + ' in UNKNOWN');
      var node = NodeImpl('testNode1');
      node.setOwner('myOwner');

      mapper.add(node);

      // make sure that lastupdated and owner is not updated upon add
      var node2 = mapper.get(':testNode1');
      expect(node2.equals(node), true,
          reason: 'Last updated was unexpectedly updated');
    }
  });

  test('add root node illegal name', () {
    for (final mapper in mapperList) {
      for (var name in [':name', 'na:me', 'name:']) {
        print('## Testing mapper ' + mapper.toString() + ' in UNKNOWN');
        var node = NodeImpl(name, '');
        expect(
            () => mapper.add(node), throwsA(TypeMatcher<StorageException>()));
        // make sure that the element was not added
        expect(
            () => mapper.get(name), throwsA(TypeMatcher<StorageException>()));
      }
    }
  });
  test('add root node illegal parent', () {
    for (final mapper in mapperList) {
      mapper.add(NodeImpl('na', ''));
      for (var parent in [':name:', 'na:me', 'name:', '::', ':na::']) {
        print('## Testing mapper ' + mapper.toString() + ' in INVALID');
        var node = NodeImpl('name', parent);
        expect(
            () => mapper.add(node), throwsA(TypeMatcher<StorageException>()));
        // make sure that the element was not added
        expect(() => mapper.get(parent + ':name'),
            throwsA(TypeMatcher<StorageException>()));
      }
    }
  });
  test('add duplicate node', () {
    for (final mapper in mapperList) {
      print('## Testing mapper ' + mapper.toString() + ' in INVALID');
      var node = NodeImpl('testNode1', '');
      mapper.add(node);
      expect(() => mapper.add(node), throwsA(TypeMatcher<StorageException>()));
    }
  });
  test('add parent-less node', () {
    for (final mapper in mapperList) {
      print('## Testing mapper ' + mapper.toString() + ' in INVALID');
      var node = NodeImpl('testNode1', ':notAValidParent');
      expect(() => mapper.add(node), throwsA(TypeMatcher<StorageException>()));
    }
  });
  test('node getter tests', () {
    for (final mapper in mapperList) {
      print('## Testing mapper ' + mapper.toString() + ' in INVALID');
      var node = NodeImpl('testNode1', '');
      var childNode = NodeImpl('testNode1a', ':testNode1');
      var nv = NodeValueImpl('key', 'value', 'type', 'description', 1);
      node.addChild(childNode);
      node.addValue(nv);

      // write data
      var node2 = NodeImpl('testNode2', '');
      mapper.add(node);
      mapper.add(node2);
      mapper.add(childNode);

      // get data
      var storedNode = mapper.get(':testNode1');
      var storedChildNode = mapper.get(':testNode1:testNode1a');
      var storedNode2 = mapper.get(':testNode2');
      expect(storedNode.isSkeleton(), false,
          reason: 'Node :testNode1 may not be a skeleton if fetched');
      expect(storedChildNode.isSkeleton(), false,
          reason: 'Node :testNode1 may not be a skeleton if fetched');
      expect(storedNode2.isSkeleton(), false,
          reason: 'Node :testNode1 may not be a skeleton if fetched');

      // compare data
      expect(node.equals(storedNode), true, reason: 'comparing parent node failed (expected: ${storedNode.toString()}; got: ${node.toString()}');
      expect(childNode.equals(storedChildNode), true,
          reason: 'comparing child node');
      expect(node2.equals(storedNode2), true, reason: 'comparing parent node2 ');
      expect(storedNode.getChildren().length, 1,
          reason: 'checking for child node count');
    }
  });
  test('persistence of locales', () {
    for (final mapper in mapperList) {
      print('## Testing mapper ' + mapper.toString() + ' in INVALID');
      var nv = NodeValueImpl('key', 'value', 'type', 'description', 1);
      nv.setDescription('Deutsche Beschreibung', Locale.parse('de-de'));
      nv.setDescription('Schwiizertüütschi Beschriibig', Locale.parse('de-ch'));
      nv.setValue('Wert', Locale.parse('de-de'));
      nv.setValue('Au ä Wert', Locale.parse('de-ch'));
      var node = NodeImpl('testNode1', '');
      var childNode = NodeImpl('testNode1a', ':testNode1');
      node.addChild(childNode);
      node.addValue(nv);
      print('## Stored ' + node.toString());

      // write data
      var node2 = NodeImpl('testNode2', '');
      mapper.add(node);
      mapper.add(node2);
      mapper.add(childNode);

      // get data
      var storedNode = mapper.get(':testNode1');
      var storedChildNode = mapper.get(':testNode1:testNode1a');
      var storedNode2 = mapper.get(':testNode2');
      expect(storedNode.isSkeleton(), false,
          reason: 'Node :testNode1 may not be a skeleton if fetched');
      expect(storedChildNode.isSkeleton(), false,
          reason:
              'Node :testNode1:testNode1a may not be a skeleton if fetched');
      expect(storedNode2.isSkeleton(), false,
          reason: 'Node :testNode2 may not be a skeleton if fetched');
      print('## got    ' + storedNode.toString());

      // compare data
      expect(node.equals(storedNode), true, reason: 'comparing parent node (expected: ${node.toString()}(${node.toString().hashCode}); got: ${storedNode.toString()}(${storedNode.toString().hashCode})');
      expect(childNode.equals(storedChildNode), true,
          reason: 'comparing child node');
      expect(node2.equals(storedNode2), true, reason: 'comparing parent node2');
      expect(storedNode.getChildren().length, 1,
          reason: 'checking for child node count');
    }
  });
  tearDown(() {
    _testTearDown(mapperList);

    // tear down all test data
    for (final mapper in mapperList) {
      mapper.close();
    }
    File('./testdb.sqlite').deleteSync();
  });
}
