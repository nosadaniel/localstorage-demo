package ch.fhnw.geiger.localstorage;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotEquals;
import static org.junit.Assert.assertNull;

import ch.fhnw.geiger.localstorage.db.data.NodeValue;
import ch.fhnw.geiger.localstorage.db.data.NodeValueImpl;
import ch.fhnw.geiger.totalcross.Locale;
import org.junit.Test;

/***
 * <p>Test node value capabilities.</p>
 */
public class TestNodeValue {

  @Test
  public void testNodeValueGetSet() {
    // testing general storage and getters with default values
    NodeValueImpl nodeValue = new NodeValueImpl("key", "value");
    assertEquals("test key getter", "key", nodeValue.getKey());
    assertEquals("test value getter", "value", nodeValue.getValue());
    assertNull("test description getter", nodeValue.getDescription());
    assertNull("test type getter", nodeValue.getType());

    // testing setters
    nodeValue.setValue("newValue");
    assertEquals("test value setter", "newValue", nodeValue.getValue());
    nodeValue.setType("newType");
    assertEquals("test type setter", "newType", nodeValue.getType());
    nodeValue.setDescription("newDescription");
    assertEquals("test description setter", "newDescription", nodeValue.getDescription());
  }

  @Test
  public void testNodeValueLanguageSupport() {
    NodeValueImpl nodeValue = new NodeValueImpl("key", "value");
    assertEquals("test key getter", "value", nodeValue.getValue());
    assertEquals("test key getter (en)", "value", nodeValue.getValue("en"));
    assertEquals("test key getter (de)", "value", nodeValue.getValue("de"));
    assertEquals("test key getter (en-us)", "value", nodeValue.getValue("en-US"));

    // with multiple languages
    nodeValue.setValue("de-value", Locale.GERMAN);
    nodeValue.setValue("de-de-value", Locale.GERMANY);
    assertEquals("test key getter (DEFAULT)", "value", nodeValue.getValue());
    assertEquals("test key getter (en)", "value", nodeValue.getValue("en"));
    assertEquals("test key getter (en-us)", "value", nodeValue.getValue("en-US"));
    assertEquals("test key getter (de)", "de-value", nodeValue.getValue("de"));
    assertEquals("test key getter (de-de)", "de-de-value", nodeValue.getValue("de-DE"));
    assertEquals("test key getter (de-ch)", "de-value", nodeValue.getValue("de-ch"));
  }

  @Test
  public void testNodeValueEquals() {
    NodeValueImpl nodeValue = new NodeValueImpl("key", "value");
    nodeValue.setValue("de-value", Locale.GERMAN);
    nodeValue.setValue("de-de-value", Locale.GERMANY);
    NodeValue nodeValue2 = nodeValue.deepClone();

    assertEquals("test value getter", nodeValue2.getValue(), nodeValue.getValue());
    assertEquals("test value getter", nodeValue2, nodeValue);
    nodeValue.setValue("de-ch-value", new Locale("de", "ch"));
    assertNotEquals("test unequal nodes", nodeValue, nodeValue2);

  }
}
