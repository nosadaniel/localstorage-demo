library geiger_localstorage;

import 'dart:async';

/// <p>Serializer interface for the serialization of value related objects.</p>
abstract class serializer {
  /// Dummy static serializer.
  ///
  /// Creates the object from a stream of bytes in [inputStream].
  static serializer fromByteArrayStream(Stream<List<int>> inputStream) {
    throw Exception('not overrriden "fromByteArrayStream"');
  };

  /// Writes the current object to the output stream.
  ///
  /// writes a representation of the current object into [sink].
  void toByteArrayStream(Sink<List<int>> sink);

  /// Convenience class to serialize to a List.
  ///
  /// serialize the object to [obj] to a list.
  /// @return byteArray representing the object
  static List<int> toByteArray(serializer obj) {
    StreamController<List<int>> sc = StreamController();
    obj.toByteArrayStream(sc.sink);
    List<int> l = [];
    sc.stream.listen((listOfInt) {
      l.addAll(listOfInt);
    });

    return l;
  }

  /// Convenience Class to deserialize using list of bytes.
  ///
  /// gets bytes from [buf] and deserialize its content.
  static serializer fromByteArray(List<int> buf) {
    StreamController<List<int>> sc = StreamController();
    sc.sink.add(buf);
    return fromByteArrayStream(sc.stream);
  }

}
