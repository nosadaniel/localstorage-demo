import 'dart:core';

import '../../../geiger_localstorage.dart';

/// <p>Field reflects the available ordinals in a node.</p>
class Field {
  static const Field OWNER = Field._(1, ComparatorType.STRING);
  static const Field NAME = Field._(2, ComparatorType.STRING);
  static const Field PATH = Field._(3, ComparatorType.STRING);
  static const Field KEY = Field._(4, ComparatorType.STRING);
  static const Field VALUE = Field._(5, ComparatorType.STRING);
  static const Field TYPE = Field._(6, ComparatorType.STRING);
  static const Field VISIBILITY = Field._(7, ComparatorType.STRING);
  static const Field LAST_MODIFIED = Field._(8, ComparatorType.DATETIME);
  static const Field EXPIRY = Field._(9, ComparatorType.DATETIME);
  static const Field TOMBSTONE = Field._(10, ComparatorType.BOOLEAN);

  final ComparatorType _comparator;

  ComparatorType get comparator => _comparator;

  final int _id;

  int get id => _id;

  const Field._(this._id, this._comparator);
}
