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
    assertEquals("Stack traces not equal in size",se.getStackTrace().length,se2.getStackTrace().length);
    for( int i=0; i<se.getStackTrace().length;i++) {
      compareStackTraceElements(i,se.getStackTrace()[i], se2.getStackTrace()[i]);
    }
    System.out.println("= Serialized Stacktrace Output ===================="
        + "==================================");
    se2.printStackTrace();
  }

  private void compareStackTraceElements(int id,StackTraceElement se, StackTraceElement se2) {
    assertEquals("array elements differ in classname of element ["+id+"]",
        se.getClassName(), se2.getClassName());
    assertEquals("array elements differ in filename of element ["+id+"]",
        se.getFileName(), se2.getFileName());
    assertEquals("array elements differ in methodname of element ["+id+"]",
        se.getMethodName(), se2.getMethodName());
    assertEquals("array elements differ in line number of element ["+id+"]",
        se.getLineNumber(), se2.getLineNumber());
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
    assertEquals("Stack traces not equal in size",
        se.getStackTrace().length,se2.getStackTrace().length);
    for( int i=0; i<se.getStackTrace().length;i++) {
      compareStackTraceElements(i,se.getStackTrace()[i],se2.getStackTrace()[i]);
    }
    // testing stacktrace of cause
    assertEquals("verifying exception message",
        se.getCause().getMessage(),
        se2.getCause().getMessage());
    assertEquals("Stack traces not equal in size",
        se.getCause().getStackTrace().length,se2.getCause().getStackTrace().length);
    for( int i=0; i<se.getCause().getStackTrace().length;i++) {
      compareStackTraceElements(i,se.getCause().getStackTrace()[i],se2.getCause().getStackTrace()[i]);
    }
    // testing stacktrace of cause
    assertEquals("verifying exception message",
        se.getCause().getCause().getMessage(),
        se2.getCause().getCause().getMessage());
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