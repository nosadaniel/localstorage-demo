package ch.fhnw.geiger.localstorage.db.mapper;

import ch.fhnw.geiger.localstorage.SearchCriteria;
import ch.fhnw.geiger.localstorage.StorageController;
import ch.fhnw.geiger.localstorage.StorageException;
import ch.fhnw.geiger.localstorage.Visibility;
import ch.fhnw.geiger.localstorage.db.GenericController;
import ch.fhnw.geiger.localstorage.db.data.Field;
import ch.fhnw.geiger.localstorage.db.data.Node;
import ch.fhnw.geiger.localstorage.db.data.NodeImpl;
import ch.fhnw.geiger.localstorage.db.data.NodeValue;
import ch.fhnw.geiger.localstorage.db.data.NodeValueImpl;
import java.sql.Clob;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * <p>This class maps the DBInterface functions to an H2SQL database.</p>
 *
 * @author Sacha Leemann
 */
public class H2SqlMapper extends AbstractMapper {

  private static final String initString = ""
      + "CREATE TABLE storage_node (\n"
      + "path VARCHAR(1024) NULL PRIMARY KEY,\n"
      + "owner VARCHAR(40),\n"
      + "name VARCHAR(40) NOT NULL,\n"
      + "visibility ENUM('RED', 'AMBER', 'GREEN', 'WHITE') NOT NULL,\n"
      + "children VARCHAR(1024) NULL\n"
      + ");\n"
      + "\n"
      + "CREATE TABLE node_value (\n"
      + "path VARCHAR(1024) NOT NULL,\n"
      + "key VARCHAR(40) NOT NULL,\n"
      + "value VARCHAR(16384),\n"
      + "type VARCHAR(40),\n"
      + "description varchar(1024),\n"
      + "last_modified VARCHAR(20) NOT NULL\n"
      + ");\n"
      + "\n"
      + "ALTER TABLE node_value ADD CONSTRAINT node_value_pk PRIMARY KEY(path,key);\n"
      + "ALTER TABLE node_value ADD FOREIGN KEY(path) REFERENCES storage_node(path);\n"
      + "";

  private Connection conn;
  private final String jdbcUrl;
  private final String jdbcUsername;
  private final String jdbcPassword;
  private StorageController controller = null;

  /**
   * <p>Constructor for a generic, persisting data Mapper based on H2SQL.</p>
   *
   * <p>If the database does not exist it will be created.</p>
   *
   * @param jdbcUrl      the url to connect to
   * @param jdbcUsername the username of the database
   * @param jdbcPassword the password of the database
   */
  public H2SqlMapper(String jdbcUrl, String jdbcUsername, String jdbcPassword) {
    // Connect to the database
    this.jdbcUrl = jdbcUrl;
    this.jdbcUsername = jdbcUsername;
    this.jdbcPassword = jdbcPassword;

    try {
      // connect only if database already exists
      conn = DriverManager.getConnection(jdbcUrl + ";IFEXISTS=TRUE", jdbcUsername, jdbcPassword);
      // check if database is already initialized
      conn.prepareStatement("SELECT * FROM node_value LIMIT 1;").executeQuery();
    } catch (SQLException e) {
      // database does not exists it should be created
      System.out.println("## got exception " + e + "... initializing database");
      initialize();
    }
  }

  @Override
  public void setController(StorageController controller) {
    this.controller = controller;
  }

  private void initialize() {
    try {
      conn = DriverManager.getConnection(jdbcUrl, jdbcUsername, jdbcPassword);
      conn.prepareStatement(initString).executeUpdate();
    } catch (SQLException e) {
      try {
        // delete malfunctioning database
        conn.prepareStatement("drop all objects delete files").execute();
      } catch (SQLException e2) {
        throw new StorageException("Whoops... error while tearing down database", e2);
      }
      throw new StorageException("Could not initialize database", e);
    }
  }

