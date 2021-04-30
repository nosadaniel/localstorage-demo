package ch.fhnw.geiger.serialization;

import ch.fhnw.geiger.totalcross.ByteArrayInputStream;
import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;

/**
 * <p>Helper class for serialization serializes important java primitives.</p>
 */
public class SerializerHelper {

  private static final long STRING_UID = 123798371293L;
  private static final long LONG_UID = 1221312393L;
  private static final long INT_UID = 122134568793L;
  private static final long STACKTRACES_UID = 9012350123956L;

  private static void writeIntLong(ByteArrayOutputStream out, Long l) throws IOException {
    ByteBuffer b = ByteBuffer.allocate(Long.BYTES);
    b.putLong(l);
    out.write(b.array());
  }

  private static Long readIntLong(ByteArrayInputStream in) throws IOException {
    int size = Long.BYTES;
    ByteBuffer b = ByteBuffer.allocate(size);
    byte[] arr = new byte[size];
    in.read(arr);
    b.put(arr, 0, size);
    b.flip();
    return b.getLong();
  }

  private static void writeIntInt(ByteArrayOutputStream out, Integer l) throws IOException {
    ByteBuffer b = ByteBuffer.allocate(Integer.BYTES);
    b.putInt(l);
    out.write(b.array());
  }

  private static Integer readIntInt(ByteArrayInputStream in) throws IOException {
    int size = Integer.BYTES;
    ByteBuffer b = ByteBuffer.allocate(size);
    byte[] arr = new byte[size];
    in.read(arr);
    b.put(arr, 0, size);
    b.flip();
    return b.getInt();
  }

  /**
   * <p>Serialize a long variable.</p>
   *
   * @param out the stream to be read
   * @param l   the value to be deserialized
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static void writeLong(ByteArrayOutputStream out, Long l) throws IOException {
    writeIntLong(out, LONG_UID);
    writeIntLong(out, l);
  }

  /**
   * <p>Deserialize a long variable.</p>
   *
   * @param in the stream to be read
   * @return the deserialized long value
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static Long readLong(ByteArrayInputStream in) throws IOException {
    if (readIntLong(in) != LONG_UID) {
      throw new ClassCastException();
    }
    return readIntLong(in);
  }

  /**
   * <p>Serialize an int variable.</p>
   *
   * @param out the stream to be read
   * @param i   the value to be deserialized
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static void writeInt(ByteArrayOutputStream out, Integer i) throws IOException {
    writeIntLong(out, INT_UID);
    writeIntInt(out, i);
  }

  /**
   * <p>Deserialize an int variable.</p>
   *
   * @param in the stream to be read
   * @return the deserialized integer value
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static Integer readInt(ByteArrayInputStream in) throws IOException {
    if (readIntLong(in) != INT_UID) {
      throw new ClassCastException();
    }
    return readIntInt(in);
  }

  /**
   * <p>Serialize a string variable.</p>
   *
   * @param out the stream to be read
   * @param s   the value to be deserialized
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static void writeString(ByteArrayOutputStream out, String s) throws IOException {
    writeIntLong(out, STRING_UID);
    if (s == null) {
      writeIntInt(out, -1);
    } else {
      writeIntInt(out, s.length());
      out.write(s.getBytes(StandardCharsets.UTF_8));
    }
  }

  /**
   * <p>Deserialize a string variable.</p>
   *
   * @param in the stream to be read
   * @return the deserialized string
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static String readString(ByteArrayInputStream in) throws IOException {
    if (readIntLong(in) != STRING_UID) {
      throw new ClassCastException();
    }
    int length = readIntInt(in);
    if (length == -1) {
      return null;
    } else {
      byte[] arr = new byte[length];
      in.read(arr);
      return new String(arr, StandardCharsets.UTF_8);
    }
  }

  /**
   * <p>Serialize an array of StackTraces.</p>
   *
   * @param out the stream to be read
   * @param ste the value to be deserialized
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static void writeStackTraces(ByteArrayOutputStream out, StackTraceElement[] ste)
      throws IOException {
    writeIntLong(out, STACKTRACES_UID);
    if (ste == null) {
      writeIntInt(out, -1);
    } else {
      writeIntInt(out, ste.length);
      for (StackTraceElement st : ste) {
        writeString(out, st.getClassName());
        writeString(out, st.getMethodName());
        writeString(out, st.getFileName());
        writeInt(out, st.getLineNumber());
      }
    }
  }

  /**
   * <p>Deserialize an array of StackTraceElement variable.</p>
   *
   * @param in the stream to be read
   * @return the deserialized array
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static StackTraceElement[] readStackTraces(ByteArrayInputStream in) throws IOException {
    if (readIntLong(in) != STACKTRACES_UID) {
      throw new ClassCastException();
    }
    int length = readIntInt(in);
    if (length == -1) {
      return null;
    } else {
      StackTraceElement[] arr = new StackTraceElement[length];
      for (int i = 0; i < length; i++) {
        arr[i] = new StackTraceElement(readString(in), readString(in), readString(in), readInt(in));
      }
      return arr;
    }
  }

}
