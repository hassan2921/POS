import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../data/hive_database.dart';

class PinService {
  static const String _pinHashKey = 'app_pin_hash';
  static const String _pinSaltKey = 'app_pin_salt';
  static const String _pinSetKey = 'app_pin_set';

  static bool _isAuthenticated = false;
  static int _failedAttempts = 0;
  static DateTime? _lockUntil;
  static const int _maxAttempts = 5;
  static const int _lockSeconds = 30;

  static bool isAuthenticated() => _isAuthenticated;

  static void authenticate() {
    _isAuthenticated = true;
    _failedAttempts = 0;
    _lockUntil = null;
  }

  static void logout() => _isAuthenticated = false;

  static bool isPinSet() {
    final flagSet =
        HiveDatabase.settingsBox.get(_pinSetKey, defaultValue: false) as bool;
    return flagSet && HiveDatabase.settingsBox.containsKey(_pinHashKey);
  }

  static bool isLocked() {
    if (_lockUntil == null) return false;
    if (DateTime.now().isAfter(_lockUntil!)) {
      _lockUntil = null;
      return false;
    }
    return true;
  }

  static int lockRemainingSeconds() {
    if (_lockUntil == null) return 0;
    final remaining = _lockUntil!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  static String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(salt + pin);
    return sha256.convert(bytes).toString();
  }

  static Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await HiveDatabase.settingsBox.put(_pinHashKey, hash);
    await HiveDatabase.settingsBox.put(_pinSaltKey, salt);
    await HiveDatabase.settingsBox.put(_pinSetKey, true);
    await HiveDatabase.settingsBox.delete('app_pin'); // remove legacy plaintext key
  }

  static bool verifyPin(String attempt) {
    if (isLocked()) return false;
    final hash = HiveDatabase.settingsBox.get(_pinHashKey) as String?;
    final salt = HiveDatabase.settingsBox.get(_pinSaltKey) as String?;
    if (hash == null || salt == null) return false;
    final valid = _hashPin(attempt, salt) == hash;
    if (!valid) {
      _failedAttempts++;
      if (_failedAttempts >= _maxAttempts) {
        _lockUntil =
            DateTime.now().add(const Duration(seconds: _lockSeconds));
        _failedAttempts = 0;
      }
    } else {
      _failedAttempts = 0;
    }
    return valid;
  }

  static Future<void> clearPin() async {
    await HiveDatabase.settingsBox.delete(_pinHashKey);
    await HiveDatabase.settingsBox.delete(_pinSaltKey);
    await HiveDatabase.settingsBox.put(_pinSetKey, false);
    await HiveDatabase.settingsBox.delete('app_pin');
  }
}
