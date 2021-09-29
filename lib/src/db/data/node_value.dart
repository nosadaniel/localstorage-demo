library geiger_localstorage;

import 'package:intl/locale.dart';

/// <p>Interface for accessing key/value pairs in nodes.</p>
///
/// <p>All values supporting locales must have at least an english [Locale.ENGLISH] locale.</p>
abstract class NodeValue /* with Serializer*/ {
  /// <p>Gets the key of the K/V tuple.</p>
  ///
  /// @return the string representation of the key
  String getKey();

  /// <p>Gets the string representation of the value in the default locale (Locale.ENGLISH).</p>
  ///
  /// @param languageRange the set of languages requested
  /// @return the string representation of the value
  String? getValue([String languageRange]);

  /// <p>Gets all translations of the value.</p>
  ///
  /// @return a Map containing all translations for the value and their locale
  Map<Locale, String> getAllValueTranslations();

  /// <p>Sets the string representation of the value.</p>
  ///
  /// @param value  the string representation of the value
  /// @param locale the locale to be fetched
  /// @throws MissingResourceException if the text for the default locale (ENGLISH) is missing
  void setValue(String value, [Locale locale]);

  /// <p>Gets the type of value.</p>
  ///
  /// @return the string representation of the type
  String? getType();

  /// <p>Sets the type of value.</p>
  /// @param type the string representation of the type to be set
  ///
  /// @return the string representation of the previously set type
  String? setType(String type);

  /// <p>Gets the description of the value.</p>
  ///
  /// <p>This description is used when asking for the users consent to share this data.</p>
  /// @param languageRange the set of languages requested
  /// @return the string of the currently set description
  String? getDescription([String languageRange]);

  /// <p>Gets all translations of the description of the value.</p>
  ///
  /// @return a Map containing all translations for the description and their locale
  Map<Locale, String> getAllDescriptionTranslations();

  /// <p>Sets the description of the value.</p>
  ///
  /// <p>This description is used when asking for the users consent to share this data.</p>
  /// @param description the description to be set
  /// @param locale      the locale to be written
  /// @return the string of the previously set description.
  /// @throws MissingResourceException if the default locale is missing
  String? setDescription(String description, [Locale locale]);

  /// <p>Gets the epoch of the last modification of the value.</p>
  ///
  /// @return a value reflecting the epoch of the last change
  int getLastModified();

  /// Copies the all values of the given node to the current node value.
  void update(NodeValue nodeValue);

  /// Creates a deep clone of the K/V tuple.
  NodeValue deepClone();

  /// prints a space prefixed representation of the NodeValue.
  ///
  /// @param prefix a prefix (typically a series of spaces
  /// @return the string representation
  @override
  String toString([String prefix]);

  /// Checks if two NodeValue are equivalent in values.
  bool equals(Object? object);
}