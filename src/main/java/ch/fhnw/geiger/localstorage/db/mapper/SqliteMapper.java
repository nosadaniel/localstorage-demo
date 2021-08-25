package ch.fhnw.geiger.localstorage.db.mapper;

import ch.fhnw.geiger.localstorage.SearchCriteria;
import ch.fhnw.geiger.localstorage.StorageController;
import ch.fhnw.geiger.localstorage.StorageException;
import ch.fhnw.geiger.localstorage.Visibility;
import ch.fhnw.geiger.localstorage.db.GenericController;
import ch.fhnw.geiger.localstorage.db.data.*;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.*;


/**
 * This class maps the DBinterface functions to a SQLite database
 */
public class SqliteMapper extends AbstractMapper {

  private static final int MAXFIELDSIZE = 1024;

  private static final String initString = ""
      + "CREATE TABLE IF NOT EXISTS storage_node (\n"
      + "path TEXT CHECK( LENGTH(path) <=" + MAXFIELDSIZE + ") PRIMARY KEY,\n"
      + "owner TEXT CHECK( LENGTH(owner) <= 40),\n"
      + "name TEXT CHECK( LENGTH(name) <= 40) NOT NULL,\n"
      + "visibility TEXT CHECK(visibility IN ('RED', 'AMBER', 'GREEN', 'WHITE')) NOT NULL DEFAULT 'RED',\n"
      + "children TEXT CHECK( LENGTH(children) <=" + MAXFIELDSIZE + ") NULL,\n"
      + "tombstone TEXT CHECK( tombstone IN ('TRUE', 'FALSE')) DEFAULT 'FALSE'\n"
      + ");\n";
  private static final String initNodeValueString = ""
      + "\n"
      + "CREATE TABLE IF NOT EXISTS node_value (\n"
      + "path TEXT CHECK( LENGTH(path) <=" + MAXFIELDSIZE + ") NOT NULL,\n"
      + "key TEXT CHECK( LENGTH(key) <= 40) NOT NULL,\n"
      + "value TEXT CHECK( LENGTH(value) <= 16384),\n"
      + "type TEXT CHECK( LENGTH(type) <= 40),\n"
      + "locale TEXT CHECK( LENGTH(locale) <= 10) NOT NULL,\n"
      + "last_modified TEXT CHECK( LENGTH(last_modified) <= 20) NOT NULL,\n"
      + "PRIMARY KEY (path, key),\n"
      + "FOREIGN KEY (path) REFERENCES storage_node(path)\n"
      + ");\n"
      + "\n";
      private static final String initTranslationString = ""
      + "CREATE TABLE IF NOT EXISTS translation (\n"
      + "path TEXT CHECK( LENGTH(path) <=" + MAXFIELDSIZE + ") NOT NULL,\n"
      + "key TEXT CHECK( LENGTH(key) <= 40) NOT NULL,\n"
      + "identifier TEXT CHECK(identifier IN ('VALUE', 'DESCRIPTION')) NOT NULL,\n"
      + "locale TEXT CHECK( LENGTH(locale) <= 10) NOT NULL,\n"
      + "translation TEXT CHECK( LENGTH(translation) <=" + MAXFIELDSIZE + ") NOT NULL,\n"
      + "PRIMARY KEY (path, key, identifier, locale),\n"
      + "FOREIGN KEY (path, key) REFERENCES node_value(path, key)\n"
      + ");\n";

  private Connection conn;
  private StorageController controller = null;

  public SqliteMapper(String jdbcPath) throws StorageException {
    try {
      // connect only if database already exists
      conn = DriverManager.getConnection("jdbc:sqlite:" + jdbcPath);
      // check if database is already initialized
      conn.prepareStatement("SELECT * FROM node_value LIMIT 1;").executeQuery();

      //conn = new SQLiteConnection(jdbcPath, "geiger.db");
    } catch (SQLException throwables) {
      // database does not exists it should be created
      initialize();
    }
  }

