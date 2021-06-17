package ch.fhnw.geiger.totalcross;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

/**
 * Class that creates Wrappers for the System class.
 */
public class System {


  private static class TcWrapper implements TcSystem {

    Class<?> cls;
    Class<?> tcls;
    String platform;

    public TcWrapper() {
      cls = Integer.class;
      try {
        cls = Class.forName("totalcross.sys.Settings");
        tcls = Class.forName("totalcross.sys.Time");
        // FIXME: Implementation missing
        platform = "win";
        //platform = (String) (cls.getField("platform").get(null));
        //throw new RuntimeException("## platform=" + platform);
      } catch (Exception e) {
        // FIXME insert proper logging/error handling (but should not be called anyway)
        e.printStackTrace();
      }
    }

    @Override
    public String getProperty(String property) {
      if ("os.name".equals(property)) {
        return platform;
      } else {
        return null;
      }
    }

    @Override
    public String lineSeparator() {
      String os = getProperty("os.name");
      if (os.contains("win")) {
        return "\r\n";
      } else {
        return "\n";
      }
    }

    @Override
    public long currentTimeMillis() {
      try {
        Constructor<?> constructor = tcls.getConstructor( new Class[]{});
        Object obj = constructor.newInstance(new Object[0]);
        Method method = tcls.getMethod("getTime", new Class[]{});
        return (long) (method.invoke(obj));
      } catch (IllegalAccessException | InvocationTargetException | NoSuchMethodException | InstantiationException e) {
        // FIXME insert proper logging/error handling (but should not be called anyway)
        e.printStackTrace();
        return 0;
      }
    }


  }


  private static class JavaWrapper implements TcSystem {

    Class cls;

    public JavaWrapper() {
      try {
        cls = Class.forName("java.lang.System");
      } catch (Exception e) {
        // FIXME insert proper logging/error handling (but should not be called anyway)
        e.printStackTrace();
      }
    }

    @Override
    public String getProperty(String property) {
      try {
        Method method = cls.getMethod("getProperty", new Class[]{String.class});
        return (String) (method.invoke(null, property));
      } catch (IllegalAccessException | InvocationTargetException | NoSuchMethodException e) {
        // FIXME insert proper logging/error handling (but should not be called anyway)
        e.printStackTrace();
        return null;
      }
    }

    @Override
    public String lineSeparator() {
      try {
        Method method = cls.getMethod("lineSeparator", new Class[]{});
        return (String) (method.invoke(null));
      } catch (IllegalAccessException | InvocationTargetException | NoSuchMethodException e) {
        // FIXME insert proper logging/error handling (but should not be called anyway)
        e.printStackTrace();
        return null;
      }
    }

    @Override
    public long currentTimeMillis() {
      try {
        Method method = cls.getMethod("currentTimeMillis", new Class[]{});
        return (long) (method.invoke(null));
      } catch (IllegalAccessException | InvocationTargetException | NoSuchMethodException e) {
        // FIXME insert proper logging/error handling (but should not be called anyway)
        e.printStackTrace();
        return 0;
      }
    }
  }

  static TcSystem sys;

  // Creates either a TotalCross-wrapper or a Java-wrapper.
  static {
    if (TcHelper.isTotalCross()) {
      sys = new TcWrapper();
    } else {
      sys = new JavaWrapper();
    }
  }

  public static String getProperties(String property) {
    return sys.getProperty(property);
  }

  public static String lineSeparator() {
    return sys.lineSeparator();
  }

  public static long currentTimeMillis() {
    return sys.currentTimeMillis();
  }

}
