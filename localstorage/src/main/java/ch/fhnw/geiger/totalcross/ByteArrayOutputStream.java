package ch.fhnw.geiger.totalcross;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

/**
 * Compatibility class running under total cross and java.
 */
public class ByteArrayOutputStream implements TcByteArrayOutputStream {

  private abstract class AbstractWrapper implements TcByteArrayOutputStream {

    void write(Object o, String methodName, byte[] buf) {
      try {
        Method m = o.getClass().getMethod(methodName,
            new Class[]{byte[].class, int.class, int.class});
        m.invoke(o, buf, 0, buf.length);
      } catch (InvocationTargetException | IllegalAccessException | NoSuchMethodException e) {
        // FIXME insert proper logging/error handling (but should not be called
        e.printStackTrace();
      }
    }

    byte[] toByteArray(Object o) {
      try {
        Method m = o.getClass().getMethod("toByteArray", new Class[]{});
        byte[] buf = (byte[]) m.invoke(o);
        return buf;
      } catch (InvocationTargetException | IllegalAccessException | NoSuchMethodException e) {
        // FIXME insert proper logging/error handling (but should not be called
        e.printStackTrace();
      }
      return null;
    }

  }

  private class TcWrapper extends AbstractWrapper {

    Object obj;

    public TcWrapper() {
      try {
        Class cls = Class.forName("totalcross.io.ByteArrayStream");
        Class[] partypes = new Class[]{int.class};
        Constructor ct = cls.getConstructor(partypes);
        Object[] arglist = new Object[]{0};
        obj = ct.newInstance(arglist);
      } catch (Exception e) {
        // FIXME insert proper logging/error handling (but should not be called
        e.printStackTrace();
      }
    }

    public void write(byte[] buf) {
      write(obj, "writeBytes", buf);
    }

    @Override
    public byte[] toByteArray() {
      return toByteArray(obj);
    }
  }


  private class JavaWrapper extends AbstractWrapper {

    Object obj;

    public JavaWrapper() {
      try {
        Class cls = Class.forName("java.io.ByteArrayOutputStream");
        Class[] partypes = new Class[]{};
        Constructor ct = cls.getConstructor(partypes);
        Object[] arglist = new Object[]{};
        obj = ct.newInstance(arglist);
      } catch (Exception e) {
        // FIXME insert proper logging/error handling (but should not be called
        e.printStackTrace();
      }
    }

    @Override
    public void write(byte[] buf) {
      write(obj, "write", buf);
    }

    @Override
    public byte[] toByteArray() {
      return toByteArray(obj);
    }
  }

  TcByteArrayOutputStream is;

  /**
   * Creates either a TotalCross-wrapper or a Java-wrapper.
   */
  public ByteArrayOutputStream() {
    if (isTotalCross()) {
      is = new TcWrapper();
    } else {
      is = new JavaWrapper();
    }
  }

  @Override
  public void write(byte[] buf) {
    is.write(buf);
  }

  @Override
  public byte[] toByteArray() {
    return is.toByteArray();
  }

  /**
   * Checks if it runs inside a TotalCross environment.
   *
   * @return true if it is a TotalCross environment, false otherwise
   */
  public static boolean isTotalCross() {
    try {
      Class.forName("totalcross.io.ByteArrayStream");
      return true;
    } catch (Exception e) {
      return false;
    }
  }

}