  private void initialize() throws StorageException {
    try {
      conn.prepareStatement(initString).execute();
      conn.prepareStatement(initNodeValueString).execute();
      conn.prepareStatement(initTranslationString).execute();
    } catch (SQLException e) {
      try {
        // delete malfunctioning database
        // SQLite does not have a drop all feature -> delete manually
        String deleteString = "DROP TABLE IF EXISTS translation;" +
            "DROP TABLE IF EXISTS node_value;" +
            "DROP TABLE IF EXISTS storage_node;";
        conn.prepareStatement(deleteString).execute();
        //conn.prepareStatement("drop all objects delete files").execute();
      } catch (SQLException e2) {
        throw new StorageException("Whoops... error while tearing down database", e2);
      }
      throw new StorageException("Could not initialize database", e);
    }
  }


  @Override
  public void setController(StorageController controller) {
    this.controller = controller;
  }

  @Override
  public Node get(String path) throws StorageException {
    checkPath(path);
    getSanity(path);
    String sqlStatement = "SELECT path, owner, name, visibility, children, tombstone "
        + "FROM storage_node WHERE path = ?";
    Node res;
    try {
      ResultSet resultSet = requestResult(sqlStatement, new String[]{path});
      if (!resultSet.next()) {
        throw new StorageException("Node does not exist");
      } else {
        if ("true".equals(resultSet.getString("tombstone").toLowerCase())) {
          // add minimum information for tombstone (only Not NUll fields)
          res = new NodeImpl(resultSet.getString("path"), true);
          res.setVisibility(Visibility.valueOf(resultSet.getString("visibility")));
          return res;
        }
        // create non tombstone node
        res = new NodeImpl(resultSet.getString("path"));
        String owner = resultSet.getString("owner");
        if (owner != null) {
          res.setOwner(owner);
        }
        res.setVisibility(Visibility.valueOf(resultSet.getString("visibility")));
        String children = resultSet.getString("children");
        // get children as skeleton
        if (!"".equals(children)) {
          for (String childName : children.split(",")) {
            res.addChild(new NodeImpl(path + ":" + childName, controller));
          }
        }
      }
    } catch (StorageException | SQLException e) {
      e.printStackTrace();
      throw new StorageException("Could not retrieve node \"" + path + "\"");
    }

    // get all values and add to node
    sqlStatement = "SELECT path, key, value, type, locale, last_modified "
        + "FROM node_value WHERE path = ?";
    ResultSet resultSetValues = requestResult(sqlStatement, new String[]{path});
    String key;
    try {
      while (resultSetValues.next()) {
        key = resultSetValues.getString("key");
        NodeValue value = new NodeValueImpl(key, resultSetValues.getString("value"),
            resultSetValues.getString("type"), "",
            Long.parseLong(resultSetValues.getString("last_modified")));

        // get translations and add to node_value
        String sqlStatementTranslations = "SELECT path, key, identifier, locale, translation "
            + "FROM translation WHERE (path = ? AND key = ?)";
        ResultSet resultSetTranslations = requestResult(sqlStatementTranslations,
            new String[]{path, key});
        try {
          while (resultSetTranslations.next()) {
            String identifier = resultSetTranslations.getString("identifier");
            if ("VALUE".equals(identifier)) {
              // the translation is for a value
              value.setValue(resultSetTranslations.getString("translation"),
                  Locale.forLanguageTag(resultSetTranslations.getString("locale")));
            } else if ("DESCRIPTION".equals(identifier)) {
              // the translation is for a description
              value.setDescription(resultSetTranslations.getString("translation"),
                  Locale.forLanguageTag(resultSetTranslations.getString("locale")));
            }
          }
        } catch (SQLException e) {
          throw new StorageException("Could not retrieve description for node \"" + path
              + "\" and key \"" + key + "\"", e);
        }
        res.addValue(value);
      }
    } catch (SQLException e) {
      throw new StorageException("Could not retrieve values for node \"" + path + "\"", e);
    }
    return res;
  }

