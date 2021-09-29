library geiger_localstorage;

import 'dart:collection';

import 'package:geiger_localstorage/src/search_criteria.dart';
import 'package:geiger_localstorage/src/storage_listener.dart';
import 'package:uuid/uuid.dart';

import '../change_registrar.dart';
import '../event_type.dart';
import '../search_criteria.dart';
import '../storage_controller.dart';
import '../storage_exception.dart';
import 'storage_mapper.dart';
import 'data/node.dart';
import 'data/node_implementation.dart';
import 'data/node_value.dart';
import 'data/node_value_implementation.dart';

/// This Class Acts as an intermediate class to relay storageRequests to the StorageMapper.
///
/// This class contains the interaction API every actor (sensor, shields, UI,...)
/// calls methods from this controller to manipulate data.
class GenericController implements StorageController, ChangeRegistrar {
  static StorageController? defaultController;

  /// the path delimiter.
  static final String pathDelimiter = ':';

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
      '${pathDelimiter}Devices',
      '${pathDelimiter}Users',
      '${pathDelimiter}Enterprise',
      '${pathDelimiter}Keys',
      '${pathDelimiter}Global',
      '${pathDelimiter}Local'
    ];
    for (var nodeName in baseNodes) {
      try {
        // for correct path generation creation of a Node is needed
        Node tmp = NodeImpl.fromPath(nodeName);
        mapper.get(tmp.getPath()!);
      } on StorageException {
        // node does not exist and therefore we create it
        Node tmp = NodeImpl.fromPath(nodeName);
        tmp.setOwner(owner);
        mapper.add(tmp);
      }
    }

    // check if current user exists
    var localNode = mapper.get('${pathDelimiter}Local');
    var uuid = localNode.getValue('currentUser');
    if (uuid == null) {
      uuid = NodeValueImpl('currentUser', Uuid().v4());
      localNode.addOrUpdateValue(uuid);
      localNode.setOwner(owner);
      mapper.update(localNode);
    }

    // create new default user
    uuid = NodeValueImpl('currentUser', Uuid().v4());
    localNode.addOrUpdateValue(uuid);
    localNode.setOwner(owner);
    mapper.update(localNode);

    // check if current user node exists
    var userNodeName = '${pathDelimiter}Users$pathDelimiter' + uuid.getValue()!;
    try {
      mapper.get(userNodeName);
    } on StorageException {
      Node n = NodeImpl.fromPath(userNodeName);
      n.setOwner(owner);
      mapper.add(n);
    }

    // check if current device exists
    localNode = mapper.get('${pathDelimiter}Local');
    uuid = localNode.getValue('currentDevice');
    if (uuid == null) {
      // create new default device
      uuid = NodeValueImpl('currentDevice', Uuid().v4());
      localNode.addOrUpdateValue(uuid);
      localNode.setOwner(owner);
      mapper.update(localNode);
    }

    // check if current device node exists
    var deviceNodeName = '${pathDelimiter}Devices$pathDelimiter' + uuid.getValue()!;
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
      delete(node.getPath()!);
      return false;
    } else {
      var ret = false;
      try {
        add(node);
        ret = true;
      } on StorageException {
        update(node);
      }
      for (var n2 in node.getChildren().values) {
        ret |= addOrUpdate(n2);
      }
      return ret;
    }
  }

  @override
  Node get(String path) {
    var n = getNodeOrTombstone(path);
    if (n.isTombstone()) {
      throw StorageException('Node "$path" does not exist (but exited in the past; It is a tombstone now)');
    }
    var l = List<String>.empty(growable: true);
    for (var cn in n.getChildren().values) {
      if (cn.isTombstone()) {
        l.add(cn.getName()!);
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

    checkListeners(EventType.create, null, node, null, null);
  }

  @override
  void update(Node node) {
    // make sure that there is an owner set
    if (node.getOwner() == null || '' == node.getOwner()) {
      node.setOwner(owner);
    }

    // get old node for update events
    var oldNode = mapper.get(node.getPath()!);

    // write node
    mapper.update(node);

    checkListeners(EventType.update, oldNode, node, null, null);

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
    checkListeners(EventType.delete, ret, null, null, null);
    return ret;
  }

  @override
  void rename(String oldPath, String newPathOrName) {
    var oldNode = mapper.get(oldPath) as NodeImpl;
    var newPath = newPathOrName;
    if (!newPathOrName.startsWith(pathDelimiter)) {
      // create path from name
      newPath = oldNode.getParentPath()! + pathDelimiter + newPathOrName;
    }
    mapper.rename(oldPath, newPath);
    var newNode = mapper.get(newPath) as NodeImpl;
    checkListeners(EventType.rename, oldNode, newNode, null, null);
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
          'value "' + newValue.getKey() + '" is already set');
    }
    var newNode = oldNode.deepClone();
    newNode.addValue(newValue);
    mapper.update(newNode);
    checkListeners(EventType.update, oldNode, newNode, null, newValue);
  }

  @override
  void updateValue(String nodeName, NodeValue newValue) {
    var oldNode = mapper.get(nodeName);
    var oldValue = oldNode.getValue(newValue.getKey());
    if (oldValue == null) {
      throw StorageException(
          'value "' + newValue.getKey() + '" does not yet exist');
    }
    var newNode = oldNode.deepClone();
    newNode.removeValue(newValue.getKey());
    newNode.addValue(newValue);
    mapper.update(newNode);
    checkListeners(EventType.update, oldNode, newNode, oldValue, newValue);
  }

  @override
  NodeValue deleteValue(String nodeName, String key) {
    var oldNode = mapper.get(nodeName);
    var oldValue = oldNode.getValue(key);
    if (oldValue == null) {
      throw StorageException('value "' + key + '" does not yet exist');
    }
    var newNode = oldNode.deepClone();
    newNode.removeValue(key);
    mapper.update(newNode);
    checkListeners(EventType.update, oldNode, newNode, oldValue, null);
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
    for (var e in listeners.entries) {
      if (e.value == listener) {
        remove.add(e.key);
      }
    }
    if (remove.isEmpty) {
      throw StorageException('Listener not registered');
    }
    for (var c in remove) {
      listeners.remove(c);
    }
    return remove;
  }

  @override
  void zap() {
    mapper.zap();
    initMapper();
  }
}
