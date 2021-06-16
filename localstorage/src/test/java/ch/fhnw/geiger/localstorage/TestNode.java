package ch.fhnw.geiger.localstorage;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;

import ch.fhnw.geiger.localstorage.db.data.Node;
import ch.fhnw.geiger.localstorage.db.data.NodeImpl;
import org.junit.Assert;
import org.junit.Test;

/***
 * <p>Test the node capabilities.</p>
 */
public class TestNode {

  @Test
  public void testNodeDefaults() {
    NodeImpl node = new NodeImpl("name", "path");
    assertNull("test predefined owner", node.getOwner());
    assertEquals("test predefined owner", node.getVisibility(), Visibility.RED);
  }

  @Test
  public void testNodeEquals() throws StorageException {
    NodeImpl node = new NodeImpl("name", "path");
    Node node2 = node.deepClone();
    assertEquals("test predefined owner", node, node2);
  }

  @Test
  public void testNodeEqualsOrdinals() throws StorageException {
    NodeImpl node = new NodeImpl("name", "path");
    Node node2 = node.deepClone();
    node2.setOwner("newOwner");
    Assert.assertNotEquals("test ordinal unequal detected", node, node2);
  }

  @Test
  public void testNodeEqualsChildren() throws StorageException {
    NodeImpl node = new NodeImpl("name", "path");
    Node node2 = node.deepClone();
    node2.addChild(new NodeImpl("name2", "path:name"));
    Assert.assertNotEquals("test children unequal detected", node, node2);
  }

}
