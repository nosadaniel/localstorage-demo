package ch.fhnw.geiger.totalcross;

import java.util.Random;

public class UUID {

  private static Random r = new Random();
  private byte[] uuid = new byte[Long.BYTES * 2];

  public UUID(long mostSigBits, long leastSigBits) {
    for (int i = Long.BYTES - 1; i >= 0; i--) {
      uuid[i] = (byte) (mostSigBits & 0xFF);
      mostSigBits >>= Byte.SIZE;
    }
    for (int i = Long.BYTES - 1; i >= 0; i--) {
      uuid[i + Long.BYTES] = (byte) (leastSigBits & 0xFF);
      leastSigBits >>= Byte.SIZE;
    }
  }

  public static UUID randomUUID() {
    return new UUID(r.nextLong(), r.nextLong());
  }

  public String toString() {
    return byteToHex(uuid[0]) + byteToHex(uuid[1]) + byteToHex(uuid[2]) + byteToHex(uuid[3]) + "-"
        + byteToHex(uuid[4]) + byteToHex(uuid[5]) + "-"
        + byteToHex(uuid[6]) + byteToHex(uuid[7]) + "-"
        + byteToHex(uuid[8]) + byteToHex(uuid[9]) + "-"
        + byteToHex(uuid[10]) + byteToHex(uuid[11]) + byteToHex(uuid[12]) + byteToHex(uuid[13])
        + byteToHex(uuid[14]) + byteToHex(uuid[15]);
  }

  public static String byteToHex(byte b) {
    return Integer.toHexString(b & 0xFF);
  }

  public static String randomHexString(int size) {
    StringBuffer sb = new StringBuffer();
    while (sb.length() < size) {
      sb.append(Integer.toHexString(r.nextInt()));
    }

    return sb.toString().substring(0, size);
  }
}
