import 'dart:collection';

import 'package:localstorage/src/StorageException.dart';
import 'package:localstorage/src/db/data/Node.dart';
import 'package:localstorage/src/db/data/NodeImpl.dart';
import 'package:localstorage/src/db/data/NodeValue.dart';

import '../../SearchCriteria.dart';
import '../../StorageController.dart';
import '../GenericController.dart';
import 'AbstractMapper.dart';

/// <p>A non-persisting dummy mapper for test purposes.</p>
class DummyMapper extends AbstractMapper {
  final Map<String, Node> nodes = HashMap();
  StorageController? controller;

  @override
  void setController(StorageController controller) {
    this.controller = controller;
  }

  @override
  Node get(String path) {
    checkPath(path);
    getSanity(path);
    var ret = nodes[path];
    if (ret == null) {
      throw StorageException('Node not found');
    }
    if (ret.isTombstone()) {
      Node returnNode = NodeImpl.fromPath(path, isTombstone: true);
      returnNode.setVisibility(ret.getVisibility());
      return returnNode;
    }
    return ret.deepClone();
  }

  void add(Node node) {
    checkPath(node.getPath());
    // synchronized(nodes, {
    if (nodes[node.getPath()] != null) {
      throw StorageException('Node does already exist');
    }
    if (node.isSkeleton()) {
      throw StorageException('Skeleton nodes cannot be added.');
    }
    if ((node.getParentPath() != null) && (!('' == node.getParentPath()))) {
      if (nodes[node.getParentPath()] == null) {
        throw StorageException(
            ('Parent node \"' + (node.getParentPath())) +
                '\" does not exist');
      }
      nodes[node.getParentPath()]?.addChild(node);
    }
    nodes[node.getPath()] = node.shallowClone();
    // });
  }

  void update(Node node) {
    checkPath(node.getPath());
    // synchronized(nodes, {
    if ((!('' == node.getParentPath())) &&
        (nodes[node.getParentPath()] == null)) {
      throw StorageException('Node does not exist');
    }
    nodes[node.getPath()]?.update(node);
    // });
  }

  void rename(String oldPath, String newPath) {
    checkPath(oldPath);
    checkPath(newPath);
    // synchronized(nodes, {
    var oldNode = nodes[oldPath];
    if (oldNode == null) {
      throw StorageException('Node does not exist');
    }
    var newNode = NodeImpl.fromPath(newPath);
    var owner = oldNode.getOwner();
    if (owner != null) newNode.setOwner(owner);
    newNode.setVisibility(oldNode.getVisibility());
    for (var nv in oldNode.getValues().values) {
      newNode.addValue(nv);
    }
    add(newNode);
    for (var n in oldNode.getChildren().values) {
      rename(
          n.getPath(),
          (newNode.getPath() + GenericController.PATH_DELIMITER) +
              n.getName());
    }
    delete(oldNode.getPath());
    // });
  }

  Node delete(String nodeName) {
    // synchronized(nodes, {
    var node = nodes[nodeName];
    if (node == null) {
      throw StorageException('Node does not exist');
    }
    if (!('' == node.getChildNodesCsv())) {
      throw StorageException(
          'Node does have children... cannot remove ' + nodeName);
    }
    nodes.remove(node);
    Node tombstone = NodeImpl.fromPath(node.getPath(), isTombstone: true);
    tombstone.setVisibility(node.getVisibility());
    nodes[node.getPath()] = tombstone;
    if ((node.getParentPath() != null) && (!("" == node.getParentPath()))) {
      nodes[node.getParentPath()]!.removeChild(node.getName());
    }
    return node;
    // });
  }

  NodeValue getValue(String path, String key) {
    var ret = get(path);
    if (ret.isTombstone()) {
      throw StorageException('node does not exist');
    }
    return ret.getValues()[key]!;
  }

  List<Node> search(SearchCriteria criteria) {
    var l = List<Node>.empty(growable: true);
    for (var e in nodes.entries) {
      if (criteria.evaluate(e.value)) {
        l.add(e.value);
      }
    }
    return l;
  }

  void close() {}

  void flush() {}

  void zap() {
    // synchronized(nodes, {
    nodes.clear();
    // });
  }
}
