import 'dart:collection';

import '../../StorageController.dart';
import '../../StorageException.dart';
import '../../Visibility.dart';
import '../GenericController.dart';
import 'Field.dart';
import 'Node.dart';
import 'NodeValue.dart';
import 'SwitchableBoolean.dart';

/// <p>The implementation of the node interface.</p>
///
/// <p>This Class denotes one node containing sub-nodes in a tree-like structure. Each node may have
/// n children. Each node may be a skeleton-only node (contains only name and a reference to a
/// mapper), or may be materialized (contains all data). Typically when fetching a node, the node
/// is materialized but its sub-nodes are skeleton-only nodes. All skeleton nodes materialize
/// automatically if their data is accessed.</p>
class NodeImpl with Node {
  static const int serialversionUID = 11239348938;

  /// an indicator whether the current object is a skeleton
  final SwitchableBoolean skeleton = SwitchableBoolean(false);

  /// Contains the mapper for a skeleton to fetch any subsequent  data
  StorageController? controller;

  /// contains the ordinals of a node
  final Map<Field, String> ordinals = HashMap();

  /// contains the key/value pairs of a node
  final Map<String, NodeValue> values = HashMap();

  /// Holds all child nodes as tuples, where the name is used as a key and
  /// the value is of type StorageNode
  final Map<String, Node> childNodes = HashMap();

  /// <p>Constructor creating a skeleton node.</p>
  ///
  /// @param path       the path of the node
  /// @param controller the controller to fetch the full node
  NodeImpl.createSkeleton(String path, StorageController? controller) {
    skeleton.set(true);
    try {
      set(Field.PATH, path);
    } on StorageException {
      throw Exception('Oops.... this should not happen... contact developer');
    }
    this.controller = controller;
  }

  NodeImpl.fromNode(Node node) {
    update(node);
  }

  /// <p>create a empty node for the given path.</p>
  ///
  /// @param path the node path
  /// @param isTombstone true if the node is a tombstone node
  /// @param visibility the visibility of the node or null if default
  /// @param nodeValues the node values to be stored or null if none
  /// @param childNodes the child nodes to be included or null if none
  factory NodeImpl.fromPath(String path,
      {bool? isTombstone,
      Visibility? visibility,
      List<NodeValue>? nodeValues,
      List<Node>? childNodes}) {
    var node = NodeImpl(getNameFromPath(path)!, getParentFromPath(path));
    try {
      if (isTombstone != null) {
        node.set(Field.TOMBSTONE, isTombstone ? 'true' : 'false');
      }
      if (visibility != null) {
        node.setVisibility(visibility);
      }
      if (nodeValues != null) {
        for (var nv in nodeValues) {
          node.addValue(nv);
        }
      }
      if (childNodes != null) {
        for (var n in childNodes) {
          node.addChildNode(n);
        }
      }
    } on StorageException {
      throw Exception('Oops.... this should not happen... contact developer');
    }
    return node;
  }

  /// <p>creates a fully fledged new empty node.</p>
  ///
  /// @param name   the name for the node
  /// @param parent the parent of the node (may be null if root node is the parent)
  /// @param vis    visibility of the node
  NodeImpl(String name, [String? parent, Visibility vis = Visibility.RED]) {
    if (parent == null) {
      parent = getParentFromPath(name);
      name = getNameFromPath(name) ?? '';
    }
    try {
      set(Field.PATH, '$parent${GenericController.PATH_DELIMITER}$name');
      set(Field.VISIBILITY, vis.toString());
    } on StorageException {
      throw Exception('Oops.... this should not happen... contact developer');
    }
    skeleton.set(false);
  }

  /// <p>Converts current node into a materialized node from a skeleton.</p>
  void init() {
    // synchronized(skeleton, {
    if (skeleton.get()) {
      update(controller!.get(getPath()));
      skeleton.set(false);
      controller = null;
    }
    // });
  }

  /// <p>Returns the name part from a fully qualified node path.</p>
  ///
  /// @param path the fully qualified path of which the name is extracted
  /// @return the name part of the path
  static String? getNameFromPath(String? path) {
    if (path == null) {
      return null;
    }
    return path
        .substring(path.lastIndexOf(GenericController.PATH_DELIMITER) + 1);
  }

