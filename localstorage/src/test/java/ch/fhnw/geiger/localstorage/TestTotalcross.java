package ch.fhnw.geiger.localstorage;

import org.junit.Assert;
import org.junit.Test;

/**
 * Class to test separated TotalCross wrappers.
 */
public class TestTotalcross {

  @Test
  public void totalCrossCurrentTimeMillis() {
    Assert.assertNotEquals(ch.fhnw.geiger.totalcross.System.currentTimeMillis(), 0);
  }

}
