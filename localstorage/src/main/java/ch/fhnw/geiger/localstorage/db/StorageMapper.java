package ch.fhnw.geiger.localstorage.db;

import ch.fhnw.geiger.localstorage.SearchCriteria;
import ch.fhnw.geiger.localstorage.StorageController;
import ch.fhnw.geiger.localstorage.StorageException;
import ch.fhnw.geiger.localstorage.db.data.Node;
import ch.fhnw.geiger.localstorage.db.data.NodeValue;
import java.util.List;

/**
 * <p>Generic interface to define the common methods between databases.</p>
 *
 * @author Sacha
 */
public interface StorageMapper {

  /**
   * <p>Sets the controller to be used when creating skeletons.</p>
   *
   * @param controller the controller to be used to resolve skeletons
   */
  void setController(StorageController controller);

  /**
   * <p>Get a node by node name from the storage backend.</p>
   *
   * @param path the fully qualified node name
   * @return the requested node
   * @throws StorageException if node is not found or an error in the storage API happens
   */
  Node get(String path) throws StorageException;

  /**
   * <p>Add a non existing node to the storage backend.</p>
   *
   * @param node the node to be added to the backend
   * @throws StorageException if the node already exists, the parental node does not exist,
   *                          or the backend storage encountered a problem
   */
  void add(Node node) throws StorageException;

  /**
   * <p>Update an already existing node with the current values.</p>
   *
   * <p>
   * All current values of the passed on node are written into the new node. Any non existing
   * values are removed.
   * </p>
   *
   * @param node the node with the values to be written
   * @throws StorageException if the node does not exist or an error happened in the storage
   *                          backend.
   */
  void update(Node node) throws StorageException;

  /**
   * <p>Remove the named node.</p>
   *
   * @param path the fully qualified path of the node to be removed
   * @return A representation of the removed node
   * @throws StorageException if the node does not exist, the node contains at least one child,
   *                          or an error happened on the backend
   */
  Node delete(String path) throws StorageException;

  /**
   * <p>Fetch a value from a node.</p>
   *
   * @param path the fully qualified path to a node.
   * @param key  the key to be fetched
   * @return a representation of the node value
   *
   * @throws StorageException if the storage backend encounters a problem
   */
  NodeValue getValue(String path, String key) throws StorageException;

  /**
   * <p>Renames or moves an existing node.</p>
   *
   * @param oldPath       the old path of the node as fully qualified name
   * @param newPathOrName the new path of the node as fully qualified path or the new name of the
   *                      node
   * @throws StorageException if the new node already exists, the old node does not exist, the new
   *                          parent node does not exist or the storage backed encountered
   *                          problems
   */
  void rename(String oldPath, String newPathOrName) throws StorageException;

  /**
   * <p>Search all nodes matching the provided search criteria.</p>
   *
   * @param criteria the matching criteria (@see ch.fhnw.geiger.localstorage.SearchCriteria for
   *                 specification of search)
   * @return the nodes matching the criteria
   * @throws StorageException if the storage backend encounters a problem
   */
  List<Node> search(SearchCriteria criteria) throws StorageException;

  /**
   * <p>closes the database backed and flushes all data.</p>
   */
  void close();

  /**
   * <p>Flushes all data possible to the disk.</p>
   */
  void flush();

  /**
   * <p>Zaps the current database and discards all vaules.</p>
   *
   * @throws StorageException In case of problems regarding the storage
   */
  void zap() throws StorageException;
}
