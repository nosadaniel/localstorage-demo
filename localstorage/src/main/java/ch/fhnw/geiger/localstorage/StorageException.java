package ch.fhnw.geiger.localstorage;

/**
 * <p>Exception to be raised on any problems related to the local storage.</p>
 */
public class StorageException extends IllegalStateException {

  public StorageException(String txt, Throwable e) {
    super(txt, e);
  }

  public StorageException(String txt) {
    this(txt, null);
  }

}
