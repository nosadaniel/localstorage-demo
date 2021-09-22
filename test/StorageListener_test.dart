import 'package:localstorage/src/EventType.dart';
import 'package:localstorage/src/SearchCriteria.dart';
import 'package:localstorage/src/StorageController.dart';
import 'package:localstorage/src/StorageException.dart';
import 'package:localstorage/src/StorageListener.dart';
import 'package:localstorage/src/db/GenericController.dart';
import 'package:localstorage/src/db/data/Node.dart';
import 'package:localstorage/src/db/data/NodeImpl.dart';
import 'package:localstorage/src/db/mapper/DummyMapper.dart';
import 'package:test/test.dart';

class StorageListener_test {}

void _setupTest(StorageController controller) {
  controller.zap();
}

class NodeListener with StorageListener {
  Node _oldNode = NodeImpl('');
  Node _newNode = NodeImpl('');

  Node get oldnode {
    return _oldNode.deepClone();
  }

  Node get newnode {
    return _newNode.deepClone();
  }

  @override
  void gotStorageChange(EventType event, Node? oldNode, Node? newNode) {
    _oldNode.update(oldNode ?? NodeImpl(''));
    _newNode.update(newNode ?? NodeImpl(''));
  }
}

void _testRegisterDeRegisterListener(StorageController controller) {
  test('Register and de-register tests', () {
    _setupTest(controller);
    var sl = NodeListener();

    //create a dummy search criteria
    var sc = SearchCriteria();

    // register the listener
    controller.registerChangeListener(sl, sc);

    //deregister listener
    var scr = controller.deregisterChangeListener(sl);

    // check return values
    expect(scr != null, true,
        reason:
            "Returned array is unexpectedly NULL when de-registering an known listener");
    expect(scr.length, 1,
        reason:
            "returned array does not contain only one search criteria when de-registering an known listener");
    expect(scr.first, sc,
        reason:
            "returned array does not contain only one search criteria when de-registering a known listener");

    // check de-registering unregistered listener
    expect(() => controller.deregisterChangeListener(sl),
        throwsA(TypeMatcher<StorageException>()));
  });
}

