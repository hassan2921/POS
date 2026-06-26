import '../data/hive_database.dart';

class PinService {
  static const String _pinKey = 'app_pin';
  static const String _pinSetKey = 'app_pin_set';

  static bool _isAuthenticated = false;

  /// Returns true if the user is authenticated in the current session
  static bool isAuthenticated() {
    return _isAuthenticated;
  }

  /// Marks the current session as authenticated
  static void authenticate() {
    _isAuthenticated = true;
  }

  /// Locks the current session (requires entering the PIN again)
  static void logout() {
    _isAuthenticated = false;
  }

  /// Returns true if a PIN has been configured
  static bool isPinSet() {
    return HiveDatabase.settingsBox.get(_pinSetKey, defaultValue: false) as bool;
  }

  /// Returns the stored PIN (or null if not set)
  static String? getPin() {
    return HiveDatabase.settingsBox.get(_pinKey) as String?;
  }

  /// Saves a new PIN
  static Future<void> setPin(String pin) async {
    await HiveDatabase.settingsBox.put(_pinKey, pin);
    await HiveDatabase.settingsBox.put(_pinSetKey, true);
  }

  /// Verifies a PIN attempt
  static bool verifyPin(String attempt) {
    final stored = getPin();
    return stored != null && stored == attempt;
  }

  /// Clears the PIN (for reset)
  static Future<void> clearPin() async {
    await HiveDatabase.settingsBox.delete(_pinKey);
    await HiveDatabase.settingsBox.put(_pinSetKey, false);
  }
}
