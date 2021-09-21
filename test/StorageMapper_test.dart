import 'dart:io';

import 'package:localstorage/src/db/StorageMapper.dart';
import 'package:localstorage/src/db/data/NodeImpl.dart';
import 'package:localstorage/src/db/mapper/DummyMapper.dart';
import 'package:localstorage/src/db/mapper/SqliteMapper.dart';
import 'package:test/test.dart';

class StorageMapper_test {}

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
  var mapperList = [
    DummyMapper(),
    SqliteMapper('jdbc:sqlite:./testdb.sqlite')
  ];

  _testPrep(mapperList);
  test('Adding root node', () {
    for (final mapper in mapperList) {
      print('## Testing mapper $mapper in UNKNOWN' );
      var node = NodeImpl('testNode1', '');
      mapper.add(node);

      // make sure that lastupdated and owner is updated upon add
      mapper.get(':testNode1');

      // todo: add tests
    }
  });
  _testTearDown(mapperList);

  // TODO: translate from java
  //
  // @Test
  // public void testAddRootNodeNull() {
  // for (StorageMapper mapper : mapperList) {
  // System.out.println("## Testing mapper " + mapper + " in " + (new Object() {
  // }).getClass().getEnclosingMethod().getName());
  // NodeImpl node = new NodeImpl("testNode1");
  //
  // mapper.add(node);
  //
  // // make sure that lastupdated and owner is updated upon add
  // mapper.get(":testNode1");
  // }
  // }
  //
  // @Test
  // public void testAddRootNodeIllegalName() {
  // for (StorageMapper mapper : mapperList) {
  // for (String name : new String[]{":name", "na:me", "name:"}) {
  // System.out.println("## Testing mapper " + mapper + " in " + (new Object() {
  // }).getClass().getEnclosingMethod().getName());
  // NodeImpl node = new NodeImpl(name, "");
  // try {
  // mapper.add(node);
  // fail("duplicate adding unexpectedly successful");
  // } catch (StorageException e) {
  // // this should fail
  // System.out.println("#### adding with name " + name
  // + " failed as expected with exception " + e);
  // }
  //
  // // make sure that the element was not added
  // try {
  // Node n = mapper.get(name);
  // fail("adding with illegal name was retrieveaeable");
  // } catch (StorageException e) {
  // // this should fail
  // System.out.println("#### node with name " + name
  // + " was not stored as expected with exception " + e);
  // }
  // }
  // }
  // }
  //
  // @Test
  // public void testAddRootNodeIllegalParent() {
  // for (StorageMapper mapper : mapperList) {
  // mapper.add(new NodeImpl("na", ""));
  // for (String parent : new String[]{":name:", "na:me", "name:", "::", ":na::"}) {
  // System.out.println("## Testing mapper " + mapper + " in " + (new Object() {
  // }).getClass().getEnclosingMethod().getName());
  // NodeImpl node = new NodeImpl("name", parent);
  // try {
  // mapper.add(node);
  // fail("duplicate adding unexpectedly successful");
  // } catch (StorageException e) {
  // // this should fail
  // System.out.println("#### adding with parent " + parent
  // + " failed as expected with exception " + e);
  // }
  //
  // // make sure that the element was not added
  // try {
  // mapper.get(parent);
  // fail("adding with illegal name was retrieveaeable");
  // } catch (StorageException e) {
  // // this should fail
  // System.out.println("#### node with parent " + parent
  // + " was not stored as expected with exception " + e);
  // }
  // }
  // }
  // }
  //
  // @Test
  // public void testDuplicateAddNode() {
  // for (StorageMapper mapper : mapperList) {
  // System.out.println("## Testing mapper " + mapper + " in " + (new Object() {
  // }).getClass().getEnclosingMethod().getName());
  // NodeImpl node = new NodeImpl("testNode1", "");
  // mapper.add(node);
  // try {
  // mapper.add(node);
  // fail("duplicate adding unexpecetedly successful");
  // } catch (StorageException e) {
  // // this should fail
  // }
  //
  // // make sure that lastupdated and owner is updated upon add
  // mapper.get(":testNode1");
  // }
  // }
  //
  // @Test
  // public void testAddNodeWithoutParent() {
  // for (StorageMapper mapper : mapperList) {
  // System.out.println("## Testing mapper " + mapper + " in " + (new Object() {
  // }).getClass().getEnclosingMethod().getName());
  // NodeImpl node = new NodeImpl("testNode1", ":notAValidParent");
  //
  // try {
  // mapper.add(node);
  // fail("unexpectedly successfully added a node without a parent");
  // } catch (StorageException e) {
  // // this should fail
  // }
  // }
  // }
  //
  // @Test
  // public void testGetNode() {
  // for (StorageMapper mapper : mapperList) {
  // System.out.println("## Testing mapper " + mapper + " in " + (new Object() {
  // }).getClass().getEnclosingMethod().getName());
  // Node node = new NodeImpl("testNode1", "");
  // Node childNode = new NodeImpl("testNode1a", ":testNode1");
  // NodeValue nv = new NodeValueImpl("key", "value", "type", "description", 1);
  // node.addChild(childNode);
  // node.addValue(nv);
  //
  // // write data
  // Node node2 = new NodeImpl("testNode2", "");
  // mapper.add(node);
  // mapper.add(node2);
  // mapper.add(childNode);
  //
  // // get data
  // Node storedNode = mapper.get(":testNode1");
  // Node storedChildNode = mapper.get(":testNode1:testNode1a");
  // Node storedNode2 = mapper.get(":testNode2");
  // assertFalse("Node :testNode1 may not be a skeleton if fetched", storedNode.isSkeleton());
  // assertFalse("Node :testNode1:testNode1a may not be a skeleton if fetched",
  // storedChildNode.isSkeleton());
  // assertFalse("Node :testNode2 may not be a skeleton if fetched", storedNode2.isSkeleton());
  //
  // // compare data
  // assertEquals("comparing parent node", node, storedNode);
  // assertEquals("comparing child node", childNode, storedChildNode);
  // assertEquals("comparing parent node2", node2, storedNode2);
  // assertEquals("checking for child node count", 1, storedNode.getChildren().size());
  // }
  // }
  //
  // @Test
  // public void testLocalePersistenceOnNode() {
  // for (StorageMapper mapper : mapperList) {
  // System.out.println("## Testing mapper " + mapper + " in " + (new Object() {
  // }).getClass().getEnclosingMethod().getName());
  //
  // NodeValue nv = new NodeValueImpl("key", "value", "type", "description", 1);
  // nv.setDescription("Deutsche Beschreibung", Locale.GERMAN);
  // nv.setDescription("Schwiizertüütschi Beschriibig", new Locale("de", "ch"));
  // nv.setValue("Wert", Locale.GERMAN);
  // nv.setValue("Au ä Wert", new Locale("de", "ch"));
  // Node node = new NodeImpl("testNode1", "");
  // Node childNode = new NodeImpl("testNode1a", ":testNode1");
  // node.addChild(childNode);
  // node.addValue(nv);
  // System.out.println("## Stored " + node);
  //
  // // write data
  // Node node2 = new NodeImpl("testNode2", "");
  // mapper.add(node);
  // mapper.add(node2);
  // mapper.add(childNode);
  //
  // // get data
  // Node storedNode = mapper.get(":testNode1");
  // Node storedChildNode = mapper.get(":testNode1:testNode1a");
  // Node storedNode2 = mapper.get(":testNode2");
  // assertFalse("Node :testNode1 may not be a skeleton if fetched", storedNode.isSkeleton());
  // assertFalse("Node :testNode1:testNode1a may not be a skeleton if fetched",
  // storedChildNode.isSkeleton());
  // assertFalse("Node :testNode2 may not be a skeleton if fetched", storedNode2.isSkeleton());
  // System.out.println("## got    " + storedNode);
  //
  // // compare data
  // assertEquals("comparing parent node", node, storedNode);
  // assertEquals("comparing child node", childNode, storedChildNode);
  // assertEquals("comparing parent node2", node2, storedNode2);
  // assertEquals("checking for child node count", 1, storedNode.getChildren().size());
  // }
  // }

  // tear down all test data
  for (final mapper in mapperList) {
        mapper.close();
  }
  File('./testdb.mv.db').delete();
  File('./testdb.sqlite').delete();
}

