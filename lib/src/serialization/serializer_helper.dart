library geiger_localstorage;

/// <p>Helper class for serialization serializes important java primitives.</p>
class SerializerHelper
{
    static const int STRING_UID = 123798371293;
    static const int LONG_UID = 1221312393;
    static const int INT_UID = 122134568793;
    static const int STACKTRACES_UID = 9012350123956;

    static const int INT_SIZE = 4;
    static const int BYTE_SIZE = 1;

    static void _writeIntLong(Sink<List<int>> out, int l)
    {
        List<int> result = new List<int>.empty(growable: true);
        for (int i = (INT_SIZE - 1); i >= 0; i--) {
            result[i] = (l & 15);
            l >>= BYTE_SIZE;
        }
        out.add(result);
    }

    static int _readIntLong(Stream<List<int>> in_)
    {
        int size = INT_SIZE;
        Future<List> f_arr = in_.toList();
        List arr = await f_arr;
        int result = 0;
        for (int i = 0; i < size; i++) {
            result <<= BYTE_SIZE;
            result |= (arr[i] & 15);
        }
        return result;
    }

    static void _writeIntInt(Sink<List<int>> out, int l)
    {
        int size = INT_SIZE;
        List<int> result = new List<int>.empty(growable: true);
        for (int i = (size - 1); i >= 0; i--) {
            result[i] = (l & 15);
            l >>= BYTE_SIZE;
        }
        out.add(result);
    }

    static int readIntInt(Stream<List<int>> in_)
    {
        int size = INT_SIZE;
        Future List<int> arr = in_.toList();
        int result = 0;
        for (int i = 0; i < size; i++) {
            result <<= BYTE_SIZE;
            result |= (arr[i] & 15);
        }
        return result;
    }

    /// <p>Serialize a long variable.</p>
    /// @param out the stream to be read
    /// @param l   the value to be deserialized
    /// @throws IOException if an exception occurs while writing to the stream
    static void writeLong(Sink<List<int>> out, int l)
    {
        _writeIntLong(out, LONG_UID);
        _writeIntLong(out, l);
    }

    /// <p>Deserialize a long variable.</p>
    /// @param in the stream to be read
    /// @return the deserialized long value
    /// @throws IOException if an exception occurs while writing to the stream
    static int readLong(Stream<List<int>> in_)
    {
        if (_readIntLong(in_) != LONG_UID) {
            throw new Exception("Cannot cast");
        }
        return _readIntLong(in_);
    }

    /// <p>Serialize an int variable.</p>
    /// @param out the stream to be read
    /// @param i   the value to be deserialized
    /// @throws IOException if an exception occurs while writing to the stream
    static void writeInt(Sink<List<int>> out, int i)
    {
        _writeIntLong(out, INT_UID);
        _writeIntInt(out, i);
    }

    /// <p>Deserialize an int variable.</p>
    /// @param in the stream to be read
    /// @return the deserialized integer value
    /// @throws IOException if an exception occurs while writing to the stream
    static int readInt(Stream<List<int>> in_)
    {
        if (readIntLong(in_) != INT_UID) {
            throw new Exception("Cannot cast");
        }
        return readIntInt(in_);
    }

    /// <p>Serialize a string variable.</p>
    /// @param out the stream to be read
    /// @param s   the value to be deserialized
    /// @throws IOException if an exception occurs while writing to the stream
    static void writeString(Sink<List<int>> out, String s)
    {
        _writeIntLong(out, STRING_UID);
        if (s == null) {
            _writeIntInt(out, -1);
        } else {
            _writeIntInt(out, s.length);
            out.add(utf8.encode(s));
        }
    }

    /// <p>Deserialize a string variable.</p>
    /// @param in the stream to be read
    /// @return the deserialized string
    /// @throws IOException if an exception occurs while writing to the stream
    static String? readString(Stream<List<int>> in_)
    {
        if (_readIntLong(in_) != STRING_UID) {
            throw new Exception("Cannot cast");
        }
        int length = readIntInt(in_);
        if (length == (-1)) {
            return null;
        } else {
            List<int> arr = new List<int>(length);
            in_.read(arr);
            return utf8.encode(arr);
        }
    }

    /// <p>Serialize an array of StackTraces.</p>
    /// @param out the stream to be read
    /// @param ste the value to be deserialized
    /// @throws IOException if an exception occurs while writing to the stream
    static void writeStackTraces(Sink<List<int>> out, List<StackTrace> ste)
    {
        _writeIntLong(out, STACKTRACES_UID);
        if (ste == null) {
            _writeIntInt(out, -1);
        } else {
            _writeIntInt(out, ste.length);
            for (StackTrace st in ste) {
                writeString(out, st.toString());
            }
        }
    }

    /// <p>Deserialize an array of StackTraceElement variable.</p>
    /// @param in the stream to be read
    /// @return the deserialized array
    /// @throws IOException if an exception occurs while writing to the stream
    static List<StackTrace> readStackTraces(Stream<List<int>> in_)
    {
        if (readIntLong(in_) != STACKTRACES_UID) {
            throw new Exception("Cannot cast");
        }
        int length = readIntInt(in_);
        if (length == (-1)) {
            return null;
        } else {
            List arr = [];
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
                return utf8.encode(arr);
            case ("" + LONG_UID):
                return readIntLong(in_);
            default:
                throw new Exception("Cannot cast");
        }
    }

    /// Write an object to ByteArrayOutputStream.
    /// @param out the ByteArrayOutputStream to use
    /// @param o the Object to write
    /// @throws IOException if object cannot be written
    static void writeObject(Sink<List<int>> out, Object o)
    {
        switch (o.runtimeType) {
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
                throw new Exception("Cannot cast");
        }
    }

}