  /// <p>Returns the fully qualified node path of the parental node.</p>
  ///
  /// @param path the fully qualified path of which the parental node is extracted
  /// @return the fully qualified path to the parental node
  static String? getParentFromPath(String? path) {
    if (path == null) {
      return null;
    }
    if (!path.contains(GenericController.PATH_DELIMITER)) {
      return '';
    }
    return path.substring(
        0, path.lastIndexOf(GenericController.PATH_DELIMITER));
  }

  @override
  NodeValue? getValue(String key) {
    init();
    // synchronized(values, {
    var ret = values[key];
    if (ret != null) {
      ret = ret.deepClone();
    }
    return ret;
    // });
  }

  @override
  NodeValue updateValue(NodeValue value) {
    init();
    var ret = getValue(value.getKey());
    if (ret == null) {
      throw StorageException(
          (('Value ' + value.getKey()) + ' not found in node ') + (getName()));
    }
    // synchronized(values, {
    values[value.getKey()] = value;
    // });

    return ret;
  }

  @override
  void addValue(NodeValue value) {
    init();
    if (getValue(value.getKey()) != null) {
      throw StorageException('value does already exist');
    }
    // synchronized(values, {
    values[value.getKey()] = value;
    // });
  }

  @override
  NodeValue? removeValue(String key) {
    init();
    // synchronized(values, {
    return values.remove(key);
    // });
  }

  @override
  void addChild(Node node) {
    init();
    // synchronized(childNodes, {
    if (!childNodes.containsKey(node.getName())) {
      childNodes[node.getName()] = node;
    }
    // });
  }

  @override
  String getOwner() {
    try {
      return get(Field.OWNER) ?? '';
    } on StorageException {
      throw Exception('Oops.... this should not happen... contact developer');
    }
  }

  @override
  String setOwner(String newOwner) {
    try {
      return set(Field.OWNER, newOwner) ?? '';
    } on StorageException {
      throw Exception('Oops.... this should not happen... contact developer');
    }
  }

  @override
  String getName() {
    try {
      return getNameFromPath(get(Field.PATH)) ?? '';
    } on StorageException {
      throw Exception('Oops.... this should not happen... contact developer');
    }
  }

  @override
  String getParentPath() {
    try {
      return getParentFromPath(get(Field.PATH)) ?? '';
    } on StorageException {
      throw Exception('Oops.... this should not happen... contact developer');
    }
  }

  @override
  String getPath() {
    try {
      return get(Field.PATH) ?? '';
    } on StorageException {
      throw Exception('Oops.... this should not happen... contact developer');
    }
  }

  @override
  Visibility getVisibility() {
    try {
      var rawVisibility = get(Field.VISIBILITY);
      return VisibilityExtension.valueOf(rawVisibility!) ?? Visibility.RED;
    } on StorageException {
      throw Exception('Oops.... this should not happen... contact developer');
    }
  }

  @override
  Visibility setVisibility(Visibility newVisibility) {
    try {
      var ret = getVisibility();
      set(Field.VISIBILITY, newVisibility.toString());
      return ret;
    } on StorageException {
      throw Exception('Oops.... this should not happen... contact developer');
    }
  }

  @override
  Map<String, NodeValue> getValues() {
    return HashMap.from(values);
  }

  /// <p>Gets an ordinal field of the node.</p>
  /// @param field the ordinal field to get
  /// @return the currently set value
  /// @throws StorageException if a field does not exist
  String? get(Field field) {
    // synchronized(skeleton, {
    if (((field != Field.PATH) && (field != Field.NAME)) &&
        (field != Field.TOMBSTONE)) {
      init();
    }
    // });

    switch (field) {
      case Field.OWNER:
      case Field.PATH:
      case Field.VISIBILITY:
      case Field.LAST_MODIFIED:
      case Field.EXPIRY:
      case Field.TOMBSTONE:
        return ordinals[field];
      case Field.NAME:
        return getNameFromPath(ordinals[Field.PATH]);
      default:
        throw StorageException('unable to fetch field ' + field.toString());
    }
  }

