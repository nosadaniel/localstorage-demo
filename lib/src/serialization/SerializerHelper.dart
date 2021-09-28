library ch.fhnw.geiger.serialization;

/// <p>Helper class for serialization serializes important java primitives.</p>
class SerializerHelper
{
    static const int STRING_UID = 123798371293;
    static const int LONG_UID = 1221312393;
    static const int INT_UID = 122134568793;
    static const int STACKTRACES_UID = 9012350123956;
    static void writeIntLong(Sink<List<int>> out, int l)
    {
        List<int> result = new List<int>(Long_.BYTES);
        for (int i = (Long_.BYTES - 1); i >= 0; i--) {
            result[i] = (l & 15);
            l >>= Byte.SIZE;
        }
        out.write(result);
    }

    static Long readIntLong(Stream<List<int>> in_)
    {
        int size = Long_.BYTES;
        List<int> arr = new List<int>(size);
        in_.read(arr);
        int result = 0;
        for (int i = 0; i < size; i++) {
            result <<= Byte.SIZE;
            result |= (arr[i] & 15);
        }
        return result;
    }

    static void writeIntInt(Sink<List<int>> out, Integer l)
    {
        int size = Integer_.BYTES;
        List<int> result = new List<int>(size);
        for (int i = (size - 1); i >= 0; i--) {
            result[i] = (l & 15);
            l >>= Byte.SIZE;
        }
        out.write(result);
    }

    static Integer readIntInt(Stream<List<int>> in_)
    {
        int size = Integer_.BYTES;
        List<int> arr = new List<int>(size);
        in_.read(arr);
        int result = 0;
        for (int i = 0; i < size; i++) {
            result <<= Byte.SIZE;
            result |= (arr[i] & 15);
        }
        return result;
    }

    /// <p>Serialize a long variable.</p>
    /// @param out the stream to be read
    /// @param l   the value to be deserialized
    /// @throws IOException if an exception occurs while writing to the stream
    static void writeLong(Sink<List<int>> out, Long l)
    {
        writeIntLong(out, LONG_UID);
        writeIntLong(out, l);
    }

    /// <p>Deserialize a long variable.</p>
    /// @param in the stream to be read
    /// @return the deserialized long value
    /// @throws IOException if an exception occurs while writing to the stream
    static Long readLong(Stream<List<int>> in_)
    {
        if (readIntLong(in_) != LONG_UID) {
            throw new ClassCastException();
        }
        return readIntLong(in_);
    }

    /// <p>Serialize an int variable.</p>
    /// @param out the stream to be read
    /// @param i   the value to be deserialized
    /// @throws IOException if an exception occurs while writing to the stream
    static void writeInt(Sink<List<int>> out, Integer i)
    {
        writeIntLong(out, INT_UID);
        writeIntInt(out, i);
    }

    /// <p>Deserialize an int variable.</p>
    /// @param in the stream to be read
    /// @return the deserialized integer value
    /// @throws IOException if an exception occurs while writing to the stream
    static Integer readInt(Stream<List<int>> in_)
    {
        if (readIntLong(in_) != INT_UID) {
            throw new ClassCastException();
        }
        return readIntInt(in_);
    }

    /// <p>Serialize a string variable.</p>
    /// @param out the stream to be read
    /// @param s   the value to be deserialized
    /// @throws IOException if an exception occurs while writing to the stream
    static void writeString(Sink<List<int>> out, String s)
    {
        writeIntLong(out, STRING_UID);
        if (s == null) {
            writeIntInt(out, -1);
        } else {
            writeIntInt(out, s.length);
            out.write(s.getBytes(StandardCharsets.UTF_8));
        }
    }

    /// <p>Deserialize a string variable.</p>
    /// @param in the stream to be read
    /// @return the deserialized string
    /// @throws IOException if an exception occurs while writing to the stream
    static String readString(Stream<List<int>> in_)
    {
        if (readIntLong(in_) != STRING_UID) {
            throw new ClassCastException();
        }
        int length = readIntInt(in_);
        if (length == (-1)) {
            return null;
        } else {
            List<int> arr = new List<int>(length);
            in_.read(arr);
            return new String(arr, StandardCharsets.UTF_8);
        }
    }

    /// <p>Serialize an array of StackTraces.</p>
    /// @param out the stream to be read
    /// @param ste the value to be deserialized
    /// @throws IOException if an exception occurs while writing to the stream
    static void writeStackTraces(Sink<List<int>> out, List<StackTraceElement> ste)
    {
        writeIntLong(out, STACKTRACES_UID);
        if (ste == null) {
            writeIntInt(out, -1);
        } else {
            writeIntInt(out, ste.length);
            for (StackTraceElement st in ste) {
                writeString(out, st.getClassName());
                writeString(out, st.getMethodName());
                writeString(out, st.getFileName());
                writeInt(out, st.getLineNumber());
            }
        }
    }

    /// <p>Deserialize an array of StackTraceElement variable.</p>
    /// @param in the stream to be read
    /// @return the deserialized array
    /// @throws IOException if an exception occurs while writing to the stream
    static List<StackTraceElement> readStackTraces(Stream<List<int>> in_)
    {
        if (readIntLong(in_) != STACKTRACES_UID) {
            throw new ClassCastException();
        }
        int length = readIntInt(in_);
        if (length == (-1)) {
            return null;
        } else {
            List<StackTraceElement> arr = new List<StackTraceElement>(length);
            for (int i = 0; i < length; i++) {
                arr[i] = new StackTraceElement(readString(in_), readString(in_), readString(in_), readInt(in_));
            }
            return arr;
        }
    }

    /// Read an object from ByteArrayInputStream.
    /// @param in the byteArrayInputStream to use
    /// @return return the object read
    /// @throws IOException if object cannot be read
    static Object readObject(Stream<List<int>> in_)
    {
        switch (("" + readIntLong(in_))) {
            case ("" + STRING_UID):
                List<int> arr = new List<int>(readIntInt(in_));
                in_.read(arr);
                return new String(arr, StandardCharsets.UTF_8);
            case ("" + LONG_UID):
                return readIntLong(in_);
            default:
                throw new ClassCastException();
        }
    }

    /// Write an object to ByteArrayOutputStream.
    /// @param out the ByteArrayOutputStream to use
    /// @param o the Object to write
    /// @throws IOException if object cannot be written
    static void writeObject(Sink<List<int>> out, Object o)
    {
        switch (o.getClass().getName()) {
            case "String":
                writeString(out, o);
                break;
            case "Long":
                writeLong(out, o);
                break;
            case "Integer":
                writeInt(out, o);
                break;
            default:
                throw new ClassCastException();
        }
    }

}
