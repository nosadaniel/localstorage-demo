package ch.fhnw.geiger.localstorage;

import static java.lang.Thread.sleep;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.fail;

import ch.fhnw.geiger.localstorage.db.GenericController;
import ch.fhnw.geiger.localstorage.db.data.Field;
import ch.fhnw.geiger.localstorage.db.data.Node;
import ch.fhnw.geiger.localstorage.db.data.NodeImpl;
import ch.fhnw.geiger.localstorage.db.data.NodeValueImpl;
import ch.fhnw.geiger.localstorage.db.mapper.DummyMapper;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.Before;
import org.junit.Test;

/**
 * <p>Test the storage listener interfaces.</p>
 */
public class TestStorageListener {


  public GenericController controller = new GenericController("testOwner", new DummyMapper());

  @Before
  public void setupTest() {
    // clear all stored objects
    controller.zap();
  }


  /**
   * <p>Test the implementation if the register/deregister cycle works as expected.</p>
   */
  @Test
  public void testRegisterDeRegisterListener() {
    final Node on = new NodeImpl("");
    StorageListener sl = (event, node1, node2) -> on.update(node1);

    //create a dummy search criteria
    SearchCriteria sc = new SearchCriteria();

    // register the listener
    controller.registerChangeListener(sl, sc);

    //deregister listener
    SearchCriteria[] scr = controller.deregisterChangeListener(sl);

    // check return values
    assertNotNull("Returned array is unexpectedly NULL when de-registering an known listener", scr);
    assertEquals("returned array does not contain only one search criteria when de-registering "
        + "an known listener", scr.length, 1);
    assertEquals("returned array does not contain only one search criteria when de-registering "
        + "an known listener", scr[0], sc);

    // check de-registering unknown criteria
    scr = controller.deregisterChangeListener((event, node1, node2) -> on.update(node1));

    // check return values
    assertNotNull("Returned array is unexpectedly NULL when de-registering an unknown listener",
        scr);
    assertEquals("returned array does not contain no search criteria  when de-registering an "
        + "unknown listener", scr.length, 0);

    // check de-registering null
    try {
      controller.deregisterChangeListener(null);
      fail("de-registering a null listener succeeded unexpectedly");
    } catch (NullPointerException npe) {
      // This is the expected behavior
    }
  }

  /**
   * <p>Test the implementation of basic search works as expected.</p>
   */
  @Test
  public void testListenerForCreateRemoveBaseNode() throws InterruptedException {
    final String testPath = ":searchtest1";
    final Node on = new NodeImpl("");
    final Node nn = new NodeImpl("");
    final StringBuilder evt = new StringBuilder();
    StorageListener sl = (event, node1, node2) -> {
      evt.delete(0, 100);
      evt.append(event.toString());
      if (node1 != null) {
        on.update(node1);
      }
      if (node2 != null) {
        nn.update(node2);
      }
    };

    //create a dummy search criteria
    SearchCriteria sc = new SearchCriteria();
    sc.setNodePath(testPath);

    // register the listener
    controller.registerChangeListener(sl, sc);

    assertEquals("old node expected to be empty", ":", on.getPath());
    assertEquals("new node expected to be empty", ":", nn.getPath());
    assertEquals("event expected to be empty", "", evt.toString());

    // adding test node
    Node tn = new NodeImpl(testPath);
    tn.setOwner("testOwner");
    controller.add(tn);
    sleep(100);
    assertEquals("nodes (written and new) are expected to be equal (1)", tn, nn);
    assertEquals("old node expected to be empty", ":", on.getPath());
    assertEquals("event expected to be add", EventType.CREATE.toString(), evt.toString());

    // update with equivalent node (should not trigger an event)
    on.update(new NodeImpl(""));
    nn.update(new NodeImpl(""));
    evt.delete(0, 100);
    controller.update(tn);
    assertEquals("old node expected to be empty", ":", on.getPath());
    assertEquals("new node expected to be empty", ":", nn.getPath());
    assertEquals("event expected to be empty", "", evt.toString());

    // remove node
    controller.delete(testPath);
    sleep(100);
    assertEquals("nodes are expected to be equal (2)", tn, on);
    assertEquals("new node expected to be empty", ":", nn.getPath());
    assertEquals("event expected to be add", evt.toString(), EventType.DELETE.toString());

    //deregister listener
    controller.deregisterChangeListener(sl);
  }

