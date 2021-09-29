library geiger_localstorage;

import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:intl/locale.dart';
import 'package:sqlite3/sqlite3.dart';

/// This class maps the DBinterface functions to a SQLite database
class SqliteMapper extends AbstractSqlMapper {
  static const int maxFieldSize = 1024;
  static final String initString = 'CREATE TABLE IF NOT EXISTS storage_node (\n'
          'path TEXT CHECK( LENGTH(path) <=' +
      maxFieldSize.toString() +
      ') PRIMARY KEY,\n'
          'owner TEXT CHECK( LENGTH(owner) <= 40),\n'
          'name TEXT CHECK( LENGTH(name) <= 40) NOT NULL,\n'
          "visibility TEXT CHECK(visibility IN ('RED', 'AMBER', 'GREEN', 'WHITE')) NOT NULL DEFAULT 'RED',\n"
          'children TEXT CHECK( LENGTH(children) <=' +
      maxFieldSize.toString() +
      ') NULL,\n'
          "tombstone TEXT CHECK( tombstone IN ('TRUE', 'FALSE')) DEFAULT 'FALSE'\n"
          ');\n';
  static final String initNodeValueString =
      'CREATE TABLE IF NOT EXISTS node_value (\n'
              'path TEXT CHECK( LENGTH(path) <=' +
          maxFieldSize.toString() +
          ') NOT NULL,\n'
              'key TEXT CHECK( LENGTH(key) <= 40) NOT NULL,\n'
              'value TEXT CHECK( LENGTH(value) <= 16384),\n'
              'type TEXT CHECK( LENGTH(type) <= 40),\n'
              'locale TEXT CHECK( LENGTH(locale) <= 10) NOT NULL,\n'
              'last_modified TEXT CHECK( LENGTH(last_modified) <= 20) NOT NULL,\n'
              'PRIMARY KEY (path, key),\n'
              'FOREIGN KEY (path) REFERENCES storage_node(path)\n'
              ');\n';
  static final String initTranslationString =
      'CREATE TABLE IF NOT EXISTS translation (\n'
              'path TEXT CHECK( LENGTH(path) <=' +
          maxFieldSize.toString() +
          ') NOT NULL,\n'
              'key TEXT CHECK( LENGTH(key) <= 40) NOT NULL,\n'
              "identifier TEXT CHECK(identifier IN ('VALUE', 'DESCRIPTION')) NOT NULL,\n"
              'locale TEXT CHECK( LENGTH(locale) <= 10) NOT NULL,\n'
              'translation TEXT CHECK( LENGTH(translation) <=' +
          maxFieldSize.toString() +
          ') NOT NULL,\n'
              'PRIMARY KEY (path, key, identifier, locale),\n'
              'FOREIGN KEY (path, key) REFERENCES node_value(path, key)\n'
              ');\n';

  late Database conn;
  StorageController? controller;

  SqliteMapper(String jdbcPath) {
    try {
      conn = sqlite3.open(jdbcPath);
      conn.execute('SELECT * FROM node_value LIMIT 1;');
    } on SqliteException {
      try {
        initialize();
      } on StorageException {
        rethrow;
      }
    }
  }

  void initialize() {
    try {
      conn.execute(initString);
      conn.execute(initNodeValueString);
      conn.execute(initTranslationString);
    } on SqliteException catch (e) {
      try {
        var deleteString = 'DROP TABLE IF EXISTS translation;'
            'DROP TABLE IF EXISTS node_value;'
            'DROP TABLE IF EXISTS storage_node;';
        conn.execute(deleteString);
      } on SqliteException catch (e2) {
        throw StorageException(
            'Whoops... error while tearing down database', e2);
      }
      throw StorageException('Could not initialize database', e);
    }
  }

  @override
  void setController(StorageController controller) {
    this.controller = controller;
  }

