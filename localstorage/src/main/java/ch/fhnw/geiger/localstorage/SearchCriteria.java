package ch.fhnw.geiger.localstorage;

import ch.fhnw.geiger.localstorage.db.data.Field;
import ch.fhnw.geiger.localstorage.db.data.Node;
import ch.fhnw.geiger.localstorage.db.data.NodeImpl;
import ch.fhnw.geiger.localstorage.db.data.NodeValue;
import ch.fhnw.geiger.serialization.SerializerHelper;
import ch.fhnw.geiger.totalcross.ByteArrayInputStream;
import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * <p>An object that can hold all possible search criteria.</p>
 *
 * <p>Each criteria can either be set or left blank the search will match all
 * nonempty criteria.
 * </p>
 *
 * <p>TODO: add recursion support</p>
 */
public class SearchCriteria { //extends Serializer {

  private static final long serialversionUID = 87128319541L; // TODO generate serialversionUID

  /**
   * <p>Defines the type of comparator to be used when accessing an ordinal.</p>
   */
  public enum ComparatorType {
    STRING,
    DATETIME
  }

  private final Map<Field, String> values = new HashMap<>();

  public String getNodeOwner() {
    return values.get(Field.OWNER);
  }

  public String setNodeOwner(String nodeOwner) {
    return values.put(Field.OWNER, nodeOwner);
  }

  public String getNodeName() {
    return values.get(Field.NAME);
  }

  public String setNodeName(String nodeName) {
    return values.put(Field.NAME, nodeName);
  }

  public String getNodePath() {
    return values.get(Field.PATH);
  }

  public String setNodePath(String nodePath) {
    return values.put(Field.PATH, nodePath);
  }

  public String getNodeValueKey() {
    return values.get(Field.KEY);
  }

  public String setNodeValueKey(String nodeValueKey) {
    return values.put(Field.KEY, nodeValueKey);
  }

  public String getNodeValueValue() {
    return values.get(Field.VALUE);

  }

  public String setNodeValueValue(String nodeValue) {
    return values.put(Field.OWNER, nodeValue);
  }

  public String getNodeValueType() {
    return values.get(Field.TYPE);
  }

  public String setNodeValueType(String nodeValueType) {
    return values.put(Field.OWNER, nodeValueType);
  }

  public String get(Field f) {
    return values.get(f);
  }

  public String set(Field f, String value) {
    return values.put(f, value);
  }

  public String getNodeValueLastModified() {
    return values.get(Field.LAST_MODIFIED);
  }

  public String setNodeValueLastModified(String nodeValueLastModified) {
    return values.put(Field.LAST_MODIFIED, nodeValueLastModified);
  }

  /**
   * <p>Evaluates a provided node against this criteria.</p>
   *
   * @param node the node to be evalueated
   * @return true iif the node matches the criteria
   */
  public boolean evaluate(Node node) {
    // evaluate node criteria
    try {
      // node path is a sub tree search
      if (!getNodePath().startsWith(getNodePath())) {
        return false;
      }
      // compare other ordinals
      for (Field f : new Field[]{Field.OWNER, Field.VISIBILITY}) {
        if (values.get(f) != null && !regexEvalString(values.get(f), ((NodeImpl) (node)).get(f))) {
          return false;
        }
      }
    } catch (ClassNotFoundException e) {
      throw new RuntimeException("OOPS! This was deemed to be impossible... "
          + "please check with developer", e);
    }
    // getting values to check
    Map<String, NodeValue> nodeValues = node.getValues();

    // evaluate key, type and value criteria
    if (values.get(Field.KEY) == null && (values.get(Field.VALUE) != null
        || values.get(Field.TYPE) != null)) {
      // key is not set but other values are so we find a matching value
      for (Map.Entry<String, NodeValue> e : nodeValues.entrySet()) {
        boolean r3 = values.get(Field.TYPE) == null || values.get(Field.TYPE) != null
            && !regexEvalString(values.get(Field.TYPE), e.getValue().getType());
        boolean r2 = values.get(Field.VALUE) == null || values.get(Field.VALUE) != null
            && !regexEvalString(values.get(Field.VALUE), e.getValue().getValue());
        if (r2 && r3) {
          return true;
        }
      }
      return false;
    } else if (values.get(Field.KEY) != null) {
      // key is set; we just compare an eventual value
      NodeValue nv = nodeValues.get(get(Field.KEY));
      if (nv == null) {
        return false;
      }
      if (!regexEvalString(values.get(Field.TYPE), nv.getType())) {
        return false;
      }
      if (!regexEvalString(values.get(Field.VALUE), nv.getValue())) {
        return false;
      }
    }
    return true;
  }

  private boolean regexEvalString(String regex, String value) {
    if (regex == null) {
      return true;
    }
    return regex.matches(value);
  }

  /**
   * <p>Serialize a SearchCriteria.</p>
   *
   * @param out the ByteArrayOutputStream to write to
   * @throws IOException if it cannot be serialized
   */
  //@Override
  public void toByteArrayStream(ByteArrayOutputStream out) throws IOException {
    // TODO
    // write object identifier
    SerializerHelper.writeLong(out, serialversionUID);

    // TODO serialize searchcriterias
  }

  /**
   * <p>Deserializes a NodeValue from a byteStream.</p>
   *
   * @param in the stream to be read
   * @return the deserialized NodeValue
   * @throws IOException if an exception happens deserializing the stream
   */
  public static SearchCriteria fromByteArrayStream(ByteArrayInputStream in) throws IOException {
    // TODO
    return null;
  }

}
