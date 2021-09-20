/// <p>A boolean valuable offering atomic toggling.</p>
class SwitchableBoolean {
  bool value;

  SwitchableBoolean(this.value);

  /// <p>sets the value of the boolean.</p>
  ///
  /// @param newValue the new value to be set
  /// @return the previously set value
  bool set(bool newValue) {
    bool ret;
    // synchronized(semaphore, {
    ret = get();
    value = newValue;
    // });
    return ret;
  }

  /// <p>gets the currently set value.</p>
  ///
  /// @return the currently set value
  bool get() {
    // synchronized(semaphore, {
    return value;
    // });
  }

  /// <p>Toggles the currently set value.</p>
  ///
  /// @return the previously set value
  bool toggle() {
    bool ret;
    // synchronized(semaphore, {
    ret = get();
    value = (!ret);
    // });
    return ret;
  }
}
