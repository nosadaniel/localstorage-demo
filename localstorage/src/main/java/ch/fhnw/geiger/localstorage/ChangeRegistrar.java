package ch.fhnw.geiger.localstorage;

/**
 * <p>Interface for registrar support for change listeners.</p>
 */
public interface ChangeRegistrar {

  /***
   * <p>Registers a listener for a specific search criteria.</p>
   *
   * @param listener the listener to be added
   * @param criteria the criteria triggering calls to the listener
   */
  void registerChangeListener(StorageListener listener, SearchCriteria criteria);

  /***
   * <p>Removes a registered listener.</p>
   *
   * @param listener the listener to be removed
   * @return the removed search criteria
   */
  SearchCriteria[] deregisterChangeListener(StorageListener listener);
}
