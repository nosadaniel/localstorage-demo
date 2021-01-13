package ch.fhnw.geiger.localstorage;

import ch.fhnw.geiger.localstorage.db.data.Node;

/**
 * <p>Listener interface for storage events.</p>
 */
public interface StorageListener {

  /***
   * <p>Event listener for all starge node changes.</p>
   *
   * @param event the type of event causing the call
   * @param oldNode the old node content
   * @param newNode the new node content
   */
  void gotStorageChange(EventType event, Node oldNode, Node newNode);

}
