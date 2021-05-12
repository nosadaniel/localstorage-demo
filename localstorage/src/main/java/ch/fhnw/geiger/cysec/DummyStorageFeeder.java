package ch.fhnw.geiger.cysec;

import ch.fhnw.geiger.localstorage.StorageController;
import ch.fhnw.geiger.localstorage.StorageException;
import ch.fhnw.geiger.localstorage.db.data.Node;
import ch.fhnw.geiger.localstorage.db.data.NodeImpl;
import ch.fhnw.geiger.localstorage.db.data.NodeValueImpl;
import ch.fhnw.geiger.localstorage.db.data.SwitchableBoolean;
import java.util.Random;

/***
 * <p>A feeder providing dummy content for a storage.</p>
 */
public class DummyStorageFeeder {

  private static class FeedRunner extends Thread {
    private StorageController controller;

    private boolean shutdown = false;

    private Object lock = new Object();

    private long interval;

    /***
     * <p>The feeding Runner thread for the feeder.</p>
     *
     * @param controller the controller to be fed
     * @param interval the intervall of the updates
     */
    public FeedRunner(StorageController controller, long interval) {
      this.controller = controller;
      this.interval = interval;
    }

    @Override
    public void run() {
      // creating plugin nodes
      for (String nodeName : new String[]{
          ":plugins",
          ":plugins:dummyFeeder",
          ":plugins:dummyFeeder:data",
          ":plugins:dummyFeeder:data:dummyBooleanValue",
          ":plugins:dummyFeeder:data:flippingBooleanValue",
          ":plugins:dummyFeeder:config"}) {
        try {
          controller.add(new NodeImpl(nodeName));
        } catch (StorageException se) {
          // we ignore storage exceptions assuming that the nodes do already exist
        }
      }
      // feeding template values into the nodes
      for (String nodeName : new String[]{
          ":plugins:dummyFeeder:data:dummyBooleanValue",
          ":plugins:dummyFeeder:data:flippingBooleanValue"}) {
        try {
          Node n = controller.get(nodeName);
          for (String keyName : new String[]{
              "minValue",
              "maxValue",
              "value"}) {
            n.addValue(new NodeValueImpl(keyName, ""));
          }
        }catch (StorageException e) {
          e.printStackTrace();
        }
      }
      Random r = new Random();
      while (!shutdown) {
        try {
          // get the dummy boolean value
          Node n = controller.get(":plugins:dummyFeeder:data:dummyBooleanValue");
          SwitchableBoolean b = new SwitchableBoolean("0".equals(n.getValue("value").getValue()));
          if (r.nextInt(10) == 0) {
            b.toggle();
          }
          n.updateValue(new NodeValueImpl("minValue", b.get() ? "1" : "0"));
          n.updateValue(new NodeValueImpl("minValue", "0"));
          n.updateValue(new NodeValueImpl("maxValue", "1"));

          // update the flipping boolean
          n = controller.get(":plugins:dummyFeeder:data:flippingBooleanValue");
          b = new SwitchableBoolean("0".equals(n.getValue("value").getValue()));
          b.toggle();
          n.updateValue(new NodeValueImpl("minValue", b.get() ? "1" : "0"));
          n.updateValue(new NodeValueImpl("minValue", "0"));
          n.updateValue(new NodeValueImpl("maxValue", "1"));
          Thread.sleep(interval);
        } catch (InterruptedException ie) {
          // we just ignore it...
        } catch(StorageException e) {
          // TODO replace with something sensible
          e.printStackTrace();
        }
      }
      synchronized (lock) {
        lock.notifyAll();
      }
    }

    /***
     * <p>Set te interval period of the feeder.</p>
     *
     * @param milliseconds the interval to be used
     * @return the previously set interval
     */
    public long setInterval(long milliseconds) {
      long ret = interval;
      interval = milliseconds;
      return ret;
    }

    /***
     * <p>Shut down the feeder.</p>
     */
    public void shutdown() {
      shutdown = true;
      while (this.isAlive()) {
        synchronized (lock) {
          try {
            lock.wait(10);
          } catch (InterruptedException ie) {
            // we ignore it to reloop if necessary
          }
        }
      }
    }

  }

  private final StorageController controller;

  private FeedRunner runner;

  private long interval = 1000;

  /***
   * <p>Create a storage feeder for the specified controller.</p>
   *
   * @param controller the controller to be fed with values
   */
  public DummyStorageFeeder(StorageController controller) {
    this.controller = controller;
    startFeeder();
  }

  /**
   * <p>start the feeder updates.</p>
   */
  public void startFeeder() {
    if (this.runner != null) {
      return;
    }
    this.runner = new FeedRunner(controller, interval);
    runner.start();
  }

  /**
   * <p>Stop the feeder updates.</p>
   */
  public void stopFeeder() {
    if (this.runner != null) {
      synchronized (runner) {
        this.runner.shutdown();
        this.runner = null;
      }
    }
  }

  /**
   * <p>Sets the update interval in milliseconds.</p>
   *
   * @param milliseconds the new interval
   * @return the previously set interval in milliseconds
   */
  public long setInterval(long milliseconds) {
    long ret = interval;
    this.interval = milliseconds;
    if (runner != null) {
      runner.setInterval(milliseconds);
    }
    return ret;
  }
}
