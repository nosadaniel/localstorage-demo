import 'change_registrar.dart';
import 'search_criteria.dart';
import 'db/data/node.dart';
import 'db/data/node_value.dart';

/// <p>Generic implementation of a convenient storage controller providing persistence to a
/// mapper backend.</p>
abstract class StorageController with ChangeRegistrar {
  /// <p>Fetches a node by its path.</p>
  /// @param path the path of the node to be fetched
  /// @return The requested node
  /// @throws StorageException if the storage backend encounters a problem
  Node get(String path);

  /// <p>Fetches a node by its path.</p>
  /// @param path the path of the node to be fetched
  /// @return The requested node
  /// @throws StorageException if the storage backend encounters a problem
  Node getNodeOrTombstone(String path);

  /// <p>Add StorageNode to data.</p>
  /// @param node is the node to add
  /// @throws StorageException if the storage backend encounters a problem
  void add(Node node);

  /// <p>Update a StorageNode inside the data.</p>
  /// @param node is the node to updated
  /// @throws StorageException if the storage backend encounters a problem
  void update(Node node);

  /// <p>Remove a StorageNode from the data.</p>
  /// @param path the name of the storage node to be removed
  /// @return the removed node or null if node doesn't exist
  /// @throws StorageException if the storage backend encounters a problem
  Node delete(String path);

  /// <p>add or update the node and all materialized sub-nodes.</p>
  /// <p>
  /// Any materialized node is added or updated. Tombstoned nodes may be used to deltete a node.
  /// </p>
  /// @param node the node to be written o updated
  /// @return true if at least one node was added
  /// @throws StorageException if the storage backend encounters a problem
  bool addOrUpdate(Node node);

  /// <p>Rename a node identified by a path.</p>
  /// <p>This call renames a node. The new name may be a name only or a fully qualified path.
  /// The later operation moves the node and all child objects.</p>
  /// @param oldPath the old path of the node
  /// @param newName the new name or new path of the node
  /// @throws StorageException if the storage backend encounters a problem
  void rename(String oldPath, String newName);

  /// <p>Get a single value from a node.</p>
  /// @param path the path of the node to add the value
  /// @param key  the key of the value to be retrieved
  /// @return a representation of the node value
  /// @throws StorageException if the node or the object does not exist or
  /// the storage backend encounters an error
  NodeValue? getValue(String path, String key);

  /// <p>Add NodeValueObject to StorageNode.</p>
  /// @param path  the path of the node to add the value
  /// @param value the NodeValueObject to add
  /// @throws StorageException if the storage backend encounters a problem
  void addValue(String path, NodeValue value);

  /// <p>Updates one NodeValueObject with a new NodeValueObject.</p>
  /// <p>It couples all fields except key. The key is used to search the NodeValueObject
  /// to update.</p>
  /// <p>TODO maybe whole object can be removed and the new one added? (might change object uuid)</p>
  /// @param nodeName the node to update
  /// @param value    the new NodeValueObject used for updating
  /// @throws StorageException if the storage backend encounters a problem
  void updateValue(String nodeName, NodeValue value);

  /// <p>Updates one NodeValueObject with a new NodeValueObject by copying all fields except key.</p>
  /// <p>The key is used to search the NodeValueObject to update.</p>
  /// <p>TODO maybe whole object can be removed and the new one added? (might change object uuid)</p>
  /// @param path the path to the node
  /// @param key  the key to be removed from the value
  /// @return the removed node value
  /// @throws StorageException if the storage backend encounters a problem
  NodeValue deleteValue(String path, String key);

  /// *<p> Search for nodes that meet the criteria.</p>
  /// @param criteria a list of SearchCriteria
  /// @return List of StorageNodes, list could be empty
  /// @throws StorageException if the storage backend encounters a problem
  List<Node> search(SearchCriteria criteria);

  /// <p>Closes all database connections and flushes the content.</p>
  /// @throws StorageException if the storage backend encounters a problem
  void close();

  /// <p>Flushes all values to the backend.</p>
  /// @throws StorageException if the storage backend encounters a problem
  void flush();

  /// <p>Clear the entire storage.</p>
  /// <p>Handle with care... there is no undo function.</p>
  /// @throws StorageException if the storage backend encounters a problem
  void zap();
}