  @Override
  public NodeImpl get(String path) throws StorageException {
    checkPath(path);
    getSanity(path);
    NodeImpl res = null;
    String sqlStatement = "SELECT path, owner, name, visibility, children "
        + "FROM storage_node WHERE path = ?";
    try {
      PreparedStatement ps = conn.prepareStatement(sqlStatement);
      ps.setString(1, path);
      ResultSet rs = ps.executeQuery();
      if (!rs.next()) {
        throw new StorageException("Node does not exist");
      } else {
        res = new NodeImpl(rs.getString("path"));
        String owner = rs.getString("owner");
        if (owner != null) {
          res.setOwner(owner);
        }
        res.setVisibility(Visibility.valueOf(rs.getString("visibility")));
        String children = rs.getString("children");
        // get children as skeleton
        if (!"".equals(children)) {
          for (String childName : children.split(",")) {
            res.addChild(new NodeImpl(path + ":" + childName, controller));
          }
        }
      }
    } catch (SQLException e) {
      e.printStackTrace();
      throw new StorageException("Could not retrieve node \"" + path + "\"");
    }

    // get all values and add to node
    sqlStatement = "SELECT path,key,value,type,description,last_modified "
        + "FROM node_value WHERE path = ?";
    try {
      PreparedStatement ps = conn.prepareStatement(sqlStatement);
      ps.setString(1, path);
      ResultSet rs = ps.executeQuery();
      while (rs.next()) {
        NodeValue value = new NodeValueImpl(rs.getString("key"), rs.getString("value"),
            rs.getString("type"), rs.getString("description"),
            Long.valueOf(rs.getString("last_modified")));
        res.addValue(value);
      }
    } catch (SQLException e) {
      throw new StorageException("Could not retrieve values for node \"" + path + "\"", e);
    }

    return res;
  }

  @Override
  public void add(Node node) {
    checkPath(node);
    // TODO This seems like bad coding, as we expect an exception to be thrown from
    // get as only node are added which do not exist yet
    // how to do this cleaner?
    try {
      get(node.getPath());
      // throw temporary exception
      throw new NullPointerException("Node does already exist");
    } catch (StorageException e) {
      // it is supposed to throw a storage exception if the node does not exist
      // this is the normal case, therefore, nothing is done here
    } catch (NullPointerException n) {
      throw new StorageException("Node already exists");
    }
    if (node.getParentPath() != null && !"".equals(node.getParentPath())) {
      if (get(node.getParentPath()) == null) {
        throw new StorageException("Parent node \"" + node.getParentPath() + "\" does not exist");
      }
      // add reference to parent
      NodeImpl parent = get(node.getParentPath());
      parent.addChild(node);
      update(parent);
    }
    String sqlStatement = "INSERT INTO storage_node(path, owner, name, visibility, children) "
        + "VALUES (?,?,?,?,?)";
    try {
      PreparedStatement ps = conn.prepareStatement(sqlStatement);
      ps.setString(1, node.getPath());
      ps.setString(2, node.getOwner());
      ps.setString(3, node.getName());
      ps.setInt(4, node.getVisibility().ordinal());
      ps.setString(5, node.getChildNodesCsv());
      ps.execute();
    } catch (SQLException e) {
      throw new StorageException("Could not add new node", e);
    }
    // check if values exists and add them
    for (NodeValue nv : node.getValues().values()) {
      addValue(node.getPath(), nv);
    }
  }

  @Override
  public void update(Node node) {
    checkPath(node);
    get(node.getPath()); // checks if node exists, throws storage exception if not exists

    String sqlStatement = "UPDATE storage_node SET(owner, visibility, children) = (?,?,?) "
        + "WHERE path = ?";
    try {
      PreparedStatement ps = conn.prepareStatement(sqlStatement);
      ps.setString(1, node.getOwner());
      ps.setInt(2, node.getVisibility().ordinal());
      ps.setString(3, node.getChildNodesCsv());
      ps.setString(4, node.getPath());
      ps.execute();

      // Values are being created if they dont exist else updated
      for (Map.Entry<String, NodeValue> entry : node.getValues().entrySet()) {
        if (getValue(node.getPath(), entry.getKey()) == null) {
          addValue(node.getPath(), entry.getValue());
        } else {
          updateValue(node.getPath(), entry.getValue());
          ;
        }
      }
    } catch (SQLException e) {
      throw new StorageException("Could not update node", e);
    }
  }

