package ch.fhnw.geiger.totalcross;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

/**
 * Compatibility class running under total cross and
 */
public class ByteArrayOutputStream implements TcByteArrayOutputStream {

  private abstract class AbstractWrapper implements TcByteArrayOutputStream {

    void write(Object o, byte[] buf) {
      try {
        Method m = o.getClass().getMethod("write", new Class[]{byte[].class, int.class, int.class});
        m.invoke(o, buf, 0, buf.length);
      } catch (InvocationTargetException | IllegalAccessException | NoSuchMethodException e) {
        // FIXME insert proper logging/error handling (but should not be called
        e.printStackTrace();
      }
    }

    byte[] toByteArray(Object o) {
      try {
        Method m = o.getClass().getMethod("toByteArray", new Class[]{});
        byte[] buf = (byte[])m.invoke(o);
        return buf;
      } catch (InvocationTargetException | IllegalAccessException | NoSuchMethodException e) {
        // FIXME insert proper logging/error handling (but should not be called
        e.printStackTrace();
      }
      return null;
    }

  }

  private class TcWrapper extends AbstractWrapper {

    Object o;

    public TcWrapper() {
      try {
        Class cls = Class.forName("totalcross.io.ByteArrayStream");
        Class partypes[] = new Class[]{};
        Constructor ct = cls.getConstructor(partypes);
        Object arglist[] = new Object[]{};
        o = ct.newInstance(arglist);
      } catch (Exception e) {
        // FIXME insert proper logging/error handling (but should not be called
        e.printStackTrace();
      }
    }

    public void write(byte[] buf) {
      write(o, buf);
    }

    @Override
    public byte[] toByteArray() {
      return toByteArray(o);
    }
  }


  private class JavaWrapper extends AbstractWrapper {

    Object o;

    public JavaWrapper() {
      try {
        Class cls = Class.forName("java.io.ByteArrayOutputStream");
        Class partypes[] = new Class[]{};
        Constructor ct = cls.getConstructor(partypes);
        Object arglist[] = new Object[]{};
        o = ct.newInstance(arglist);
      } catch (Exception e) {
        // FIXME insert proper logging/error handling (but should not be called
        e.printStackTrace();
      }
    }

    @Override
    public void write(byte[] buf) {
      write(o, buf);
    }

    @Override
    public byte[] toByteArray() {
      return toByteArray(o);
    }
  }

  TcByteArrayOutputStream is;

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

  public static boolean isTotalCross() {
    try {
      Class.forName("totalcross.io.ByteArrayStream");
      return true;
    } catch (Exception e) {
      return false;
    }
  }

}
