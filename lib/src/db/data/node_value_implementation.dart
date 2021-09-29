library geiger_localstorage;

import 'dart:collection';

import 'package:intl/locale.dart';

import 'language_range.dart';
import 'node_value.dart';

/// This abstract class defines the common attributes for all NodeValueObjects.
class NodeValueImpl with NodeValue {
  static const int serialversionUID = 871283188;
  static final Locale defaultLocale = Locale.fromSubtags(languageCode: 'en');

  /// They key is used to identify the NodeValueObject inside a StorageNode,
  /// therefore, the key is unique within one StorageNode.
  String key;
  final Map<String, String> value = HashMap();

  /// <p>The type of the value.</p>>
  String? type;

  /// Description of this value, can be used for translation.
  final Map<String, String> description = HashMap();

  /// Defines the epoch when this value was last modified.
  late int lastModified;

  /// <p>A fully fledged constructor for creating key/value pairs suitable for sharing.</p>
  ///
  /// @param key          the name of the key/value pair
  /// @param value        the value to be set
  /// @param type         a searchable type field
  /// @param description  the description to be shown when asking for consent of sharing
  /// @param lastModified the last modified date to be set
  NodeValueImpl(this.key, String value,
      [this.type, String? description, int? lastModified]) {
    setLocalizedString(this.value, value, defaultLocale);
    if (description != null) {
      setLocalizedString(this.description, description, defaultLocale);
    }
    this.lastModified = lastModified ?? 0;
  }

  @override
  String getKey() {
    return key;
  }

  void setKey(String key) {
    this.key = key;
    updateLastModified();
  }

  @override
  String? getValue([String? languageRange]) {
    return getLocalizedString(
        value, languageRange ?? defaultLocale.toLanguageTag());
  }

  @override
  Map<Locale, String> getAllValueTranslations() {
    Map<Locale, String> m = HashMap();
    for (var e in value.entries) {
      m[Locale.parse(e.key)] = e.value;
    }
    return m;
  }

  @override
  void setValue(String value, [Locale? locale]) {
    setLocalizedString(this.value, value, locale ?? defaultLocale);
    updateLastModified();
  }

  @override
  String? getType() {
    return type;
  }

  @override
  String? setType(String type) {
    var ret = this.type;
    this.type = type;
    updateLastModified();
    return ret;
  }

  @override
  String? getDescription([String? languageRange]) {
    return getLocalizedString(
        description, languageRange ?? defaultLocale.toLanguageTag());
  }

  @override
  Map<Locale, String> getAllDescriptionTranslations() {
    Map<Locale, String> m = HashMap();
    for (var e in description.entries) {
      m[Locale.parse(e.key)] = e.value;
    }
    return m;
  }

  static Locale lookupLocale(Map<String, String> map, String languageRange) {
    if (map.isEmpty) {
      return defaultLocale;
    }

    // Get Language Range
    var lr = LanguageRange.parse(languageRange);

    // extending range list with locale only
    return Locale.parse(lr.getBestLanguage(map));
  }

  static String? getLocalizedString
      (Map<String, String> map,
      String
      languageRange) {
    return map[lookupLocale(map, languageRange).toLanguageTag()];
  }

  static void setLocalizedString
      (Map<String, String> map, String
  value,

      Locale locale) {
    if ((getLocalizedString(map, defaultLocale.toLanguageTag()) == null) &&
        (!(locale.toLanguageTag() == defaultLocale.toLanguageTag()))) {
      throw Exception('undefined string for locale ' +
          defaultLocale.toString() +
          ' Locale ' +
          locale.toLanguageTag());
    }
    map[locale.toLanguageTag()] = value;
  }

  @override
  String? setDescription(String description, [Locale? locale]) {
    locale ??= defaultLocale;
    var ret = getLocalizedString(this.description, locale.toLanguageTag());
    setLocalizedString(this.description, description, locale);
    updateLastModified();
    return ret;
  }

  @override
  int getLastModified() {
    return lastModified;
  }

