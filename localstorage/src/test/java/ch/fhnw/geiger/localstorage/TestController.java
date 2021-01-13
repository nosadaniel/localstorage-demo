package ch.fhnw.geiger.localstorage;

import static ch.fhnw.geiger.localstorage.Visibility.RED;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

import ch.fhnw.geiger.localstorage.db.GenericController;
import ch.fhnw.geiger.localstorage.db.data.Node;
import ch.fhnw.geiger.localstorage.db.data.NodeImpl;
import ch.fhnw.geiger.localstorage.db.data.NodeValue;
import ch.fhnw.geiger.localstorage.db.data.NodeValueImpl;
import ch.fhnw.geiger.localstorage.db.mapper.DummyMapper;
import java.util.Arrays;
import java.util.Collections;
import org.junit.Test;

/***
 * <p>Test the controller capabilities.</p>
 */
public class TestController {

  // TODO add test reflecting the recursion for child nodes
  public StorageController controller = new GenericController("testOwner", new DummyMapper());

  @Test
  public void testOwnerUpdateOnNode() throws StorageException {
    System.out.println("## Testing controller in " + (new Object() {
    }).getClass().getEnclosingMethod().getName());
    Node node = new NodeImpl("testNode1", "");
    controller.add(node);
    node = controller.get(node.getPath());
    assertEquals("testing that owner is set upon adding", "testOwner", node.getOwner());
  }

  @Test
  public void testStorageNodeCreate() throws StorageException {
    controller.add(new NodeImpl("testNode1", ""));

    // fetch stored node
    Node storedNode = controller.get(":testNode1");

    // check results
    assertEquals("testOwner", storedNode.getOwner());
    assertEquals("testNode1", storedNode.getName());
    assertEquals(":testNode1", storedNode.getPath());
    assertTrue(RED == storedNode.getVisibility());
  }

  @Test
  public void testStorageNodeAdd() throws StorageException {
    controller.add(new NodeImpl("parent1", ""));
    controller.add(new NodeImpl("name2", ":parent1"));

    // get the record
    Node storedNode = controller.get(":parent1:name2");

    // check results
    assertEquals("testOwner", storedNode.getOwner());
    assertEquals("name2", storedNode.getName());
    assertEquals(":parent1:name2", storedNode.getPath());
    assertTrue(RED == storedNode.getVisibility());
  }

  /**
   * depends on correct functionality of the StorageController.create() function
   */
  @Test
  public void testStorageNodeUpdate() throws StorageException {
    // create original node
    controller.add(new NodeImpl("parent1", ""));

    // updated Node with different visibility children
    NodeImpl node = new NodeImpl("testNode1", ":parent1", Visibility.GREEN);
    controller.add(node);
    assertEquals("testOwner", node.getOwner());
    NodeImpl sn = new NodeImpl("testChild1", ":parent1:testNode1");
    controller.add(sn);
    node.setVisibility(Visibility.RED);
    node.addChild(sn);

    // update with node from above
    controller.update(node);

    // get the record
    Node storedNode = controller.get(":parent1:testNode1");

    // check results
    assertEquals("testOwner", storedNode.getOwner());
    assertEquals("testNode1", storedNode.getName());
    assertEquals(":parent1:testNode1", storedNode.getPath());
    assertEquals("testChild1", storedNode.getChildNodesCsv());
    assertTrue("Visibility is incorrect", Visibility.RED == storedNode.getVisibility());
  }

  @Test
  public void testValueUpdate() throws StorageException {
    // add value
    NodeValue value = new NodeValueImpl("key1", "valueFirst");
    try {
      controller.add(new NodeImpl("testNode1", ":parent1"));
      fail("Should raise an exception as parent node does not exist");
    } catch (StorageException e) {
      // this is the expected behavior as the parent node does not exist
    }
    NodeImpl[] n = new NodeImpl[]{
        new NodeImpl("parent1"),
        new NodeImpl("testNode1", ":parent1")
      };
    for (NodeImpl tn : n) {
      System.out.println("## creating new node " + tn.getPath() + " (parent of "
          + tn.getParentPath() + ")");
      controller.add(tn);
    }

    // add a value
    System.out.println("## adding value");
    controller.addValue(":parent1:testNode1", new NodeValueImpl("key1", "valuefirst"));

    // update value
    System.out.println("## updating value");
    NodeValue value2 = new NodeValueImpl("key1", "valueSecond");
    controller.updateValue(":parent1:testNode1", value2);

    // get the record
    System.out.println("## testing updated value");
    Node n2 = controller.get(":parent1:testNode1");
    assertTrue("stored value \"" + n2.getValue(value2.getKey()).getValue()
            + "\" does not match \"" + value2.getValue() + "\"",
        value2.getValue().equals(n2.getValue(value2.getKey()).getValue()));

    try {
      System.out.println("## testing removal of node with child nodes ("
          + n[n.length - 1].getPath() + ")");
      controller.delete(n[0].getPath());
      fail("shoud raise an exception as child classes exist");
    } catch (StorageException e) {
      // this is expected as the node has subnodes
    }

    Collections.reverse(Arrays.asList(n));
    for (NodeImpl tn : n) {
      System.out.println("## removing node " + tn.getPath() + " (parent of "
          + tn.getParentPath() + ")");
      controller.delete(tn.getPath());
    }
  }

  @Test
  public void testStorageNodeRemove() throws StorageException {
    controller.add(new NodeImpl("parent1", ""));
    NodeImpl node = new NodeImpl("name1", ":parent1");
    controller.add(node);
    Node removed = controller.delete(":parent1:name1");

    // check results
    assertEquals(node.getOwner(), removed.getOwner());
    assertEquals(node.getName(), removed.getName());
    assertEquals(node.getPath(), removed.getPath());
    assertTrue(RED == node.getVisibility());
  }

  @Test
  public void testStorageNodeSearch() {

  }

  @Test
  public void testRegisterChangeListener() {

  }

  @Test
  public void testNotifyChangeListener() {

  }

  @Test
  public void testRenameNode() throws StorageException {
    NodeImpl[] nodes = new NodeImpl[]{
        new NodeImpl("renameTests"),
        new NodeImpl("name1", ":renameTests"),
        new NodeImpl("name2", ":renameTests"),
        new NodeImpl("name21", ":renameTests:name2"),
        new NodeImpl("name3", ":renameTests")
      };
    for (NodeImpl n : nodes) {
      controller.add(n);
    }
    controller.rename(":renameTests:name2", ":renameTests:name2a");
    try {
      controller.get(":renameTests:name2");
      fail("renaming node seems unsuccessful (old node still exists)");
    } catch (StorageException e) {
      // this is expected to happen
    }
    assertTrue("renaming node seems unsuccessful (new node missing)",
        controller.get(":renameTests:name2a") != null);
    assertTrue("renaming node seems unsuccessful (new node name wrong)",
        "name2a".equals(controller.get(":renameTests:name2a").getName()));
    assertTrue("renaming node seems unsuccessful (new node path wrong)",
        ":renameTests:name2a".equals(controller.get(":renameTests:name2a").getPath()));
    assertTrue("renaming node seems unsuccessful (sub-node missing)",
        controller.get(":renameTests:name2a:name21") != null);
    assertTrue("renaming node seems unsuccessful (sub-node name wrong)",
        "name21".equals(controller.get(":renameTests:name2a:name21").getName()));
    assertTrue("renaming node seems unsuccessful (sub-node path wrong)",
        ":renameTests:name2a:name21".equals(
            controller.get(":renameTests:name2a:name21").getPath()));
  }
}
