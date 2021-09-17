import 'dart:core';

import 'package:localstorage/src/SearchCriteria.dart';

/// <p>Field reflects the available ordinals in a node.</p>
class Field {
  static Field OWNER = Field._(1, ComparatorType.STRING);
  static Field NAME = Field._(2, ComparatorType.STRING);
  static Field PATH = Field._(3, ComparatorType.STRING);
  static Field KEY = Field._(4, ComparatorType.STRING);
  static Field VALUE = Field._(5, ComparatorType.STRING);
  static Field TYPE = Field._(6, ComparatorType.STRING);
  static Field VISIBILITY = Field._(7, ComparatorType.STRING);
  static Field LAST_MODIFIED = Field._(8, ComparatorType.DATETIME);
  static Field EXPIRY = Field._(9, ComparatorType.DATETIME);
  static Field TOMBSTONE = Field._(10, ComparatorType.BOOLEAN);

  final ComparatorType _comparator;

  ComparatorType get comparator => _comparator;

  final int _id;

  int get id => _id;

  Field._(this._id, this._comparator);
}