  /// <p>Sets an ordinal field of the node.</p>
  ///
  /// @param field the ordinal field to be set
  /// @param value the new value
  /// @return the previously set value
  /// @throws StorageException if a field does not exist
  String? set(Field field, String? value) {
    // synchronized(skeleton, {
    if (field != Field.PATH) {
      init();
    }
    // });

    var current = ordinals[field];

    if (field != Field.LAST_MODIFIED &&
        ((current != null && current != value) ||
            (current == null && value != null))) {
      touch();
    }
    switch (field) {
      case Field.OWNER:
      case Field.PATH:
      case Field.VISIBILITY:
      case Field.LAST_MODIFIED:
      case Field.EXPIRY:
        if (value == null) {
          return ordinals.remove(field);
        }
        var prev = ordinals[field];
        ordinals[field] = value;
        return prev;
      case Field.TOMBSTONE:
        var prev = ordinals[field] ?? 'false';
        ordinals[field] = ('true' == value) ? 'true' : 'false';
        return prev;
      default:
        throw StorageException('unable to set field ' + field.toString());
    }
  }

  /// <p>Checks if the current node is marked as TOMBSTONE (old deleted node).</p>
  /// @return true if node is a tombstone
  @override
  bool isTombstone() {
    try {
      return 'true' == get(Field.TOMBSTONE);
    } on StorageException {
      throw Exception('OOPS! Unexpected exception... please contact developer');
    }
  }

  void addChildNode(Node n) {
    childNodes[n.getName()] = n;
  }

  @override
  void removeChild(String name) {
    childNodes.remove(name);
  }

  @override
  Map<String, Node> getChildren() {
    init();
    // synchronized(childNodes, {
    Map<String, Node> ret = HashMap();
    for (var entry in childNodes.entries) {
      ret[entry.key] = entry.value.deepClone();
    }
    return ret;
    // });
  }

  @override
  Node? getChild(String name) {
    init();
    return childNodes[name];
  }

  @override
  String getChildNodesCsv() {
    init();
    if (childNodes.isEmpty) {
      return '';
    }
    var csv = '';
    for (var s in childNodes.keys) {
      csv += s + ',';
    }
    return csv.substring(0, csv.length - 1);
  }

  @override
  bool isSkeleton() {
    return skeleton.get();
  }

  @override
  StorageController? getController() {
    return controller;
  }

  @override
  StorageController? setController(StorageController controller) {
    var ret = this.controller;
    this.controller = controller;
    return ret;
  }

  @override
  bool operator ==(Object other) => equals(other);

  bool equals(Object? o) {
    if (o == null || !(o is NodeImpl)) {
      return false;
    }
    var n2 = o;
    if (!isSkeleton() || (isSkeleton() && (!n2.isSkeleton()))) {
      try {
        init();
        n2.init();
      } on StorageException {
        // I do not care if init fails....
      }
      if (ordinals.length != n2.ordinals.length) {
        return false;
      }
      for (var e in n2.ordinals.entries) {
        try {
          if (!(e.value == get(e.key))) {
            return false;
          }
        } on Exception {
          throw Exception(
              'Oops.... this should not happen... contact developer');
        }
      }
      if (values.length != n2.values.length) {
        return false;
      }
      for (var e in values.entries) {
        try {
          if (!(e.value.equals(n2.getValue(e.key)))) {
            return false;
          }
        } on StorageException {
          return false;
        }
      }
      if (childNodes.length != n2.childNodes.length) {
        return false;
      }
      for (var n in childNodes.keys) {
        if (n2.childNodes[n] == null) {
          return false;
        }
      }
    } else {
      if (!(getPath() == n2.getPath())) {
        return false;
      }
      if (controller != n2.getController()) {
        return false;
      }
    }
    return true;
  }

  @override
  void update(Node n2, {bool deepClone = true}) {
    controller = n2.getController();
    skeleton.set(n2.isSkeleton());
    var path = (n2 as NodeImpl).ordinals[Field.PATH];
    if (path != null) {
      ordinals[Field.PATH] = path;
    }
    if (!n2.isSkeleton()) {
      // synchronized(ordinals, {
      ordinals.clear();
      for (var e in n2.ordinals.entries) {
        ordinals[e.key] = e.value;
      }
      // });
      // synchronized(values, {
      values.clear();
      for (var e in n2.values.entries) {
        values[e.key] = e.value.deepClone();
      }
      //});

// synchronized(childNodes, {
      childNodes.clear();

      for (var e in n2.getChildren().entries) {
        if (deepClone) {
          childNodes[e.key] = e.value.deepClone();
        } else {
          childNodes[e.key] =
              NodeImpl.createSkeleton(e.value.getPath(), controller);
        }
      }
      // });
    }

    var lastModified = n2.ordinals[Field.LAST_MODIFIED];
    if (lastModified != null) {
      ordinals[Field.LAST_MODIFIED] = lastModified;
    }
  }

