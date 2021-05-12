package ch.fhnw.geiger.localstorage;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;

import ch.fhnw.geiger.localstorage.db.data.Node;
import ch.fhnw.geiger.localstorage.db.data.NodeImpl;
import ch.fhnw.geiger.localstorage.db.data.NodeValueImpl;
import ch.fhnw.geiger.totalcross.ByteArrayInputStream;
import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;
import ch.fhnw.geiger.totalcross.Locale;
import java.io.IOException;
import org.junit.Test;

/**
 * <p>Test class for testing storage serialization.</p>
 */
public class TestSerializer {

  @Test
  public void testNodeSerialization() throws Exception {
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

  @Test
  public void testExceptionSerialization() throws Exception {
    StorageException se = new StorageException("bla", null);
    ByteArrayOutputStream out = new ByteArrayOutputStream();
    se.toByteArrayStream(out);
    StorageException se2 = StorageException.fromByteArrayStream(
        new ByteArrayInputStream(out.toByteArray()));
    assertEquals(se.getMessage(), se2.getMessage());
    assertArrayEquals(se.getStackTrace(), se2.getStackTrace());
    System.out.println("= Serialized Stacktrace Output ===================="
        + "==================================");
    se2.printStackTrace();
  }

  @Test
  public void testNestedExceptionSerialization() throws Exception {
    StorageException se = new StorageException("bla", new StorageException("Test",
        new IOException("test2")));
    ByteArrayOutputStream out = new ByteArrayOutputStream();
    se.toByteArrayStream(out);
    StorageException se2 = StorageException.fromByteArrayStream(
        new ByteArrayInputStream(out.toByteArray()));
    assertEquals("verifying exception message",
        se.getMessage(),
        se2.getMessage());
    assertArrayEquals("stacktrace of root cause",
        se.getStackTrace(),
        se2.getStackTrace());
    // testing stacktrace of cause
    assertEquals("verifying exception message",
        se.getCause().getMessage(),
        se2.getCause().getMessage());
    assertArrayEquals("verifying stacktrace of nested cause",
        se.getCause().getStackTrace(),
        se2.getCause().getStackTrace());
    // testing stacktrace of cause
    assertEquals("verifying exception message",
        se.getCause().getCause().getMessage(),
        se2.getCause().getCause().getMessage());
    assertArrayEquals("verifying stacktrace of nested cause",
        se.getCause().getCause().getStackTrace(),
        se2.getCause().getCause().getStackTrace());
    // testing last cause empty
    assertNull("empty last cause of chain", se2.getCause().getCause().getCause());
    System.out.println("= Serialized Stacktrace Output ===================="
        + "==================================");
    se2.printStackTrace();
  }

  @Test
  public void testSearchCriteriaSerialization() throws Exception {
    SearchCriteria sc = new SearchCriteria();
    sc.setNodeName("test");
    sc.setNodeValueType("bla");
    ByteArrayOutputStream out = new ByteArrayOutputStream();
    sc.toByteArrayStream(out);
    SearchCriteria sc2 = SearchCriteria.fromByteArrayStream(
        new ByteArrayInputStream(out.toByteArray()));
    assertEquals("verifying criteria equivalence", sc.toString(), sc2.toString());
  }

  @Test
  public void testByteArrayWrappers() throws Exception {
    SearchCriteria sc = new SearchCriteria();
    sc.setNodeName("test");
    sc.setNodeValueType("bla");
    SearchCriteria sc2 = SearchCriteria.fromByteArray(sc.toByteArray());
    assertEquals("verifying criteria equivalence", sc, sc2);
  }



}