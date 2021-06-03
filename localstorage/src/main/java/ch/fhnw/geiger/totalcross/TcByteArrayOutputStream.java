package ch.fhnw.geiger.totalcross;

interface TcByteArrayOutputStream extends AutoCloseable {
  /**
   * <p>Writes a byte array to the stream.</p>
   *
   * @param buf the byte array to be written
   */
  void write(byte[] buf);

  /**
   * <p>Creates a newly allocated byte array.</p>
   *
   * <p>Its size is the current size of this output stream and the valid contents of the buffer
   * have been copied into it.</p>
   *
   * @return the current contents of this output stream, as a byte array.
   */
  byte[] toByteArray();
}
