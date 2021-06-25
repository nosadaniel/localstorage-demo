package ch.fhnw.geiger.localstorage.db.mapper;

import ch.fhnw.geiger.localstorage.SearchCriteria;
import ch.fhnw.geiger.localstorage.StorageController;
import ch.fhnw.geiger.localstorage.StorageException;
import ch.fhnw.geiger.localstorage.db.GenericController;
import ch.fhnw.geiger.localstorage.db.data.Node;
import ch.fhnw.geiger.localstorage.db.data.NodeImpl;
import ch.fhnw.geiger.localstorage.db.data.NodeValue;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

/**
 * <p>A non-persisting dummy mapper for test purposes.</p>
 */
public class DummyMapper extends AbstractMapper {

  private final Map<String, Node> nodes = new HashMap<>();

  private StorageController controller = null;

  @Override
  public void setController(StorageController controller) {
    this.controller = controller;
  }

  @Override
  public Node get(String path) throws StorageException {
    checkPath(path);
    getSanity(path);
    Node ret = nodes.get(path);
    if (ret == null) {
      throw new StorageException("Node not found");
    }
    if (ret.isTombstone()) {
      Node returnNode = new NodeImpl(path, true);
      returnNode.setVisibility(ret.getVisibility());
      return returnNode;
    }
    return ret.deepClone();
  }

  @Override
  public void add(Node node) throws StorageException {
    checkPath(node);
    synchronized (nodes) {
      if (nodes.get(node.getPath()) != null) {
        throw new StorageException("Node does already exist");
      }
      if (node.isSkeleton()) {
        throw new StorageException("Skeleton nodes cannot be added.");
      }

      // check if parent node is available
      if (node.getParentPath() != null && !"".equals(node.getParentPath())) {
        if (nodes.get(node.getParentPath()) == null) {
          throw new StorageException("Parent node \"" + node.getParentPath() + "\" does not exist");
        }
        // add reference to parent
        nodes.get(node.getParentPath()).addChild(node);
      }
      // add node
      nodes.put(node.getPath(), node.shallowClone());
    }
  }

  @Override
  public void update(Node node) throws StorageException {
    checkPath(node);
    synchronized (nodes) {
      if (!"".equals(node.getParentPath()) && nodes.get(node.getParentPath()) == null) {
        throw new StorageException("Node does not exist");
      }
      nodes.get(node.getPath()).update(node);
    }
  }

  @Override
  public void rename(String oldPath, String newPath) throws StorageException {
    checkPath(oldPath);
    checkPath(newPath);
    synchronized (nodes) {
      if (nodes.get(oldPath) == null) {
        throw new StorageException("Node does not exist");
      }
      Node oldNode = nodes.get(oldPath);

      // clone node at new location
      NodeImpl newNode = new NodeImpl(newPath);

      // copy ordinals
      newNode.setOwner(oldNode.getOwner());
      newNode.setVisibility(oldNode.getVisibility());

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
      delete(oldNode.getPath());
    }
  }

  @Override
  public Node delete(String nodeName) throws StorageException {
    synchronized (nodes) {
      if (nodes.get(nodeName) == null) {
        throw new StorageException("Node does not exist");
      }
      if (!"".equals(nodes.get(nodeName).getChildNodesCsv())) {
        throw new StorageException("Node does have children... cannot remove " + nodeName);
      }
      Node n = nodes.remove(nodeName);
      // add tombstone
      Node tombstone = new NodeImpl(n.getPath(), true);
      tombstone.setVisibility(n.getVisibility());
      nodes.put(n.getPath(), tombstone);
      if (n.getParentPath() != null && !"".equals(n.getParentPath())) {
        nodes.get(n.getParentPath()).removeChild(n.getName());
      }
      return n;
    }
  }

  @Override
  public NodeValue getValue(String path, String key) throws StorageException {
    Node ret = get(path);
    if (ret.isTombstone()) {
      throw new StorageException("Not does not exist");
    }
    return ret.getValues().get(key);
  }

  @Override
  public List<Node> search(SearchCriteria criteria) throws StorageException {
    List<Node> l = new Vector<>();
    for (Map.Entry<String, Node> e : nodes.entrySet()) {
      if (criteria.evaluate(e.getValue())) {
        l.add(e.getValue());
      }
    }
    return l;
  }

  @Override
  public void close() {
    // not required for the dummy wrapper as there is no persistence
  }

  @Override
  public void flush() {
    // not required for the dummy wrapper as there is no persistence
  }

  @Override
  public void zap() {
    synchronized (nodes) {
      nodes.clear();
    }
  }
}