  @Override
  public void add(Node node) throws StorageException {
    // check skeleton
    if (node.isSkeleton()) {
      throw new StorageException("Skeleton nodes cannot be added.");
    }
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
      Node parent = get(node.getParentPath());
      parent.addChild(node);
      update(parent);
    }
    // add node
    String sqlStatement = "INSERT INTO "
        + "storage_node(path, owner, name, visibility, children, tombstone) "
        + "VALUES (?,?,?,?,?,?)";
    try {
      requestResult(sqlStatement, new String[]{node.getPath(), node.getOwner(), node.getName(),
          node.getVisibility().toString(), node.getChildNodesCsv(),
          String.valueOf(node.isTombstone()).toUpperCase()});
    } catch (StorageException e) {
      throw new StorageException("Could not add new node", e);
    }
    // check if values exists and add them
    for (NodeValue nv : node.getValues().values()) {
      addValue(node.getPath(), nv);
    }
  }

  @Override
  public void update(Node node) throws StorageException {
    // check skeleton
    if (node.isSkeleton()) {
      throw new StorageException("Skeleton nodes cannot be added, "
          + "please materialize before adding");
    }
    checkPath(node);
    get(node.getPath()); // checks if node exists, throws storage exception if not exists

    String sqlStatement = "UPDATE storage_node SET owner = ?, visibility = ?, children = ?, "
        + "tombstone = ? WHERE path = ?";
    try {
      requestResult(sqlStatement, new String[]{node.getOwner(), node.getVisibility().toString(),
          node.getChildNodesCsv(), String.valueOf(node.isTombstone()).toUpperCase(),
          node.getPath()});

      // Values are being created if they dont exist else updated
      for (Map.Entry<String, NodeValue> entry : node.getValues().entrySet()) {
        if (getValue(node.getPath(), entry.getKey()) == null) {
          addValue(node.getPath(), entry.getValue());
        } else {
          updateValue(node.getPath(), entry.getValue());
        }
      }
    } catch (StorageException e) {
      throw new StorageException("Could not update node", e);
    }
  }

  @Override
  public Node delete(String path) throws StorageException {
    Node oldNode = get(path);
    if (!"".equals(oldNode.getChildNodesCsv())) {
      throw new StorageException("Node does have children... cannot remove " + path);
    }

    // remove values
    for (NodeValue nv : oldNode.getValues().values()) {
      deleteValue(path, nv.getKey());
    }

    // remove the node by deleting all properties and create tombstone
    Node deletedNode = new NodeImpl(path, true);
    deletedNode.setVisibility(oldNode.getVisibility());
    update(deletedNode);

    // remove reference from parent
    if (!"".equals(oldNode.getParentPath())) {
      Node parentNode = get(oldNode.getParentPath());
      parentNode.removeChild(oldNode.getName());
      update(parentNode);
    }

    // return node
    return oldNode;
  }

  @Override
  public NodeValue getValue(String path, String key) throws StorageException {
    if ("".equals(path) || "".equals(key)) {
      throw new NullPointerException();
    }
    checkPath(path);
    // check if node exists and is not a tombstone
    Node ret = get(path);
    if (ret.isTombstone()) {
      throw new StorageException("Node does not exists: " + path);
    }

    String sqlSelectStatement = "SELECT path,key,value,type,locale,last_modified "
        + "FROM node_value WHERE (path = ? and key = ?)";
    NodeValue value = null;
    try {
      ResultSet resultSet = requestResult(sqlSelectStatement, new String[]{path, key});

      if (!resultSet.next()) {
        return value; // returning a null value to use this method as an pseudo "contains"
      }

      // add properties
      value = new NodeValueImpl(resultSet.getString("key"), resultSet.getString("value"),
          resultSet.getString("type"), "",
          resultSet.getLong("last_modified"));

    } catch (StorageException | SQLException e) {
      throw new StorageException(
          "Something went wrong while trying to retrieve the value " + key + " from " + path, e);
    }

    // add translations
    String sqlStatementTranslations = "SELECT path,key,identifier,locale,translation "
        + "FROM translation WHERE (path = ? AND key = ?)";
    try {
      ResultSet rsTranslations = requestResult(sqlStatementTranslations, new String[]{path, key});

      while (rsTranslations.next()) {
        String identifier = rsTranslations.getString("identifier");
        if ("VALUE".equals(identifier)) {
          // the translation is for a value
          value.setValue(rsTranslations.getString("translation"),
              Locale.forLanguageTag(rsTranslations.getString("locale")));
        } else if ("DESCRIPTION".equals(identifier)) {
          // the translation is for a description
          value.setDescription(rsTranslations.getString("translation"),
              Locale.forLanguageTag(rsTranslations.getString("locale")));
        }
      }
    } catch (SQLException e) {
      throw new StorageException("Could not retrieve description for node \"" + path
          + "\" and key \"" + key + "\"", e);
    }
    return value;
  }

  private void addValue(String path, NodeValue value) throws StorageException {
    checkPath(path);
    if (value == null) {
      throw new NullPointerException();
    }
    get(path); // check if node exists

    if (getValue(path, value.getKey()) != null) {
      throw new StorageException("Value already exists");
    }
    String sqlStatement = "INSERT INTO node_value (path, key, value, type, locale, "
        + "last_modified) VALUES (?,?,?,?,?,?)";
    try {
      requestResult(sqlStatement, new String[]{path, value.getKey(), value.getValue(),
          value.getType(), Locale.ENGLISH.toLanguageTag(),
          String.valueOf(value.getLastModified())});
    } catch (StorageException e) {
      throw new StorageException("Could not create value \"" + value.getKey() + "\"", e);
    }

    // insert translations for value
    String sqlStatementTrl = "INSERT INTO translation (path, key, identifier, locale, translation)"
        + " VALUES (?,?,?,?,?)";
    Map<Locale, String> valueMap = value.getAllValueTranslations();
    for (Map.Entry<Locale, String> entry : valueMap.entrySet()) {
      try {
        requestResult(sqlStatementTrl, new String[]{path, value.getKey(), "VALUE",
            entry.getKey().toLanguageTag(), entry.getValue()});
      } catch (StorageException e) {
        throw new StorageException("Could not create translation \""
            + entry.getKey().toLanguageTag() + "\" for value \"" + value.getKey() + "\"", e);
      }
    }

    // insert translations for description
    Map<Locale, String> descriptionMap = value.getAllDescriptionTranslations();
    for (Map.Entry<Locale, String> entry : descriptionMap.entrySet()) {
      try {
        requestResult(sqlStatementTrl, new String[]{path, value.getKey(), "DESCRIPTION",
            entry.getKey().toLanguageTag(), entry.getValue()});
      } catch (StorageException e) {
        throw new StorageException("Could not create translation \""
            + entry.getKey().toLanguageTag() + "\" for description in value \""
            + value.getKey() + "\"", e);
      }
    }
  }

  private void updateValue(String path, NodeValue value) throws StorageException {
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
    deleteValue(path, value.getKey());
    addValue(path, value);
  }

  private NodeValue deleteValue(String path, String key) throws StorageException {
    if (key == null || "".equals(path)) {
      throw new NullPointerException();
    }
    get(path); // check if node exists

    // get value
    NodeValue value = getValue(path, key);
    if (value == null) {
      throw new StorageException("Key \"" + key + "\" does not exist");
    }
    // remove translations
    String sqlDeleteStatementTranslations = "DELETE FROM translation WHERE (path = ? AND key = ?)";
    try {
      requestResult(sqlDeleteStatementTranslations, new String[]{path, key});
    } catch (StorageException e) {
      throw new StorageException("Could not delete translations for key \"" + key + "\" in node \""
          + path + "\"", e);
    }

    // remove value
    String sqlDeleteStatement = "DELETE FROM node_value WHERE (path = ? AND key = ?)";
    try {
      requestResult(sqlDeleteStatement, new String[]{path, key});
    } catch (StorageException e) {
      throw new StorageException("Could not delete value for key \"" + key + "\" in node \""
          + path + "\"", e);
    }

    return value;
  }

  @Override
  public void rename(String oldPath, String newPathOrName) throws StorageException {
    checkPath(oldPath);
    checkPath(newPathOrName);
    Node oldNode = get(oldPath);

    // handle tombstones
    NodeImpl newNode;
    if (oldNode.isTombstone()) {
      newNode = new NodeImpl(newPathOrName, true);
    } else {
      newNode = new NodeImpl(newPathOrName, oldNode.getOwner(), oldNode.getVisibility());
    }

    // copy values
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
    delete(oldPath);
  }

  @Override
  public List<Node> search(SearchCriteria criteria) throws StorageException {
    String sqlNodeSearch = "SELECT path, owner, name, visibility, children FROM storage_node "
        + "WHERE (path = ? and owner = ? and name = ? and visibility = ?)";
    String sqlValueSearch = "SELECT path,key,value,type,locale,last_modified "
        + "FROM node_value WHERE (path = ? and key = ? and value = ? and type = ? "
        + "and last_modified = ?)";
    Map<String, Node> nodes = new HashMap<>();
    Map<String, NodeValue> values = new HashMap<>();
    try {
      // get nodes
      // TODO check if this actually works for Visibility
      ResultSet resultSetNodes = requestResult(sqlNodeSearch, new String[]{
          "".equals(criteria.getNodePath()) ? "*" : criteria.getNodePath(),
          "".equals(criteria.getNodeOwner()) ? "*" : criteria.getNodeOwner(),
          "".equals(criteria.getNodeName()) ? "*" : criteria.getNodeName(),
          "".equals(criteria.get(Field.VISIBILITY)) ? "*" : criteria.get(Field.VISIBILITY)
      });

      // add all Nodes that matched the criteria
      while (resultSetNodes.next()) {
        String path = resultSetNodes.getString("path");
        nodes.put(path, get(path));
      }

      // get values
      ResultSet resultSetValues = requestResult(sqlValueSearch, new String[]{
          "".equals(criteria.getNodePath()) ? "*" : criteria.getNodePath(),
          "".equals(criteria.getNodeValueKey()) ? "*" : criteria.getNodeValueKey(),
          "".equals(criteria.getNodeValueValue()) ? "*" : criteria.getNodeValueValue(),
          "".equals(criteria.getNodeValueType()) ? "*" : criteria.getNodeValueType(),
          "".equals(criteria.getNodeValueLastModified()) ? "*" : criteria.getNodeValueLastModified()
      });

      // add values that matched the criteria
      while (resultSetValues.next()) {
        String path = resultSetValues.getString("path");
        values.put(path, getValue(path, resultSetValues.getString("key")));
      }
    } catch (SQLException e) {
      e.printStackTrace();
      throw new StorageException("Something went wrong while trying to execute the search");
    }

    // Currently all missing Nodes (if any) for values get added to the list in
    // order to include the values.
    for (String path : values.keySet()) {
      if (!nodes.containsKey(path)) {
        // get missing node
        nodes.put(path, get(path));
      }
      // add value to existing node
      nodes.get(path).addValue(values.get(path));
    }
    return new ArrayList<>(nodes.values());
  }

  @Override
  public void close() {
    try {
      // TODO any alternatives to this?
      //conn.prepareStatement("SHUTDOWN;").executeUpdate();
      conn.close();
    } catch (SQLException e) {
      throw new RuntimeException("OOPS... unexpected exception", e);
    }
  }

  @Override
  public void flush() {
    // this operation seems not to be used within sqlite
    /*
    try {
      conn.commit();
    } catch (SQLException e) {
      throw new RuntimeException("Could not flush database", e);
    }
     */
  }

  @Override
  public void zap() throws StorageException {
    // Usually Truncate would be used, but it does not work with referenced tables
    String sqlStatement1 = "DELETE FROM storage_node";
    String sqlStatement2 = "DELETE FROM node_value";
    String sqlStatement3 = "DELETE FROM translation";
    try {
      (conn.createStatement()).execute(sqlStatement3);
      (conn.createStatement()).execute(sqlStatement2);
      (conn.createStatement()).execute(sqlStatement1);
    } catch (SQLException e) {
      throw new StorageException("Something went wrong while trying to truncate the database", e);
    }
  }

  /**
   * Executes the given sqlStatement as a prepared statement using the optional args in given order.
   *
   * @param sqlStatement the statement to execute
   * @param args the arguments to replace
   * @return the Resultset containing all the results
   */
  private ResultSet requestResult(String sqlStatement, String[] args) throws StorageException {
    ResultSet resultSet;
    try {
      PreparedStatement ps = conn.prepareStatement(sqlStatement);
      for (int i = 0; i < args.length; ++i) {
        ps.setString(i + 1, args[i]);
      }
      if (ps.execute()) {
        // it has a resultSet
        resultSet = ps.getResultSet();
      } else {
        resultSet = null;
      }
    } catch (SQLException throwables) {
      throwables.printStackTrace();
      throw new StorageException("Could not execute query: " + sqlStatement + " with args: "
          + Arrays.toString(args));
    }
    return resultSet;
  }
}
