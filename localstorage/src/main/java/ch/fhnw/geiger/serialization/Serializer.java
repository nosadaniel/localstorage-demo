package ch.fhnw.geiger.serialization;

import ch.fhnw.geiger.totalcross.ByteArrayInputStream;
import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;
import java.io.IOException;

/**
 * <p>Serializer interface for the serialization of value related objects.</p>
 */
public interface Serializer {

  /**
   * <p>Dummy static serializer.</p>
   *
   * <p>Must be overridden by the respective implementing class.</p>
   *
   * @param in The input byte stream to be used
   * @return the object parsed from the input stream by the respective class
   * @throws IOException if not overridden or reached unexpectedly the end of stream
   */
  static Object fromByteArrayStream(ByteArrayInputStream in) throws IOException {
    throw new IOException("Not implemented... ");
  }

  /**
   * <p>Writes the current object to the output stream.</p>
   *
   * @param out the output stream receiving the object
   * @throws IOException if  an exception occurs while writing to the stream
   */
  void toByteArrayStream(ByteArrayOutputStream out) throws IOException;

}