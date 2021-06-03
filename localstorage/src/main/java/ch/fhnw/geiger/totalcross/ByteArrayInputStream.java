package ch.fhnw.geiger.totalcross;

import java.io.IOException;
import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

/**
 * Compatibility class running under total cross and java.
 */
public class ByteArrayInputStream implements TcByteArrayInputStream {

  private abstract class AbstractWrapper implements TcByteArrayInputStream {

    int read(Object o, String methodName, byte[] buf) {
      try {
        Method m = o.getClass().getMethod(methodName,
            new Class[]{byte[].class, int.class, int.class});
        int bytesRead = (Integer) m.invoke(o, buf, 0, buf.length);
        return bytesRead;
      } catch (InvocationTargetException | IllegalAccessException | NoSuchMethodException e) {
        // FIXME insert proper logging/error handling (but should not be called
        e.printStackTrace();
      }
      return -1;
    }

    public void close(Object o) throws IOException {
      try {
        Method m = o.getClass().getMethod("close",
            new Class[]{});
        m.invoke(o);
      } catch (InvocationTargetException | IllegalAccessException | NoSuchMethodException e) {
        // FIXME insert proper logging/error handling (but should not be called anyway)
        e.printStackTrace();
      }
    }

    public abstract void close() throws IOException;
  }

  private class TcWrapper extends AbstractWrapper {

    Object obj;

    public TcWrapper(byte[] buf) {
      try {
        Class cls = Class.forName("totalcross.io.ByteArrayStream");
        Class[] partypes = new Class[]{byte[].class};
        Constructor ct = cls.getConstructor(partypes);
        Object[] arglist = new Object[]{buf};
        obj = ct.newInstance(arglist);
      } catch (Exception e) {
        // FIXME insert proper logging/error handling (but should not be called
        e.printStackTrace();
      }
    }

    public int read(byte[] buf) {
      return read(obj, "readBytes", buf);
    }

    @Override
    public void close() throws IOException{
      close(obj);
    }
  }


  private class JavaWrapper extends AbstractWrapper {

    Object obj;

    public JavaWrapper(byte[] buf) {
      try {
        Class cls = Class.forName("java.io.ByteArrayInputStream");
        Class[] partypes = new Class[]{byte[].class};
        Constructor ct = cls.getConstructor(partypes);
        Object[] arglist = new Object[]{buf};
        obj = ct.newInstance(arglist);
      } catch (Exception e) {
        // FIXME insert proper logging/error handling (but should not be called
        e.printStackTrace();
      }
    }

    @Override
    public int read(byte[] buf) {
      return read(obj, "read", buf);
    }

    @Override
    public void close() throws IOException{
      close(obj);
    }
  }

  TcByteArrayInputStream is;

  /**
   * Creates either a TotalCross-wrapper or a Java-wrapper.
   *
   * @param buf the byte buffer to be used for the inputstrema
   */
  public ByteArrayInputStream(byte[] buf) {
    if (TcHelper.isTotalCross()) {
      is = new TcWrapper(buf);
    } else {
      is = new JavaWrapper(buf);
    }
  }

  @Override
  public int read(byte[] buf) {
    return is.read(buf);
  }

  @Override
  public void close() throws Exception {
    is.close();
  }

}
