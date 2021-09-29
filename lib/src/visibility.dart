library geiger_localstorage;

/// Defines the constants used in the traffic light protocol (TLP).
///
/// Each constants is a visibility option that needs to be set on a storage object.
enum Visibility {
  /// For all private values not to be shared with anyone!
  black,

  /// For all private values not to be shared with anyone except the devices
  /// assigned with the same user/enterprise.</p>
  red,

  /// <p>for all values to be shared with a specific party (e.g., CERT) only.</p>
  amber,

  /// <p>for all values to be shared with the cloud for analysis an consolidation.</p>
  green,

  /// <p>for all values to be shared with all entities of the cloud.</p>
  white
}

extension VisibilityExtension on Visibility {
  String toValueString() => toString().split('.').last;

  static Visibility? valueOf(String value) {
    try {
      return Visibility.values.firstWhere((e) => e.toValueString() == value);
    } on StateError {
      return null;
    }
  }
}
