library geiger_localstorage;

import 'package:geiger_localstorage/geiger_localstorage.dart';

/// <p>Defines the type of comparator to be used when accessing an ordinal.</p>
enum ComparatorType { string, datetime, boolean }

/// <p>An object that can hold all possible search criteria.</p>
///
/// <p>Each criteria can either be set or left blank the search will match all
/// nonempty criteria.
/// </p>
class SearchCriteria with /*Serializer,*/ Comparable<SearchCriteria> {
  static const int serialversionUID = 87128319541;

  /// <p>Create a [SearchCriteria].</p>
  ///
  /// @param path the path to search for
  /// @param key the key to search for
  /// @param value the value to search for
  SearchCriteria([String? path, String? key, String? value]) {
    if (path == null || key == null) {
      return;
    }
    setNodePath(path);
    setNodeValueKey(key);
    if (value != null && value != '%') {
      setNodeValueValue(value);
    }
  }

  final Map<Field, String> values = {};

  String? getNodeOwner() {
    return values[Field.owner];
  }

  String setNodeOwner(String nodeOwner) {
    return values[Field.owner] = nodeOwner;
  }

  String? getNodeName() {
    return values[Field.name];
  }

  String setNodeName(String nodeName) {
    return values[Field.name] = nodeName;
  }

  String? getNodePath() {
    return values[Field.path];
  }

  String setNodePath(String nodePath) {
    return values[Field.path] = nodePath;
  }

  String? getNodeValueKey() {
    return values[Field.key];
  }

  String setNodeValueKey(String nodeValueKey) {
    return values[Field.key] = nodeValueKey;
  }

  String? getNodeValueValue() {
    return values[Field.value];
  }

  String setNodeValueValue(String nodeValue) {
    return values[Field.owner] = nodeValue;
  }

  String? getNodeValueType() {
    return values[Field.type];
  }

  String setNodeValueType(String nodeValueType) {
    return values[Field.owner] = nodeValueType;
  }

  String? get(Field f) {
    return values[f];
  }

  String set(Field f, String value) {
    return values[f] = value;
  }

  String? getNodeValueLastModified() {
    return values[Field.lastModified];
  }

  String setNodeValueLastModified(String nodeValueLastModified) {
    return values[Field.lastModified] = nodeValueLastModified;
  }

  /// <p>Evaluates a provided node against this criteria.</p>
  ///
  /// @param node the node to be evaluated
  /// @return true iif the node matches the criteria
  /// @throws StorageException if the storage backend encounters a problem
  bool evaluate(Node node) {
    var path = getNodePath();
    if (path == null || !node.getPath()!.startsWith(path)) {
      return false;
    }
    var owner = values[Field.owner];
    if ((owner != null) && (!regexEvalString(owner, node.getOwner()!))) {
      return false;
    }
    var visibility = values[Field.visibility];
    if ((visibility != null) &&
        (!regexEvalString(visibility, node.getVisibility().toString()))) {
      return false;
    }
    var nodeValues = node.getValues();
    if ((values[Field.key] == null) &&
        ((values[Field.value] != null) || (values[Field.type] != null))) {
      for (var e in nodeValues.entries) {
        var type = values[Field.type];
        var r3 = type == null || !regexEvalString(type, e.value.getType()!);
        var value = values[Field.value];
        var r2 = value == null || !regexEvalString(value, e.value.getValue()!);
        if (r2 && r3) {
          return true;
        }
      }
      return false;
    } else {
      if (values[Field.key] != null) {
        var nv = nodeValues[get(Field.key)]!;
        if (!regexEvalString(values[Field.type]!, nv.getType()!)) {
          return false;
        }
        if (!regexEvalString(values[Field.value]!, nv.getValue()!)) {
          return false;
        }
      }
    }
    return true;
  }

  bool regexEvalString(String regex, String value) {
    return RegExp(regex).hasMatch(value);
  }

  /*void toByteArrayStream(java_io_ByteArrayOutputStream out) {
    SerializerHelper.writeLong(out, serialversionUID);
    SerializerHelper.writeInt(out, values.size());
    for (MapEntry<Field, String> e in values.entrySet()) {
      SerializerHelper.writeString(out, e.getKey().name());
      SerializerHelper.writeString(out, e.getValue());
    }
    SerializerHelper.writeLong(out, serialversionUID);
  }

  /// <p>Static deserializer.</p>
  ///
  /// <p>creates  a search criteria from a ByteArrayStream</p>
  /// @param in The input byte stream to be used
  /// @return the object parsed from the input stream by the respective class
  /// @throws IOException if not overridden or reached unexpectedly the end of stream
  static SearchCriteria fromByteArrayStream(java_io_ByteArrayInputStream in_) {
    if (SerializerHelper.readLong(in_) != serialversionUID) {
      throw new java_io_IOException(
          'failed to parse StorageException (bad stream?)');
    }
    SearchCriteria s = new SearchCriteria();
    int size = SerializerHelper.readInt(in_);
    for (int i = 0; i < size; i++) {
      s.values.put(Field.valueOf(SerializerHelper.readString(in_)),
          SerializerHelper.readString(in_));
    }
    if (SerializerHelper.readLong(in_) != serialversionUID) {
      throw new java_io_IOException(
          'failed to parse StorageException (bad stream end?)');
    }
    return s;
  }

  String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append('{').append(System.lineSeparator());
    java_util_Set<String> tmp = new java_util_TreeSet();
    for (Field f in values.keySet()) {
      tmp.add(f.toString());
    }
    for (String f in new java_util_TreeSet(tmp)) {
      sb
          .append('  ')
          .append(f)
          .append('='.codeUnitAt(0))
          .append(values.get(Field.valueOf(f)))
          .append(System.lineSeparator());
      sb.append('}').append(System.lineSeparator());
      return sb.toString();
    }
  }

  /// <p>Wrapper function to simplify serialization.</p>
  /// @return the serializer object as byte array
  List<int> toByteArray() {
    try {
      java_io_ByteArrayOutputStream out = new java_io_ByteArrayOutputStream();
      toByteArrayStream(out);
      return out.toByteArray();
    } on java_io_IOException catch (e) {
      return null;
    }
  }

  /// <p>Wrapper function to simplify deserialization.</p>
  /// @param buf the buffer to be read
  /// @return the deserialized object
  static SearchCriteria fromByteArray(List<int> buf) {
    return fromByteArrayInt(buf);
  }

  static ch_fhnw_geiger_serialization_Serializer fromByteArrayInt(
      List<int> buf) {
    try {
      java_io_ByteArrayInputStream in_ = new java_io_ByteArrayInputStream(buf);
      return fromByteArrayStream(in_);
    } on java_io_IOException catch (ioe) {
      ioe.printStackTrace();
      return null;
    }
  }*/

  @override
  int compareTo(SearchCriteria object) {
    return toString().compareTo(object.toString());
  }

  bool equals(Object o) {
    if (o is! SearchCriteria) {
      return false;
    }
    return toString() == o.toString();
  }
}
