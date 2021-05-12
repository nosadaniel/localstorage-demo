package ch.fhnw.geiger.totalcross;

public class MissingResourceException extends RuntimeException {

  private String classname;
  private String key;

  public MissingResourceException(String s, String className, String key) {
    super(s);
    this.classname=className;
    this.key=key;
  }

}