  @Override
  public void rename(String oldPath, String newPath) throws StorageException {
    checkPath(oldPath);
    checkPath(newPath);
    NodeImpl oldNode = get(oldPath);
    NodeImpl newNode = new NodeImpl(newPath);
    // set missing properties
    newNode.setOwner(oldNode.getOwner());
    newNode.setVisibility(oldNode.getVisibility());

    // add values
    for (NodeValue nv : oldNode.getValues().values()) {
      newNode.addValue(nv);
    }

    // insert new node
    add(newNode);

    // rename all children
    for (Node n : oldNode.getChildren().values()) {
      rename(n.getPath(), newNode.getPath() + GenericController.PATH_DELIMITER + n.getName());
    }

    // remove old node
    remove(oldPath);
  }

  private void addValue(String path, NodeValue value) {
    checkPath(path);
    if (value == null) {
      throw new NullPointerException();
    }
    get(path); // check if node exists

    if (getValue(path, value.getKey()) != null) {
      throw new StorageException("Value already exists");
    }
    String sqlStatement = "INSERT INTO node_value (path, key, value, type, description, "
        + "last_modified) VALUES (?,?,?,?,?,?)";
    try {
      PreparedStatement ps = conn.prepareStatement(sqlStatement);
      ps.setString(1, path);
      ps.setString(2, value.getKey());
      ps.setString(3, value.getValue());
      ps.setString(4, value.getType());
      Clob clob = conn.createClob();
      clob.setString(1, value.getDescription());
      ps.setClob(5, clob);
      ps.setString(6, String.valueOf(value.getLastModified()));
      ps.execute();
    } catch (SQLException e) {
      throw new StorageException("Could not create value \"" + value.getKey() + "\"", e);
    }
  }

  private NodeValue removeValue(String path, String key) {
    if (key == null || "".equals(path)) {
      throw new NullPointerException();
    }
    get(path); // check if node exists

    // get value
    NodeValue value = getValue(path, key);
    if (value == null) {
      throw new StorageException("Key \"" + key + "\" does not exist");
    }
    // remove value
    String sqlDeleteStatement = "DELETE FROM node_value WHERE (path = ? AND key = ?)";
    try {
      PreparedStatement psDelete = conn.prepareStatement(sqlDeleteStatement);
      psDelete.setString(1, path);
      psDelete.setString(2, key);
      psDelete.execute();
    } catch (SQLException e) {
      e.printStackTrace();
      throw new StorageException("Could not delete value");
    }
    return value;
  }

  private void updateValue(String path, NodeValue value) {
    checkPath(path);
    if (value == null || "".equals(path)) {
      throw new NullPointerException();
    }
    if (get(path) == null) {
      throw new StorageException("Node does not exist");
    }
    if (getValue(path, value.getKey()) == null) {
      throw new StorageException("Key \"" + value.getKey() + "\" does not exist");
    }
    removeValue(path, value.getKey());
    addValue(path, value);
  }

  @Override
  public NodeImpl remove(String path) {
    NodeImpl oldNode = get(path);
    if (!"".equals(oldNode.getChildNodesCsv())) {
      throw new StorageException("Node does have childs... cannot remove " + oldNode.getName());
    }

    // remove values
    for (NodeValue nv : oldNode.getValues().values()) {
      removeValue(path, nv.getKey());
    }

    // remove the node
    String sqlStatement = "DELETE FROM storage_node WHERE path = ?";
    try {
      PreparedStatement ps = conn.prepareStatement(sqlStatement);
      ps.setString(1, path);
      ps.execute();
    } catch (SQLException e) {
      throw new StorageException("Could not remove Node", e);
    }

    // remove reference from parent
    NodeImpl parentNode = get(oldNode.getParentPath());
    parentNode.removeChild(oldNode.getName());
    update(parentNode);

    // return node
    return oldNode;
  }