  @override
  Node get(String path) {
    checkPath(path);
    getSanity(path);
    var sqlStatement =
        'SELECT path, owner, name, visibility, children, tombstone '
        'FROM storage_node WHERE path = ?';
    Node res;
    try {
      ResultSet resultSet = requestResult(sqlStatement, [path]);
      if (resultSet.isEmpty) {
        throw StorageException('Node "$path" does not exist on sqlite backed');
      } else {
        if ('true' == resultSet.first['tombstone'].toLowerCase()) {
          res = NodeImpl.fromPath(resultSet.first['path'] as String,
              isTombstone: true);
          res.setVisibility(VisibilityExtension.valueOf(
                  resultSet.first['visibility']! as String) ??
              Visibility.red);
          return res;
        }
        res = NodeImpl.fromPath(resultSet.first['path'] as String);
        String? owner = resultSet.first['owner'] as String;
        res.setOwner(owner);
        res.setVisibility(VisibilityExtension.valueOf(
                resultSet.first['visibility'] as String) ??
            Visibility.red);
        String children = resultSet.first['children'] as String;
        if (!('' == children)) {
          for (var childName in children.split(',')) {
            res.addChild(
                NodeImpl.createSkeleton(path + ':' + childName, controller));
          }
        }
      }
    } catch (e) {
      if (!(e is StorageException || e is SqliteException)) rethrow;
      print(e);
      throw StorageException('Could not retrieve node "' + path + '"');
    }
    sqlStatement = ('SELECT path, key, value, type, locale, last_modified '
        'FROM node_value WHERE path = ?');
    var resultSetValues = requestResult(sqlStatement, [path]);
    String key;
    try {
      for (var valueRow in resultSetValues) {
        key = valueRow['key'] as String;
        NodeValue value = NodeValueImpl(
            key,
            valueRow['value'] as String,
            valueRow['type'] as String,
            '',
            int.parse(valueRow['last_modified'] as String));
        var sqlStatementTranslations =
            'SELECT path, key, identifier, locale, translation '
            'FROM translation WHERE (path = ? AND key = ?)';
        var resultSetTranslations =
            requestResult(sqlStatementTranslations, [path, key]);
        try {
          for (var translationRow in resultSetTranslations) {
            String identifier = translationRow['identifier'] as String;
            if ('VALUE' == identifier) {
              value.setValue(translationRow['translation'] as String,
                  Locale.parse(translationRow['locale'] as String));
            } else {
              if ('DESCRIPTION' == identifier) {
                value.setDescription(translationRow['translation'] as String,
                    Locale.parse(translationRow['locale'] as String));
              }
            }
          }
        } on SqliteException catch (e) {
          throw StorageException(
              'Could not retrieve description for node "' +
                  path +
                  '" and key "' +
                  key +
                  '"',
              e);
        }
        res.addValue(value);
      }
    } on SqliteException catch (e) {
      throw StorageException(
          'Could not retrieve values for node "' + path + '"', e);
    }
    return res;
  }

  @override
  void add(Node node) {
    if (node.isSkeleton()) {
      throw StorageException('Skeleton nodes cannot be added.');
    }
    checkPath(node.getPath()!);
    try {
      get(node.getPath()!);
    } catch (e) {
      if ((e is! StorageException)) {
        throw StorageException('Node already exists');
      }
    }
    if (node.getParentPath() != null && '' != node.getParentPath()) {
      var parent = get(node.getParentPath()!);
      parent.addChild(node);
      update(parent);
    }
    var sqlStatement = 'INSERT INTO '
        'storage_node(path, owner, name, visibility, children, tombstone) '
        'VALUES (?,?,?,?,?,?)';
    try {
      requestResult(sqlStatement, [
        node.getPath(),
        node.getOwner(),
        node.getName(),
        node.getVisibility().toValueString(),
        node.getChildNodesCsv(),
        node.isTombstone().toString().toUpperCase()
      ]);
    } on StorageException catch (e) {
      print(e.toString());
      throw StorageException('Could not add new node "${node.getPath()}"', e);
    }
    for (var nv in node.getValues().values) {
      addValue(node.getPath()!, nv);
    }
  }

  @override
  void update(Node node) {
    if (node.isSkeleton()) {
      throw StorageException('Skeleton nodes cannot be added, '
          'please materialize before adding');
    }
    checkPath(node.getPath()!);
    get(node.getPath()!);
    var sqlStatement =
        ('UPDATE storage_node SET owner = ?, visibility = ?, children = ?, '
            'tombstone = ? WHERE path = ?');
    try {
      requestResult(sqlStatement, [
        node.getOwner(),
        node.getVisibility().toValueString(),
        node.getChildNodesCsv(),
        node.isTombstone().toString().toUpperCase(),
        node.getPath()
      ]);
      for (var entry in node.getValues().entries) {
        if (getValue(node.getPath()!, entry.key) == null) {
          addValue(node.getPath()!, entry.value);
        } else {
          updateValue(node.getPath()!, entry.value);
        }
      }
    } on StorageException catch (e) {
      throw StorageException('Could not update node', e);
    }
  }

  @override
  Node delete(String path) {
    var oldNode = get(path);
    if (oldNode.getChildren().isNotEmpty) {
      throw StorageException(
          'Node does have ${oldNode.getChildren().length} children... cannot remove ' +
              path);
    }
    for (var nv in oldNode.getValues().values) {
      deleteValue(path, nv.getKey());
    }
    Node deletedNode = NodeImpl.fromPath(path, isTombstone: true);
    deletedNode.setVisibility(oldNode.getVisibility());
    update(deletedNode);
    if (!('' == oldNode.getParentPath())) {
      var parentNode = get(oldNode.getParentPath()!);
      parentNode.removeChild(oldNode.getName()!);
      update(parentNode);
    }
    return oldNode;
  }

