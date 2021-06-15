package ch.fhnw.geiger.totalcross;

/**
 * Interface used for accessing system variables.
 */
public interface TcSystem {

  String getProperty(String property);

  String lineSeparator();

  long currentTimeMillis();

}
