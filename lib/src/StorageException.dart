import 'dart:io';

/// <p>Exception to be raised on any problems related to the local storage.</p>
class StorageException with /*Serializer,*/ IOException {
  /// private static class SerializedException extends Throwable implements Serializer {
  /// private static final long serialversionUID = 721364991234L;
  /// private final String exceptionName;
  /// private final String message;
  /// public SerializedException(Throwable t) {
  /// super(t.getCause());
  /// this.message = t.getMessage();
  /// this.exceptionName = t.getClass().getName();
  /// setStackTrace(t.getStackTrace());
  /// }
  /// public SerializedException(String exceptionName, String message, StackTraceElement[] stacktrace,
  /// Throwable cause) {
  /// super(message, cause);
  /// this.exceptionName = exceptionName;
  /// this.message = message;
  /// setStackTrace(stacktrace);
  /// }
  /// public void toByteArrayStream(ByteArrayOutputStream out) throws IOException {
  /// SerializerHelper.writeLong(out, serialversionUID);
  /// SerializerHelper.writeString(out, exceptionName);
  /// SerializerHelper.writeString(out, message);
  /// SerializerHelper.writeStackTraces(out, getStackTrace());
  /// if (getCause() != null) {
  /// SerializerHelper.writeInt(out, 1);
  /// if (getCause() instanceof SerializedException) {
  /// ((SerializedException) (getCause())).toByteArrayStream(out);
  /// } else {
  /// new SerializedException(getCause()).toByteArrayStream(out);
  /// }
  /// } else {
  /// SerializerHelper.writeInt(out, 0);
  /// }
  /// SerializerHelper.writeLong(out, serialversionUID);
  /// }
  /// public static SerializedException fromByteArrayStream(ByteArrayInputStream in)
  /// throws IOException {
  /// if (SerializerHelper.readLong(in) != serialversionUID) {
  /// throw new IOException("failed to parse StorageException (bad stream?)");
  /// }
  /// //
  /// read exception text
  /// String name = SerializerHelper.readString(in);
  /// //
  /// read exception message
  /// String message = SerializerHelper.readString(in);
  /// //
  /// read stack trace
  /// StackTraceElement[] ste = SerializerHelper.readStackTraces(in);
  /// //
  /// read cause (if any)
  /// SerializedException cause = null;
  /// if (SerializerHelper.readInt(in) == 1) {
  /// cause = SerializedException.fromByteArrayStream(in);
  /// }
  /// //
  /// read object end tag (identifier)
  /// if (SerializerHelper.readLong(in) != serialversionUID) {
  /// throw new IOException("failed to parse NodeImpl (bad stream end?)");
  /// }
  /// return new SerializedException(name, message, ste, cause);
  /// }
  /// }
  static const int serialversionUID = 178324938;

  final String _message;
  final Exception? _cause;
  final StackTrace? _stackTrace;

  /// <p>Creates a StorageException with message and root cause.</p>
  ///
  /// @param txt the message
  /// @param e the root cause
  StorageException(this._message, [this._cause, this._stackTrace]);

/* void toByteArrayStream(java_io_ByteArrayOutputStream out)
  {
    SerializerHelper.writeLong(out, serialversionUID);
    SerializerHelper.writeString(out, getMessage());
    SerializerHelper.writeStackTraces(out, getStackTrace());
    SerializedException cause = null;
    if (getCause() == null) {
    } else {
      if (getCause() is SerializedException_) {
        cause = getCause();
      } else {
        cause = new SerializedException(getCause());
      }
    }
    if (cause != null) {
      SerializerHelper.writeInt(out, 1);
      cause.toByteArrayStream(out);
    } else {
      SerializerHelper.writeInt(out, 0);
    }
    SerializerHelper.writeLong(out, serialversionUID);
  }

  /// <p>Static deserializer.</p>
  /// <p>Creates a storage exception from the stream.</p>
  ///
  /// @param in The input byte stream to be used
  /// @return the object parsed from the input stream by the respective class
  /// @throws IOException if not overridden or reached unexpectedly the end of stream
  static StorageException fromByteArrayStream(java_io_ByteArrayInputStream in_)
  {
    if (SerializerHelper.readLong(in_) != serialversionUID) {
      throw new IOException("failed to parse StorageException (bad stream?)");
    }
    String txt = SerializerHelper.readString(in_);
    List<StackTraceElement> ste = SerializerHelper.readStackTraces(in_);
    Throwable t = null;
    if (SerializerHelper.readInt(in_) == 1) {
      t = SerializedException_.fromByteArrayStream(in_);
    }
    if (SerializerHelper.readLong(in_) != serialversionUID) {
      throw new IOException("failed to parse NodeImpl (bad stream end?)");
    }
    return new StorageException(txt, t, ste);
  }*/

}