  @override
  NodeValue? getValue(String path, String key) {
    if (('' == path) || ('' == key)) {
      throw NullThrownError();
    }
    checkPath(path);
    var ret = get(path);
    if (ret.isTombstone()) {
      throw StorageException('unable to get value... Node "$path" does not exists. Node is a tombstone.');
    }
    var sqlSelectStatement = ('SELECT path,key,value,type,locale,last_modified '
        'FROM node_value WHERE (path = ? and key = ?)');
    NodeValue? value;
    try {
      var resultSet = requestResult(sqlSelectStatement, [path, key]);
      if (resultSet.isEmpty) {
        return value;
      }
      value = NodeValueImpl(
          resultSet.first['key'] as String,
          resultSet.first['value'] as String,
          resultSet.first['type'] as String,
          '',
          int.parse(resultSet.first['last_modified'] as String));
    } catch (e) {
      if (!(e is StorageException && e is SqliteException)) rethrow;
      throw StorageException(
          'Something went wrong while trying to retrieve the value ' +
              key +
              ' from ' +
              path,
          e);
    }
    var sqlStatementTranslations =
        ('SELECT path,key,identifier,locale,translation '
            'FROM translation WHERE (path = ? AND key = ?)');
    try {
      var rsTranslations = requestResult(sqlStatementTranslations, [path, key]);
      for (var rsTranslation in rsTranslations) {
        String identifier = rsTranslation['identifier'] as String;
        if ('VALUE' == identifier) {
          value.setValue(rsTranslation['translation'] as String,
              Locale.parse(rsTranslation['locale'] as String));
        } else {
          if ('DESCRIPTION' == identifier) {
            value.setDescription(rsTranslation['translation'] as String,
                Locale.parse(rsTranslation['locale'] as String));
          }
        }
      }
    } on SqliteException catch (e) {
      throw StorageException(
          'Could not retrieve description for node "' +
              path +
              '" and key "' +
              key +
              '"',
          e);
    }
    return value;
  }

  void addValue(String path, NodeValue value) {
    checkPath(path);
    get(path);
    if (getValue(path, value.getKey()) != null) {
      throw StorageException('Value "${value.getKey()}" already exists');
    }
    var sqlStatement =
        ('INSERT INTO node_value (path, key, value, type, locale, '
            'last_modified) VALUES (?,?,?,?,?,?)');
    try {
      requestResult(sqlStatement, [
        path,
        value.getKey(),
        value.getValue(),
        value.getType(),
        Locale.fromSubtags(languageCode: 'en').toLanguageTag(),
        value.getLastModified().toString()
      ]);
    } on StorageException catch (e) {
      throw StorageException(
          'Could not create value "${value.getKey()}"', e);
    }
    var sqlStatementTrl =
        ('INSERT INTO translation (path, key, identifier, locale, translation)'
            ' VALUES (?,?,?,?,?)');
    var valueMap = value.getAllValueTranslations();
    for (var entry in valueMap.entries) {
      try {
        requestResult(sqlStatementTrl, [
          path,
          value.getKey(),
          'VALUE',
          entry.key.toLanguageTag(),
          entry.value
        ]);
      } on StorageException catch (e) {
        throw StorageException(
            'Could not create translation "' +
                entry.key.toLanguageTag() +
                '" for value "' +
                value.getKey() +
                '"',
            e);
      }
    }
    var descriptionMap = value.getAllDescriptionTranslations();
    for (var entry in descriptionMap.entries) {
      try {
        requestResult(sqlStatementTrl, [
          path,
          value.getKey(),
          'DESCRIPTION',
          entry.key.toLanguageTag(),
          entry.value
        ]);
      } on StorageException catch (e) {
        throw StorageException(
            'Could not create translation "' +
                entry.key.toLanguageTag() +
                '" for description in value "' +
                value.getKey() +
                '"',
            e);
      }
    }
  }

  void updateValue(String path, NodeValue value) {
    checkPath(path);
    if ('' == path) {
      throw NullThrownError();
    }
    if (getValue(path, value.getKey()) == null) {
      throw StorageException(('Key "' + value.getKey()) + '" does not exist');
    }
    deleteValue(path, value.getKey());
    addValue(path, value);
  }

  NodeValue deleteValue(String path, String key) {
    if ('' == path) {
      throw NullThrownError();
    }
    get(path);
    var value = getValue(path, key);
    if (value == null) {
      throw StorageException(('Key "' + key) + '" does not exist');
    }
    var sqlDeleteStatementTranslations =
        'DELETE FROM translation WHERE (path = ? AND key = ?)';
    try {
      requestResult(sqlDeleteStatementTranslations, [path, key]);
    } on StorageException catch (e) {
      throw StorageException(
          'Could not delete translations for key "' +
              key +
              '" in node "' +
              path +
              '"',
          e);
    }
    var sqlDeleteStatement =
        'DELETE FROM node_value WHERE (path = ? AND key = ?)';
    try {
      requestResult(sqlDeleteStatement, [path, key]);
    } on StorageException catch (e) {
      throw StorageException(
          'Could not delete value for key "' + key + '" in node "' + path + '"',
          e);
    }
    return value;
  }