  @override
  void update(NodeValue nodeValue) {
    NodeValueImpl n2 = nodeValue as NodeValueImpl;
    key = n2.getKey();
    value.clear();
    for (var e in n2.value.entries) {
      value[e.key] = e.value;
    }
    type = n2.getType();
    description.clear();
    for (var e in n2.description.entries) {
      description[e.key] = e.value;
    }
    updateLastModified();
  }

  void updateLastModified() {
    lastModified = DateTime
        .now()
        .millisecondsSinceEpoch;
  }

  @override
  NodeValue deepClone() {
    NodeValue ret = NodeValueImpl(getKey(), getValue()!);
    ret.update(this);
    return ret;
  }

  /// <p>prints a space prefixed representation of the NodeValue.</p>
  ///
  /// @param prefix a prefix (typically a series of spaces
  /// @return the string representation
  @override
  String toString([String prefix = '']) {
    var sb = StringBuffer();
    sb.write(prefix);
    sb.write(getKey());
    if (getType() != null) {
      sb.write(':');
      sb.write(getType());
    }
    sb.write('={');
    if (value.length == 1) {
      sb.write(defaultLocale.toLanguageTag());
      sb.write('=>"');
      sb.write(value[defaultLocale.toLanguageTag()]);
      sb.write('"}');
    } else {
      sb.write('\n');
      var i = 0;
      List<String> keyList = List.from(value.keys);
      keyList.sort();
      for (String l in keyList) {
        if (i > 0) {
          sb.write(',');
          sb.write('\n');
        }
        sb.write(prefix);
        sb.write('  ');
        sb.write(Locale.parse(l).toLanguageTag());
        sb.write('=>"');
        sb.write(value[l]);
        sb.write('"');
        i++;
      }
      sb.write('\n');
      sb.write(prefix);
      sb.write('}');
    }
    return sb.toString();
  }

  @override
  bool operator
  ==
      (Object other) =>

      equals(other);

  @override
  bool equals(Object? object) {
    if (object == null || object is! NodeValueImpl) {
      return false;
    }
    return toString() == object.toString();
  }

  @override
  int get hashCode => toString().hashCode;


/*void toByteArrayStream(Sink<List<int>> out) {
    SerializerHelper.writeLong(out, serialversionUID);
    SerializerHelper.writeString(out, key);
    SerializerHelper.writeInt(out, value.length);
    synchronized(value, {
    for (MapEntry<String, String> e in value.entries) {
    SerializerHelper.writeString(out, e.key);
    SerializerHelper.writeString(out, e.value);
    }
    });
    SerializerHelper.writeString(out, type);
    SerializerHelper.writeLong(out, lastModified);
    SerializerHelper.writeInt(out, description.length);
    synchronized(description, {
    for (MapEntry<String, String> e in description.entries) {
    SerializerHelper.writeString(out, e.key);
    SerializerHelper.writeString(out, e.value);
    }
    });
    SerializerHelper.writeLong(out, serialversionUID);
  }

  /// <p>Deserializes a NodeValue from a byteStream.</p>
  /// @param in the stream to be read
  /// @return the deserialized NodeValue
  /// @throws IOException if an exception happens deserializing the stream
  static NodeValueImpl fromByteArrayStream(Stream<List<int>> in_) {
    if (SerializerHelper.readLong(in_) != serialversionUID) {
      throw java_io_IOException(
          'failed to parse NodeValueImpl (bad stream?)');
    }
    var nv = NodeValueImpl(SerializerHelper.readString(in_), '');
    int counter = SerializerHelper.readInt(in_);
    nv.value.clear();
    for (var i = 0; i < counter; i++) {
      nv.value.put(Locale.forLanguageTag(SerializerHelper.readString(in_))
          .toLanguageTag(), SerializerHelper.readString(in_));
    }
    nv.type = SerializerHelper.readString(in_);
    nv.lastModified = SerializerHelper.readLong(in_);
    counter = SerializerHelper.readInt(in_);
    for (var i = 0; i < counter; i++) {
      nv.description.put(Locale.forLanguageTag(SerializerHelper.readString(in_))
          .toLanguageTag(), SerializerHelper.readString(in_));
    }
    if (SerializerHelper.readLong(in_) != serialversionUID) {
      throw java_io_IOException(
          'failed to parse NodeValueImpl (bad stream end?)');
    }
    return nv;
  }*/

}
