library geiger_localstorage;

import 'package:geiger_localstorage/geiger_localstorage.dart';

/// <p>Field reflects the available ordinals in a node.</p>
class Field {
  static const Field owner = Field._(1, ComparatorType.string);
  static const Field name = Field._(2, ComparatorType.string);
  static const Field path = Field._(3, ComparatorType.string);
  static const Field key = Field._(4, ComparatorType.string);
  static const Field value = Field._(5, ComparatorType.string);
  static const Field type = Field._(6, ComparatorType.string);
  static const Field visibility = Field._(7, ComparatorType.string);
  static const Field lastModified = Field._(8, ComparatorType.datetime);
  static const Field expiry = Field._(9, ComparatorType.datetime);
  static const Field tombstone = Field._(10, ComparatorType.boolean);

  final ComparatorType _comparator;

  ComparatorType get comparator => _comparator;

  final int _id;

  int get id => _id;

  const Field._(this._id, this._comparator);
}