  @override
  void rename(String oldPath, String newPathOrName) {
    checkPath(oldPath);
    checkPath(newPathOrName);
    var oldNode = get(oldPath);
    NodeImpl newNode;
    if (oldNode.isTombstone()) {
      newNode = NodeImpl.fromPath(newPathOrName, isTombstone: true);
    } else {
      newNode =
          NodeImpl(newPathOrName, oldNode.getOwner(), oldNode.getVisibility());
    }
    for (var nv in oldNode.getValues().values) {
      newNode.addValue(nv);
    }
    add(newNode);
    for (var n in oldNode.getChildren().values) {
      rename(n.getPath()!,
          newNode.getPath()! + GenericController.pathDelimiter + n.getName()!);
    }
    delete(oldPath);
  }

  @override
  List<Node> search(SearchCriteria criteria) {
    var sqlNodeSearch =
        'SELECT path, owner, name, visibility, children FROM storage_node '
        'WHERE (path = ? and owner = ? and name = ? and visibility = ?)';
    var sqlValueSearch = 'SELECT path,key,value,type,locale,last_modified '
        'FROM node_value WHERE (path = ? and key = ? and value = ? and type = ? '
        'and last_modified = ?)';
    Map<String, Node> nodes = {};
    Map<String, NodeValue> values = {};
    try {
      var resultSetNodes = requestResult(sqlNodeSearch, [
        ('' == criteria.getNodePath()) ? '*' : criteria.getNodePath(),
        ('' == criteria.getNodeOwner()) ? '*' : criteria.getNodeOwner(),
        ('' == criteria.getNodeName()) ? '*' : criteria.getNodeName(),
        ('' == criteria.get(Field.visibility))
            ? '*'
            : criteria.get(Field.visibility)
      ]);
      for (var node in resultSetNodes) {
        String path = node['path'] as String;
        nodes[path] = get(path);
      }
      var resultSetValues = requestResult(sqlValueSearch, [
        ('' == criteria.getNodePath()) ? '*' : criteria.getNodePath(),
        ('' == criteria.getNodeValueKey()) ? '*' : criteria.getNodeValueKey(),
        ('' == criteria.getNodeValueValue())
            ? '*'
            : criteria.getNodeValueValue(),
        ('' == criteria.getNodeValueType()) ? '*' : criteria.getNodeValueType(),
        ('' == criteria.getNodeValueLastModified())
            ? '*'
            : criteria.getNodeValueLastModified()
      ]);
      for (var value in resultSetValues) {
        String path = value['path'] as String;
        values[path] = getValue(path, value['key'] as String)!;
      }
    } on SqliteException catch (_, st) {
      print(st);
      throw StorageException(
          'Something went wrong while trying to execute the search');
    }
    for (var path in values.keys) {
      if (!nodes.containsKey(path)) {
        nodes[path] = get(path);
      }
      nodes[path]!.addValue(values[path]!);
    }
    return nodes.values.toList();
  }

  @override
  void close() {
    try {
      conn.dispose();
    } on SqliteException catch (e) {
      throw Exception('OOPS... unexpected exception' + e.toString());
    }
  }

  @override
  void flush() {
    /// try {
    /// conn.commit();
    /// } catch (SQLException e) {
    /// throw new RuntimeException("Could not flush database", e);
    /// }
  }

  @override
  void zap() {
    var sqlStatement1 = 'DELETE FROM storage_node';
    var sqlStatement2 = 'DELETE FROM node_value';
    var sqlStatement3 = 'DELETE FROM translation';
    try {
      conn.execute(sqlStatement3);
      conn.execute(sqlStatement2);
      conn.execute(sqlStatement1);
    } on SqliteException catch (e) {
      throw StorageException(
          'Something went wrong while trying to truncate the database', e);
    }
  }

  /// Executes the given sqlStatement as a prepared statement using the optional args in given order.
  ///
  /// @param sqlStatement the statement to execute
  /// @param args the arguments to replace
  /// @return the Resultset containing all the results
  ResultSet requestResult(String sqlStatement, List<Object?> args) {
    try {
      return conn.select(sqlStatement, args);
    } on SqliteException catch (_, st) {
      print(st);
      throw StorageException('Could not execute query: ' +
          sqlStatement +
          ' with args: ' +
          args.toString());
    }
  }
}