  @override
  Node deepClone() {
    return NodeImpl.fromNode(this);
  }

  @override
  Node shallowClone() {
    var ret = NodeImpl.fromPath(getPath());
    ret.update(this, deepClone: false);
    return ret;
  }

  void touch() {}

  @override
  String toString() {
    var sb = StringBuffer();
    sb.write(getPath());
    sb.write('[');
    if (isSkeleton()) {
      sb.write('{<skeletonized>}');
      sb.write(']{');
      sb.write('\n');
    } else {
      sb.write('owner=');
      sb.write(getOwner());
      sb.write(';vis=');
      sb.write(getVisibility());
      sb.write(']{');
      sb.write('\n');
    }
    var i = 0;
    if (isSkeleton()) {
      sb.write('{<skeletonized>}');
    } else {
      if (values != null) {
        for (var e in values.entries) {
          if (i > 0) {
            sb.write(', ');
            sb.write('\n');
          }
          sb.write(e.value.toString('  '));
          i++;
        }
        sb.write('\n');
        sb.write('}');
      } else {
        sb.write('{}');
      }
    }
    return sb.toString();
  }

/* void toByteArrayStream(Sink<List<int>> out) {
    SerializerHelper.writeLong(out, serialversionUID);
    SerializerHelper.writeInt(out, skeleton.get() ? 1 : 0);
    SerializerHelper.writeString(out, getPath());
    SerializerHelper.writeInt(out, ordinals.length - 1);
    // synchronized(ordinals, {
    for (MapEntry<Field, String> e in ordinals.entries) {
      if (e.key != Field.PATH) {
        SerializerHelper.writeString(out, e.getKey().toString());
        SerializerHelper.writeString(out, e.getValue());
      }
    }
    // });

    if

    (

    !

    isSkeleton
      ()

    ) {
      SerializerHelper.writeInt(out, values.length);
// synchronized(values, {
      for (MapEntry<String, NodeValue> e in values.entries) {
        SerializerHelper.writeString(out, e.getKey());
        e.getValue().toByteArrayStream(out);
      }
    }
    );

    SerializerHelper.writeInt

    (

    out

    ,

    childNodes.length

    );

// synchronized(childNodes, {
    for

    (

    MapEntry<String, Node> e

    in

    childNodes.entries

    ) {
    SerializerHelper.writeString(out, e.getKey());
    e.getValue().toByteArrayStream(out);
    }
  }

  );
}
SerializerHelper.writeLong(out, serialversionUID);
}

/// <p>Deserializes a NodeValue from a byteStream.</p>
/// @param in the stream to be read
/// @return the deserialized NodeValue
/// @throws IOException if an exception happens deserializing the stream
static NodeImpl fromByteArrayStream
(

Stream<List<int>> in_
) {
if (SerializerHelper.readLong(in_) != serialversionUID) {
throw java_io_IOException('failed to parse NodeImpl (bad stream?)');
}
var skel = (SerializerHelper.readInt(in_) == 1);
var n = NodeImpl(SerializerHelper.readString(in_));
if (skel) {
n.controller = GenericController.getDefault();
}
int counter = SerializerHelper.readInt(in_);
for (var i = 0; i < counter; i++) {
n.ordinals.put(Field.valueOf(SerializerHelper.readString(in_)),
SerializerHelper.readString(in_));
}
if (!skel) {
counter = SerializerHelper.readInt(in_);
for (var i = 0; i < counter; i++) {
n.values.put(SerializerHelper.readString(in_),
NodeValueImpl.fromByteArrayStream(in_));
}
counter = SerializerHelper.readInt(in_);
for (var i = 0; i < counter; i++) {
n.childNodes.put(SerializerHelper.readString(in_),
NodeImpl_.fromByteArrayStream(in_));
}
}
if (SerializerHelper.readLong(in_) != serialversionUID) {
throw java_io_IOException(
'failed to parse NodeImpl (bad stream end?)');
}
return n;
}*/

}
