package ch.fhnw.geiger.totalcross;

import ch.fhnw.geiger.totalcross.Random;

/**
 * A UUID implementation to work with TotalCross.
 */
@SuppressWarnings("checkstyle:abbreviationaswordinname")
public class UUID {

  private static final Random r = new Random();
  private final byte[] uuid = new byte[Long.BYTES * 2];

  /**
   * Constructor to create a UUID.
   *
   * @param mostSigBits Most significant bits
   * @param leastSigBits least significant bits
   */
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

  @SuppressWarnings("checkstyle:AbbreviationAsWordInName")
  public static UUID randomUUID() {
    int i1= r.nextInt();
    int i2= r.nextInt();
    int i3 = r.nextInt();
    int i4 = r.nextInt();
    long l1= ((((long)i1 & 0xffffffff) << 32) |
        (((long)i2 & 0xffffffff)      ));
    long l2= ((((long)i3 & 0xffffffff) << 32) |
        (((long)i4 & 0xffffffff)      ));
    return new UUID(l1,l2);
  }

  /**
   * Create a string representation of a UUID.
   *
   * @return String representation
   */
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

  /**
   * Create random Hex String.
   *
   * @param size size of the resulting hex string
   * @return hex String
   */
  public static String randomHexString(int size) {
    StringBuilder sb = new StringBuilder();
    while (sb.length() < size) {
      sb.append(Integer.toHexString(r.nextInt()));
    }

    return sb.substring(0, size);
  }
}
