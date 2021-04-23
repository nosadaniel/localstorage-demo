package ch.fhnw.geiger.totalcross;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

/**
 * Compatibility class running under total cross and
 */
public class ByteArrayInputStream implements TcByteArrayInputStream {

  private abstract class AbstractWrapper implements TcByteArrayInputStream {

    int read(Object o, String methodName, byte[] buf) {
      try {
        Method m = o.getClass().getMethod(methodName, new Class[]{byte[].class, int.class, int.class});
        int bytesRead = (Integer) m.invoke(o, buf, 0, buf.length);
        return bytesRead;
      } catch (InvocationTargetException | IllegalAccessException | NoSuchMethodException e) {
        // FIXME insert proper logging/error handling (but should not be called
        e.printStackTrace();
      }
      return -1;
    }
  }

  private class TcWrapper extends AbstractWrapper {

    Object o;

    public TcWrapper(byte[] buf) {
      try {
        Class cls = Class.forName("totalcross.io.ByteArrayStream");
        Class partypes[] = new Class[]{byte[].class};
        Constructor ct = cls.getConstructor(partypes);
        Object arglist[] = new Object[]{buf};
        o = ct.newInstance(arglist);
      } catch (Exception e) {
        // FIXME insert proper logging/error handling (but should not be called
        e.printStackTrace();
      }
    }

    public int read(byte[] buf) {
      return read(o, "readBytes", buf);
    }
  }


  private class JavaWrapper extends AbstractWrapper {

    Object o;

    public JavaWrapper(byte[] buf) {
      try {
        Class cls = Class.forName("java.io.ByteArrayInputStream");
        Class partypes[] = new Class[]{byte[].class};
        Constructor ct = cls.getConstructor(partypes);
        Object arglist[] = new Object[]{buf};
        o = ct.newInstance(arglist);
      } catch (Exception e) {
        // FIXME insert proper logging/error handling (but should not be called
        e.printStackTrace();
      }
    }

    @Override
    public int read(byte[] buf) {
      return read(o, "read", buf);
    }
  }

  TcByteArrayInputStream is;

  public ByteArrayInputStream(byte[] buf) {
    if (isTotalCross()) {
      is = new TcWrapper(buf);
    } else {
      is = new JavaWrapper(buf);
    }
  }

  @Override
  public int read(byte[] buf) {
    return is.read(buf);
  }

  public static boolean isTotalCross() {
    try {
      Class.forName("totalcross.io.ByteArrayStream");
      return true;
    } catch (Exception e) {
      return false;
    }
  }

}
