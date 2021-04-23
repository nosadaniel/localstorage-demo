package ch.fhnw.geiger.totalcross;

import java.lang.reflect.InvocationTargetException;

interface TcByteArrayInputStream {
  /**
   * <p>Reads the next byte of data from this input stream.</p>
   *
   * @param buf the byte array to be filled
   * @return the next byte of data, or -1 if the end of the stream has been reached.
   */
  int read(byte[] buf);
}