  @Override
  public NodeValue getValue(String path, String key) {
    if ("".equals(path) || "".equals(key)) {
      throw new NullPointerException();
    }
    checkPath(path);
    get(path); // check if node exists

    String sqlSelectStatement = "SELECT path,key,value,type,description,last_modified "
        + "FROM node_value WHERE (path = ? and key = ?)";
    NodeValue value = null;
    try {
      PreparedStatement psSelect = conn.prepareStatement(sqlSelectStatement);
      psSelect.setString(1, path);
      psSelect.setString(2, key);
      ResultSet rs = psSelect.executeQuery();

      if (!rs.next()) {
        return value; // returning a null value to use this method as an pseudo "contains"
      }

      // add properties
      value = new NodeValueImpl(rs.getString("key"), rs.getString("value"),
          rs.getString("type"), rs.getString("description"),
          rs.getLong("last_modified"));

    } catch (SQLException e) {
      throw new StorageException(
          "Something went wrong while trying to retrieve the value " + key + " from " + path, e);
    }
    return value;
  }

  @Override
  public List<Node> search(SearchCriteria criteria) {
    String sqlNodeSearch = "SELECT path,owner,name,visibility,children FROM storage_node "
        + "WHERE (path = ? and owner = ? and name = ? and visibility = ?)";
    String sqlValueSearch = "SELECT path,key,value,type,description,last_modified "
        + "FROM node_value WHERE (path = ? and key = ? and value = ? and type = ? "
        + "and last_modified = ?)";
    Map<String, NodeImpl> nodes = new HashMap<String, NodeImpl>();
    Map<String, NodeValue> values = new HashMap<String, NodeValue>();
    try {
      // get nodes
      PreparedStatement psSelect = conn.prepareStatement(sqlNodeSearch);
      psSelect.setString(1, "".equals(criteria.getNodePath()) ? "*" : criteria.getNodePath());
      psSelect.setString(2, "".equals(criteria.getNodeOwner()) ? "*" : criteria.getNodeOwner());
      psSelect.setString(3, "".equals(criteria.getNodeName()) ? "*" : criteria.getNodeName());
      psSelect.setString(4, "".equals(criteria.get(Field.VISIBILITY))
          ? "*" : criteria.get(Field.VISIBILITY));
      // TODO check if this actually works for Visibility

      ResultSet rs = psSelect.executeQuery();

      // add all Nodes that matched the criteria
      while (rs.next()) {
        String path = rs.getString("path");
        nodes.put(path, get(path));
      }

      // get values
      psSelect = conn.prepareStatement(sqlValueSearch);
      psSelect.setString(1, "".equals(criteria.getNodePath())
          ? "*" : criteria.getNodePath());
      psSelect.setString(2, "".equals(criteria.getNodeValueKey())
          ? "*" : criteria.getNodeValueKey());
      psSelect.setString(3, "".equals(criteria.getNodeValueValue())
          ? "*" : criteria.getNodeValueValue());
      psSelect.setString(4, "".equals(criteria.getNodeValueType())
          ? "*" : criteria.getNodeValueType());
      psSelect.setString(5,
          "".equals(criteria.getNodeValueLastModified())
              ? "*" : criteria.getNodeValueLastModified());
      rs = psSelect.executeQuery();

      // add values that matched the criteria
      while (rs.next()) {
        String path = rs.getString("path");
        values.put(path, getValue(path, rs.getString("key")));
      }
    } catch (SQLException e) {
      e.printStackTrace();
      throw new StorageException("Something went wrong while trying to execute the search");
    }

    // Currently all missing Nodes (if any) for values get added to the list in
    // order to include the values.
    for (String path : values.keySet()) {
      if (!nodes.keySet().contains(path)) {
        // get missing node
        nodes.put(path, get(path));
      }
      // add value to existing node
      nodes.get(path).addValue(values.get(path));
    }
    return new ArrayList<Node>(nodes.values());
  }

  @Override
  public void close() {
    try {
      conn.prepareStatement("SHUTDOWN;").executeUpdate();
      conn.close();
    } catch (SQLException e) {
      throw new RuntimeException("OOPS... unexpected exception", e);
    }
  }

  @Override
  public void flush() {
    // nothing to do with H2SQL; Flushes approx. every second
  }

  @Override
  public void zap() {
    // Usually Truncate would be used, but it does not work with referenced tables
    String sqlStatement1 = "DELETE FROM node_value";
    String sqlStatement2 = "DELETE FROM storage_node";
    try {
      (conn.createStatement()).execute(sqlStatement1);
      (conn.createStatement()).execute(sqlStatement2);
    } catch (SQLException e) {
      throw new StorageException("Something went wrong while trying to truncate the database", e);
    }
  }

}
