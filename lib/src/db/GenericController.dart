import 'dart:collection';

import 'package:localstorage/src/SearchCriteria.dart';
import 'package:localstorage/src/StorageListener.dart';
import 'package:uuid/uuid.dart';

import '../ChangeRegistrar.dart';
import '../EventType.dart';
import '../SearchCriteria.dart';
import '../StorageController.dart';
import '../StorageException.dart';
import 'StorageMapper.dart';
import 'data/Node.dart';
import 'data/NodeImpl.dart';
import 'data/NodeValue.dart';
import 'data/NodeValueImpl.dart';

/// <p>This Class Acts as an intermediate class to relay storageRequests to the
/// StorageMapper.</p>
///
/// <p>This class contains the interaction API every actor (sensor, shields, UI,...)
/// calls methods from this controller to manipulate data.</p>
///
/// @author Sacha
/// @version 0.1
class GenericController implements StorageController, ChangeRegistrar {
  static StorageController? defaultController;

  /// the path delimiter.
  static final String PATH_DELIMITER = ':';

  /// the default owner of all newly created nodes.
  final String owner;

  /// a map of all registered listeners for changes.
  final Map<SearchCriteria, StorageListener> listeners = HashMap();

  /// the storage mapper to be used.
  final StorageMapper mapper;

  /// <p>Construct the controller according to the database that is used.</p>
  ///
  /// @param owner  the owner to be used for all requests
  /// @param mapper the database mapper to use
  ///
  /// @throws StorageException In case of problems regarding the storage
  GenericController(this.owner, this.mapper) {
    mapper.setController(this);
    initMapper();
    defaultController = this;
  }

  /// <p>Returns the latest created controller within the JVM.</p>
  ///
  /// @return a valid storage controller
  static StorageController? getDefault() {
    return defaultController;
  }

  void initMapper() {
    final baseNodes = <String>[
      '',
      ':Devices',
      ':Users',
      ':Enterprise',
      ':Keys',
      ':Global',
      ':Local'
    ];
    for (var nodeName in baseNodes) {
      try {
// for correct path generation creation of a Node is needed
        Node tmp = NodeImpl.fromPath(nodeName);
        mapper.get(tmp.getPath());
      } on StorageException {
// node does not exist and therefore we create it
        Node tmp = NodeImpl.fromPath(nodeName);
        tmp.setOwner(owner);
        mapper.add(tmp);
      }
    }

// check if current user exists
    var localNode = mapper.get(':Local');
    var uuid = localNode.getValue('currentUser');
    if (uuid == null) {
      uuid = NodeValueImpl('currentUser', Uuid().v4());
      localNode.addValue(uuid);
      localNode.setOwner(owner);
      mapper.update(localNode);
    }
    if (uuid == null) {
// create new default user
      uuid = NodeValueImpl('currentUser', Uuid().v4());
      localNode.addValue(uuid);
      localNode.setOwner(owner);
      mapper.update(localNode);
    }

// check if current user node exists
    var userNodeName = ':Users:' + uuid.getValue()!;
    try {
      mapper.get(userNodeName);
    } on StorageException {
      Node n = NodeImpl.fromPath(userNodeName);
      n.setOwner(owner);
      mapper.add(n);
    }

// check if current device exists
    localNode = mapper.get(':Local');
    uuid = localNode.getValue('currentDevice');
    if (uuid == null) {
// create new default device
      uuid = NodeValueImpl('currentDevice', Uuid().v4());
      localNode.addValue(uuid);
      localNode.setOwner(owner);
      mapper.update(localNode);
    }

// check if current device node exists
    var deviceNodeName = ':Devices:' + uuid.getValue()!;
    try {
      mapper.get(deviceNodeName);
    } on StorageException {
      mapper.add(NodeImpl.fromPath(deviceNodeName));
    }
  }

  @override
  bool addOrUpdate(Node? node) {
    if (node == null) {
      return false;
    } else if (node.isSkeleton()) {
      return false;
    } else if (node.isTombstone()) {
      delete(node.getPath());
      return false;
    } else {
      var ret = false;
      try {
        add(node);
        ret = true;
      } on StorageException {
        update(node);
      }
      if (node.getChildren() != null) {
        for (var n2 in node.getChildren().values) {
          ret |= addOrUpdate(n2);
        }
      }
      return ret;
    }
  }

  @override
  Node get(String path) {
    var n = getNodeOrTombstone(path);
    if (n == null || n.isTombstone()) {
      throw StorageException('Node does not exist');
    }
    var l = List<String>.empty(growable: true);
    for (var cn in n.getChildren().values) {
      if (cn.isTombstone()) {
        l.add(cn.getName());
      }
    }
    for (var name in l) {
      n.removeChild(name);
    }
    return n;
  }

  @override
  Node getNodeOrTombstone(String path) {
    return mapper.get(path);
  }

