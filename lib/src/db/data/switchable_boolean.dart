library geiger_localstorage;

/// A boolean valuable offering atomic toggling.
class SwitchableBoolean {
  bool value;

  SwitchableBoolean(this.value);

  /// sets the value of the boolean.
  ///
  /// accepts a [newValue] to be set and returns the previously set value.
  bool set(bool newValue) {
    bool ret;
    // synchronized(semaphore, {
    ret = get();
    value = newValue;
    // });
    return ret;
  }

  /// Gets the currently set value.
  ///
  /// Returns the currently set value of the boolean.
  bool get() {
    // synchronized(semaphore, {
    return value;
    // });
  }

  /// Toggles the currently set value.
  ///
  /// Returns the new set value.
  bool toggle() {
    bool ret;
    // synchronized(semaphore, {
    ret = get();
    value = (!ret);
    // });
    return value;
  }
}
