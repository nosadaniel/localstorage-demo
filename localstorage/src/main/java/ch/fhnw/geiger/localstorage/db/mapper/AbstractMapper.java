package ch.fhnw.geiger.localstorage.db.mapper;

import ch.fhnw.geiger.localstorage.StorageException;
import ch.fhnw.geiger.localstorage.db.GenericController;
import ch.fhnw.geiger.localstorage.db.StorageMapper;
import ch.fhnw.geiger.localstorage.db.data.Node;

/**
 * <p>An abstract mapper providing general checks.</p>
 */
public abstract class AbstractMapper implements StorageMapper {

  protected void getSanity(String path) throws StorageException {
    if (path == null) {
      throw new NullPointerException("path may not be null");
    }
  }

  protected void checkPath(Node node) throws StorageException {
    checkPath(node.getPath());
  }

  protected void checkPath(String path) throws StorageException {
    if (path == null) {
      throw new StorageException("illegal path (may not be null)");
    }
    if (":".equals(path)) {
      return;
    }
    if (!path.matches("(" + GenericController.PATH_DELIMITER + "[a-zA-Z0-9\\-]+)*")) {
      throw new StorageException("illegal path detected in \"" + path + "\"");
    }
  }

}
