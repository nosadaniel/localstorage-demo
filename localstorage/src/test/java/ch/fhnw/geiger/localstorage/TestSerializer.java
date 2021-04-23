package ch.fhnw.geiger.localstorage;

import static org.junit.Assert.assertEquals;

import ch.fhnw.geiger.localstorage.db.data.Node;
import ch.fhnw.geiger.localstorage.db.data.NodeImpl;
import ch.fhnw.geiger.localstorage.db.data.NodeValueImpl;
import ch.fhnw.geiger.totalcross.ByteArrayInputStream;
import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;
import java.util.Locale;
import org.junit.Test;

/**
 * <p>Test class for testing storage serialization.</p>
 */
public class TestSerializer {

  @Test
  public void testSerialization() throws Exception {
    NodeValueImpl nodeValue = new NodeValueImpl("key", "value");
    nodeValue.setValue("de-value", Locale.GERMAN);
    nodeValue.setValue("de-de-value", Locale.GERMANY);
    NodeImpl node = new NodeImpl("name", "path");
    node.addValue(nodeValue);

    ByteArrayOutputStream bout = new ByteArrayOutputStream();
    node.toByteArrayStream(bout);
    ByteArrayInputStream bin = new ByteArrayInputStream(bout.toByteArray());
    Node node2 = NodeImpl.fromByteArrayStream(bin);
    assertEquals("Cloned nodes are not equal", node, node2);
  }
}
