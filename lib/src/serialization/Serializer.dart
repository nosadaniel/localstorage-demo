library ch.fhnw.geiger.serialization;

/// <p>Serializer interface for the serialization of value related objects.</p>
abstract class Serializer
{
    /// <p>Dummy static serializer.</p>
    /// <p>Must be overridden by the respective implementing class.</p>
    /// @param in The input byte stream to be used
    /// @return the object parsed from the input stream by the respective class
    /// @throws IOException if not overridden or reached unexpectedly the end of stream
    static Serializer fromByteArrayStream(Stream<List<int>> in_)
    {
        throw new UnimplementedError("Not implemented... ");
    }

    /// <p>Writes the current object to the output stream.</p>
    /// @param out the output stream receiving the object
    /// @throws IOException if  an exception occurs while writing to the stream
    void toByteArrayStream(Sink<List<int>> out);

    /// Convenience class to serialize to a bytearray.
    /// @param obj the object to serialize
    /// @return byteArray representing the object
    static List<int> toByteArray(Serializer obj)
    {
        try {
            Sink<List<int>> out = new Sink<List<int>>();
            obj.toByteArrayStream(out);
            return out.toByteArray();
        } on UnimplementedError catch (ioe) {
            return null;
        }
    }

    /// Convenience Class to deserialize using byte array.
    /// @param buf the byte array to deserialize
    /// @return Serializer
    static Serializer fromByteArray(List<int> buf)
    {
        try {
            Stream<List<int>> in_ = new Stream<List<int>>(buf);
            return fromByteArrayStream(in_);
        } on UnimplementedError catch (ioe) {
            ioe.printStackTrace();
            return null;
        }
    }

}