  @override
  void add(Node node) {
// make sure that there is an owner set
    if (node.getOwner() == null || '' == node.getOwner()) {
      node.setOwner(owner);
    }

// add object
    mapper.add(node);

// add child nodes
    for (var n in node.getChildren().values) {
      mapper.add(n);
    }

    checkListeners(EventType.CREATE, null, node, null, null);
  }

  @override
  void update(Node node) {
// make sure that there is an owner set
    if (node.getOwner() == null || '' == node.getOwner()) {
      node.setOwner(owner);
    }

// get old node for update events
    var oldNode = mapper.get(node.getPath());

// write node
    mapper.update(node);

    checkListeners(EventType.UPDATE, oldNode, node, null, null);

// any child that is not a skeleton will be handled as new or changed
    for (var child in node.getChildren().values) {
      if (!child.isSkeleton()) {
        try {
          add(child);
        } on StorageException {
// node already exists, therefore it was changed
          update(child);
        }
      }
    }
  }

  @override
  Node delete(String path) {
    var ret = mapper.delete(path);
    checkListeners(EventType.DELETE, ret, null, null, null);
    return ret;
  }

  @override
  void rename(String oldPath, String newPathOrName) {
    var oldNode = mapper.get(oldPath) as NodeImpl;
    var newPath = newPathOrName;
    if (!newPathOrName.startsWith(PATH_DELIMITER)) {
// create path from name
      newPath = oldNode.getParentPath() + PATH_DELIMITER + newPathOrName;
    }
    mapper.rename(oldPath, newPath);
    var newNode = mapper.get(newPath) as NodeImpl;
    checkListeners(EventType.RENAME, oldNode, newNode, null, null);
  }

  @override
  NodeValue? getValue(String path, String key) {
    return mapper.getValue(path, key);
  }

  @override
  void addValue(String nodeName, NodeValue newValue) {
    var oldNode = mapper.get(nodeName);
    var oldValue = oldNode.getValue(newValue.getKey());
    if (oldValue != null) {
      throw StorageException(
          'value \"' + newValue.getKey() + '\" is already set');
    }
    var newNode = oldNode.deepClone();
    newNode.addValue(newValue);
    mapper.update(newNode);
    checkListeners(EventType.UPDATE, oldNode, newNode, null, newValue);
  }

  @override
  void updateValue(String nodeName, NodeValue newValue) {
    var oldNode = mapper.get(nodeName);
    var oldValue = oldNode.getValue(newValue.getKey());
    if (oldValue == null) {
      throw StorageException(
          'value \"' + newValue.getKey() + '\" does not yet exist');
    }
    var newNode = oldNode.deepClone();
    newNode.removeValue(newValue.getKey());
    newNode.addValue(newValue);
    mapper.update(newNode);
    checkListeners(EventType.UPDATE, oldNode, newNode, oldValue, newValue);
  }

  @override
  NodeValue deleteValue(String nodeName, String key) {
    var oldNode = mapper.get(nodeName);
    var oldValue = oldNode.getValue(key);
    if (oldValue == null) {
      throw StorageException('value \"' + key + '\" does not yet exist');
    }
    var newNode = oldNode.deepClone();
    newNode.removeValue(key);
    mapper.update(newNode);
    checkListeners(EventType.UPDATE, oldNode, newNode, oldValue, null);
    return oldValue;
  }

  @override
  List<Node> search(SearchCriteria criteria) {
    return mapper.search(criteria);
  }

  @override
  void close() {
    mapper.close();
  }

  @override
  void flush() {
    // nothing to do with H2 (flushes roughly after a second)
  }

  void checkListeners(final EventType event, final Node? oldNode,
      final Node? newNode, NodeValue? oldValue, NodeValue? newValue) {
    if (oldNode == null || oldNode != newNode) {
      // synchronized(listeners) {
      for (var e in listeners.entries) {
        try {
          if ((oldNode != null &&
                  newNode != null &&
                  (e.key.evaluate(oldNode) || e.key.evaluate(newNode))) ||
              (oldNode != null && e.key.evaluate(oldNode)) ||
              (newNode != null && e.key.evaluate(newNode))) {
            Future.microtask(() {
              try {
                e.value.gotStorageChange(event, oldNode, newNode);
              } on StorageException {
                // FIXME do something sensible (should not happen anyway)
              }
            });
          }
        } on StorageException {
          // FIXME do something sensible (should not happen anyway)
        }
      }
      // }
    }
  }

  @override
  void registerChangeListener(
      StorageListener listener, SearchCriteria criteria) {
    // synchronized(listeners) {
    listeners[criteria] = listener;
    // }
  }

  @override
  List<SearchCriteria> deregisterChangeListener(StorageListener listener) {
    var remove = List<SearchCriteria>.empty(growable: true);
    // synchronized(listeners) {
    for (var e in listeners.entries) {
      if (e.value == listener) {
        remove.add(e.key);
      }
    }
    for (var c in remove) {
      listeners.remove(c);
    }
    return remove;
    // }
  }

  @override
  void zap() {
    mapper.zap();
    initMapper();
  }
}