void _testSearchImplementation(StorageController controller) {
  test('test search implementation',() {
    // /**
    //  * <p>Test the implementation of basic search works as expected.</p>
    //  */
    // final String testPath1 = ":Devices:testDevice1";
    // final String testPath2 = ":Devices:testDevice2";
    // final Object notifier = new Object();
    //
    // final Node on = new NodeImpl(":null");
    // final Node nn = new NodeImpl(":null");
    // final StringBuilder evt = StringBuilder();
    // final AtomicInteger nums = AtomicInteger(0);
    // StorageListener sl = (event, node1, node2) -> {
    // evt.delete(0, 100);
    // evt.append(event.toString());
    // if (node1 != null) {
    //   on.update(node1);
    // }
    // if (node2 != null) {
    //   nn.update(node2);
    // }
    // nums.incrementAndGet();
    // System.out.println("#### (EVENT) got new event \"" + event + "\" with change " + node1+ "(" + on + ")->" + node2);
    // synchronized (notifier) {
    // notifier.notifyAll();
    // }
    // };
    // //create a dummy search criteria
    // SearchCriteria sc = new SearchCriteria();
    // sc.setNodePath(":Devices");
    //
    // // register the listener
    // controller.registerChangeListener(sl, sc);
    // assertEquals("old node expected to be empty", ":null", on.getPath());
    // assertEquals("new node expected to be empty", ":null", nn.getPath());
    // assertEquals("event expected to be empty", "", evt.toString());
    // assertEquals("got sufficient events", nums.get(), 0);
    //
    // // adding test node
    // Node tn = new NodeImpl(testPath1);
    // tn.setOwner("testOwner");
    // controller.add(tn);
    // synchronized (notifier) {
    //     notifier.wait(1000);
    // }
    // assertEquals("got sufficient events", nums.get(), 1);
    // assertEquals("old node expected to be empty", ":null", on.getPath());
    // assertEquals("nodes (written and new) are expected to be equal (1)", tn, nn);
    // assertEquals("event expected to be add", EventType.CREATE.toString(), evt.toString());
    //
    // // update with equivalent node (should not trigger an event)
    // on.update(new NodeImpl(":null"));
    // nn.update(new NodeImpl(":null"));
    // evt.delete(0, 100);
    // controller.update(tn);
    // for (int i = 0; nums.get() < 2 && i < 10; i++) {
    //   synchronized (notifier) {
    //     notifier.wait(100);
    //   };
    // }
    // assertEquals("got sufficient events", 1, nums.get());
    // assertEquals("old node expected to be empty", ":null", on.getPath());
    // assertEquals("new node expected to be empty", ":null", nn.getPath());
    // assertEquals("event expected to be empty", "", evt.toString());
    //
    // // update with changed node
    // on.update(new NodeImpl(":null"));
    // nn.update(new NodeImpl(":null"));
    // evt.delete(0, 100);
    // Node nodeWithoutValue = tn.deepClone();
    // Node nodeWithValue = nodeWithoutValue.deepClone();
    // nodeWithValue.addValue(new NodeValueImpl("key", "value"));
    // controller.update(nodeWithValue);
    // for (int i = 0; nums.get() < 2 && i < 10; i++) {
    //   synchronized (notifier) {
    //     notifier.wait(100);
    //   }
    // }
    // assertEquals("got bad number of events", 2, nums.get());
    // assertEquals("old node mismatch", nodeWithoutValue, on);
    // assertEquals("new node mismatch", nodeWithValue, nn);
    // assertEquals("event expected to be empty", EventType.UPDATE.toString(), evt.toString());
    //
    // // delete node
    // on.update(new NodeImpl(":null"));
    // nn.update(new NodeImpl(":null"));
    // evt.delete(0, 100);
    // Node newNode = nodeWithValue.deepClone();
    // ((NodeImpl) (newNode)).set(Field.PATH, testPath2);
    // controller.rename(testPath1, testPath2);
    // for (int i = 0; nums.get() < 3 && i < 10; i++) {
    //   synchronized (notifier) {
    //     notifier.wait(100);
    //   }
    // }
    // assertEquals("got bad number of events", 3, nums.get());
    // assertEquals("old node expected to be empty", nodeWithValue, on);
    // assertEquals("new node expected to be empty", newNode, nn);
    // assertEquals("event expected to be empty", EventType.RENAME.toString(), evt.toString());
    //
    // // remove node
    // on.update(new NodeImpl(":null"));
    // nn.update(new NodeImpl(":null"));
    // evt.delete(0, 100);
    // // newNode = controller.get(testPath2);
    // controller.delete(testPath2);
    // synchronized (notifier) {
    //   notifier.wait(1000);
    // }
    // assertEquals("got bad number of events", 4, nums.get());
    // assertEquals("nodes are expected to be equal (2)", newNode, on);
    // assertEquals("new node expected to be empty", ":null", nn.getPath());
    // assertEquals("event expected to be add", evt.toString(), EventType.DELETE.toString());
    //
    // //deregister listener
    // controller.deregisterChangeListener(sl);
    // }
  });
  test('test events on base node', () {
    // /**
    //  * <p>Test the implementation if the register/deregister cycle works as expected.</p>
    //  */
    // /**
    //  * <p>Test the implementation of basic search works as expected.</p>
    //  */
    // @Test
    // public void testListenerForCreateRemoveBaseNode() throws InterruptedException {
    // final String testPath = ":searchtest1";
    // final Node on = new NodeImpl("");
    // final Node nn = new NodeImpl("");
    // final StringBuilder evt = new StringBuilder();
    // StorageListener sl = (event, node1, node2) -> {
    // evt.delete(0, 100);
    // evt.append(event.toString());
    // if (node1 != null) {
    // on.update(node1);
    // }
    // if (node2 != null) {
    // nn.update(node2);
    // }
    // };
    //
    // //create a dummy search criteria
    // SearchCriteria sc = new SearchCriteria();
    // sc.setNodePath(testPath);
    //
    // // register the listener
    // controller.registerChangeListener(sl, sc);
    //
    // assertEquals("old node expected to be empty", ":", on.getPath());
    // assertEquals("new node expected to be empty", ":", nn.getPath());
    // assertEquals("event expected to be empty", "", evt.toString());
    //
    // // adding test node
    // Node tn = new NodeImpl(testPath);
    // tn.setOwner("testOwner");
    // controller.add(tn);
    // sleep(100);
    // assertEquals("nodes (written and new) are expected to be equal (1)", tn, nn);
    // assertEquals("old node expected to be empty", ":", on.getPath());
    // assertEquals("event expected to be add", EventType.CREATE.toString(), evt.toString());
    //
    // // update with equivalent node (should not trigger an event)
    // on.update(new NodeImpl(""));
    // nn.update(new NodeImpl(""));
    // evt.delete(0, 100);
    // controller.update(tn);
    // assertEquals("old node expected to be empty", ":", on.getPath());
    // assertEquals("new node expected to be empty", ":", nn.getPath());
    // assertEquals("event expected to be empty", "", evt.toString());
    //
    // // remove node
    // controller.delete(testPath);
    // sleep(100);
    // assertEquals("nodes are expected to be equal (2)", tn, on);
    // assertEquals("new node expected to be empty", ":", nn.getPath());
    // assertEquals("event expected to be add", evt.toString(), EventType.DELETE.toString());
    //
    // //deregister listener
    // controller.deregisterChangeListener(sl);
    // }
    //
  });
}

void main() {
  var controller = GenericController('testOwner', DummyMapper());

  _testRegisterDeRegisterListener(controller);

  _testSearchImplementation(controller);
  // TODO: Translate from java

}