  /**
   * <p>Test the implementation of basic search works as expected.</p>
   */
  @Test
  public void testListenerForCreateRemoveSubNode()
      throws ClassNotFoundException, InterruptedException {
    final String testPath1 = ":device:testDevice1";
    final String testPath2 = ":device:testDevice2";
    final Object notifier = new Object();

    final Node on = new NodeImpl(":null");
    final Node nn = new NodeImpl(":null");
    final StringBuilder evt = new StringBuilder();
    final AtomicInteger nums = new AtomicInteger(0);
    StorageListener sl = (event, node1, node2) -> {
      evt.delete(0, 100);
      evt.append(event.toString());
      if (node1 != null) {
        on.update(node1);
      }
      if (node2 != null) {
        nn.update(node2);
      }
      nums.incrementAndGet();
      System.out.println("#### (EVENT) got new event \"" + event + "\" with change " + node1
          + "(" + on + ")->" + node2);
      synchronized (notifier) {
        notifier.notifyAll();
      }
    };

    //create a dummy search criteria
    SearchCriteria sc = new SearchCriteria();
    sc.setNodePath(":device");

    // register the listener
    controller.registerChangeListener(sl, sc);
    assertEquals("old node expected to be empty", ":null", on.getPath());
    assertEquals("new node expected to be empty", ":null", nn.getPath());
    assertEquals("event expected to be empty", "", evt.toString());
    assertEquals("got sufficient events", nums.get(), 0);

    // adding test node
    Node tn = new NodeImpl(testPath1);
    tn.setOwner("testOwner");
    controller.add(tn);
    synchronized (notifier) {
      notifier.wait(1000);
    }
    assertEquals("got sufficient events", nums.get(), 1);
    assertEquals("old node expected to be empty", ":null", on.getPath());
    assertEquals("nodes (written and new) are expected to be equal (1)", tn, nn);
    assertEquals("event expected to be add", EventType.CREATE.toString(), evt.toString());

    // update with equivalent node (should not trigger an event)
    on.update(new NodeImpl(":null"));
    nn.update(new NodeImpl(":null"));
    evt.delete(0, 100);
    controller.update(tn);
    for (int i = 0; nums.get() < 2 && i < 10; i++) {
      synchronized (notifier) {
        notifier.wait(100);
      }
      ;
    }
    assertEquals("got sufficient events", 1, nums.get());
    assertEquals("old node expected to be empty", ":null", on.getPath());
    assertEquals("new node expected to be empty", ":null", nn.getPath());
    assertEquals("event expected to be empty", "", evt.toString());

    // update with changed node
    on.update(new NodeImpl(":null"));
    nn.update(new NodeImpl(":null"));
    evt.delete(0, 100);
    Node nodeWithoutValue = tn.deepClone();
    Node nodeWithValue = nodeWithoutValue.deepClone();
    nodeWithValue.addValue(new NodeValueImpl("key", "value"));
    controller.update(nodeWithValue);
    for (int i = 0; nums.get() < 2 && i < 10; i++) {
      synchronized (notifier) {
        notifier.wait(100);
      }
      ;
    }
    assertEquals("got bad number of events", 2, nums.get());
    assertEquals("old node mismatch", nodeWithoutValue, on);
    assertEquals("new node mismatch", nodeWithValue, nn);
    assertEquals("event expected to be empty", EventType.UPDATE.toString(), evt.toString());

    // delete node
    on.update(new NodeImpl(":null"));
    nn.update(new NodeImpl(":null"));
    evt.delete(0, 100);
    Node newNode = nodeWithValue.deepClone();
    ((NodeImpl) (newNode)).set(Field.PATH, testPath2);
    controller.rename(testPath1, testPath2);
    for (int i = 0; nums.get() < 3 && i < 10; i++) {
      synchronized (notifier) {
        notifier.wait(100);
      }
    }
    assertEquals("got bad number of events", 3, nums.get());
    assertEquals("old node expected to be empty", nodeWithValue, on);
    assertEquals("new node expected to be empty", newNode, nn);
    assertEquals("event expected to be empty", EventType.RENAME.toString(), evt.toString());

    // remove node
    on.update(new NodeImpl(":null"));
    nn.update(new NodeImpl(":null"));
    evt.delete(0, 100);
    // newNode = controller.get(testPath2);
    controller.delete(testPath2);
    synchronized (notifier) {
      notifier.wait(1000);
    }
    assertEquals("got bad number of events", 4, nums.get());
    assertEquals("nodes are expected to be equal (2)", newNode, on);
    assertEquals("new node expected to be empty", ":null", nn.getPath());
    assertEquals("event expected to be add", evt.toString(), EventType.DELETE.toString());

    //deregister listener
    controller.deregisterChangeListener(sl);
  }


}
