library geiger_localstorage;

import 'package:geiger_localstorage/geiger_localstorage.dart';

/// Interface representing a single node in the storage.
abstract class Node /*with Serializer*/ {

  /// Gets the name of the current node.
  ///
  /// Returns the name of the current node without the path prefix.
  String? getName();

  /// Gets the parent path of the node.
  ///
  /// Returns the parent path of the current node.
  String? getParentPath();

  /// Gets the full path with name of the current node.
  ///
  /// Returns the fully qualified name of the current node.
  String? getPath();

  /// Gets the owner of the current object.
  ///
  /// Returns string representation of the owner.
  String? getOwner();

  /// Sets the owner string.
  ///
  /// Sets tho owner string of the node to [newOwner].
  ///
  /// Returns the previously set owner owner string.
  String? setOwner(String newOwner);

  /// <p>Gets the current visibility according to the TLP protocol.</p>
  /// @return the current visibility
  Visibility getVisibility();

  /// <p>Sets the visibility of the node.</p>
  /// @param newVisibility the new visibility
  /// @return the visibility set previously
  Visibility setVisibility(Visibility newVisibility);

  /// Add a key/value pair to the node.
  ///
  /// Adds a K/V tuple to the node. The key must not exist prior adding.
  void addValue(NodeValue value);

  /// Add a key/value pair to the node.
  ///
  /// Adds a K/V tuple to the node. The key must not exist prior adding.
  void addOrUpdateValue(NodeValue value);

  /// <p>Get a specific value of the node.</p>
  ///
  /// @param key the key to be looked up
  /// @return the requested value or null if not found
  /// @throws StorageException if the storage backend encounters a problem
  NodeValue? getValue(String key);

  /// <p>Update a specific value of the node.</p>
  ///
  /// @param value the key to be updated
  /// @return the requested value or null if not found
  /// @throws StorageException if the storage backend encounters a problem
  NodeValue? updateValue(NodeValue value);

  /// <p>Removes a value from the node.</p>
  ///
  /// @param key the key of the value to be removed
  /// @return the removed node value or null if not found
  /// @throws StorageException if the storage backend encounters a problem
  NodeValue? removeValue(String key);

  /// <p>Get a deep copy of all values stored in the node.</p>
  ///
  /// @return a map of all values
  Map<String, NodeValue> getValues();

  /// <p>Adds a child node to this node.</p>
  ///
  /// @param node the child node to be added
  /// @throws StorageException if the storage backend encounters a problem
  void addChild(Node node);

  /// <p>Gets a child node from the current node.</p>
  ///
  /// @param name the name of the child node to fetch
  /// @return the requested child node or null if the node does not exist
  /// @throws StorageException if the storage backend encounters a problem
  Node? getChild(String name);

  /// <p>Removes a child node from this node.</p>
  ///
  /// @param name the name of the child node to be removed
  void removeChild(String name);

  /// <p>Get a map of all existing child nodes.</p>
  ///
  /// @return the map containing all child nodes
  /// @throws StorageException if the storage backend encounters a problem
  Map<String, Node> getChildren();

  /// <p>Gets the child nodes as CVS export.</p>
  ///
  /// @return A string representing the nodes as CVS
  /// @throws StorageException if the storage backend encounters a problem
  String getChildNodesCsv();

  /// <p>Returns true if the current node is not yet materialized.</p>
  ///
  /// @return true if the current node is a skeleton only
  bool isSkeleton();

  /// <p>Returns true if the node was there in the past but deleted.</p>
  ///
  /// @return true if the node was deleted
  bool isTombstone();

  /// <p>get the controller needed for materializing the node if required.</p>
  ///
  /// @return the controller
  StorageController? getController();

  /// <p>Sets the controller needed for materializing the node if required.</p>
  ///
  /// @param controller the controller to be set
  /// @return the previously set controller
  StorageController? setController(StorageController controller);

  /// <p>Update all data of the node with the data of the given node.</p>
  ///
  /// @param n2 the node whose values should be copied
  /// @throws StorageException if the storage backend encounters a problem
  void update(Node n2);

  /// <p>Create a deep clone of the current node.</p>
  ///
  /// @return the cloned node
  /// @throws StorageException if the storage backend encounters a problem
  Node deepClone();

  /// <p>Create a shallow clone of the current node.</p>
  ///
  /// <p>any children of the node are included skeletoized.</p>
  /// @return the cloned node
  /// @throws StorageException if the storage backend encounters a problem
  Node shallowClone();

  /// Checks if two NodeValue are equivalent in values.
  bool equals(Object? object);
}
