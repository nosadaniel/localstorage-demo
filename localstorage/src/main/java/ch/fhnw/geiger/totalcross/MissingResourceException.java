package ch.fhnw.geiger.totalcross;

/**
 * Exception to be thrown when a Resource is missing.
 */
public class MissingResourceException extends RuntimeException {

  private final String classname;
  private final String key;

  /**
   * MissingResourceException constructor.
   *
   * @param s Stacktrace
   * @param className Classname of missing resource
   * @param key Missing resource name
   */
  public MissingResourceException(String s, String className, String key) {
    super(s);
    this.classname = className;
    this.key = key;
  }

}
