import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../data/hive_database.dart';

class PinService {
  static const String _pinHashKey = 'app_pin_hash';
  static const String _pinSaltKey = 'app_pin_salt';
  static const String _pinSetKey = 'app_pin_set';
  static const String _pinVersionKey = 'app_pin_version';
  static const String _failedAttemptsKey = 'pin_failed_attempts';
  static const String _lockUntilKey = 'pin_lock_until';

  // Version 1 = legacy single SHA-256, Version 2 = PBKDF2-HMAC-SHA256
  static const int _currentVersion = 2;
  static const int _pbkdf2Iterations = 10000;

  static bool _isAuthenticated = false;
  static DateTime? _authTime;
  static const Duration _sessionTimeout = Duration(minutes: 30);

  static const int _maxAttempts = 5;
  static const int _lockSeconds = 30;

  // ── Authentication state ──────────────────────────────────────────────────

  static bool isAuthenticated() {
    if (!_isAuthenticated) return false;
    if (_authTime == null) {
      _isAuthenticated = false;
      return false;
    }
    if (DateTime.now().difference(_authTime!) > _sessionTimeout) {
      _isAuthenticated = false;
      _authTime = null;
      return false;
    }
    return true;
  }

  static void authenticate() {
    _isAuthenticated = true;
    _authTime = DateTime.now();
    _saveAttemptCount(0);
    _saveLockUntil(null);
  }

  static void logout() {
    _isAuthenticated = false;
    _authTime = null;
  }

  // ── PIN management ────────────────────────────────────────────────────────

  static bool isPinSet() {
    final flagSet =
        HiveDatabase.settingsBox.get(_pinSetKey, defaultValue: false) as bool;
    return flagSet && HiveDatabase.settingsBox.containsKey(_pinHashKey);
  }

  // ── Lockout (persisted to Hive so app-kill doesn't reset it) ─────────────

  static bool isLocked() {
    final lockUntil = _loadLockUntil();
    if (lockUntil == null) return false;
    if (DateTime.now().isAfter(lockUntil)) {
      _saveLockUntil(null);
      _saveAttemptCount(0);
      return false;
    }
    return true;
  }

  static int lockRemainingSeconds() {
    final lockUntil = _loadLockUntil();
    if (lockUntil == null) return 0;
    final remaining = lockUntil.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  static int _loadAttempts() =>
      HiveDatabase.settingsBox.get(_failedAttemptsKey, defaultValue: 0) as int;

  static void _saveAttemptCount(int count) =>
      HiveDatabase.settingsBox.put(_failedAttemptsKey, count);

  static DateTime? _loadLockUntil() {
    final ms = HiveDatabase.settingsBox.get(_lockUntilKey) as int?;
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  static void _saveLockUntil(DateTime? dt) {
    if (dt == null) {
      HiveDatabase.settingsBox.delete(_lockUntilKey);
    } else {
      HiveDatabase.settingsBox.put(_lockUntilKey, dt.millisecondsSinceEpoch);
    }
  }

  // ── Hashing ───────────────────────────────────────────────────────────────

  static String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// PBKDF2-HMAC-SHA256 (RFC 2898). Vastly more resistant to brute-force
  /// than single-pass SHA-256 against the extracted Hive database.
  static String _pbkdf2(String pin, String salt) {
    final keyBytes = utf8.encode(pin);
    final saltBytes = utf8.encode(salt);

    final hmac = Hmac(sha256, keyBytes);

    // U1 = HMAC(key, salt || INT(1))
    final saltWithBlock = Uint8List(saltBytes.length + 4);
    saltWithBlock.setAll(0, saltBytes);
    saltWithBlock[saltBytes.length] = 0;
    saltWithBlock[saltBytes.length + 1] = 0;
    saltWithBlock[saltBytes.length + 2] = 0;
    saltWithBlock[saltBytes.length + 3] = 1;

    List<int> u = hmac.convert(saltWithBlock).bytes;
    final result = List<int>.from(u);

    for (int i = 1; i < _pbkdf2Iterations; i++) {
      u = hmac.convert(u).bytes;
      for (int j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }

    return base64Url.encode(result);
  }

  static String _legacySha256(String pin, String salt) {
    final bytes = utf8.encode(salt + pin);
    return sha256.convert(bytes).toString();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  static Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = _pbkdf2(pin, salt);
    await HiveDatabase.settingsBox.put(_pinHashKey, hash);
    await HiveDatabase.settingsBox.put(_pinSaltKey, salt);
    await HiveDatabase.settingsBox.put(_pinSetKey, true);
    await HiveDatabase.settingsBox.put(_pinVersionKey, _currentVersion);
    await HiveDatabase.settingsBox.delete('app_pin');
  }

  static bool verifyPin(String attempt) {
    if (isLocked()) return false;

    final hash = HiveDatabase.settingsBox.get(_pinHashKey) as String?;
    final salt = HiveDatabase.settingsBox.get(_pinSaltKey) as String?;
    if (hash == null || salt == null) return false;

    final version =
        HiveDatabase.settingsBox.get(_pinVersionKey, defaultValue: 1) as int;

    final candidate =
        version == _currentVersion ? _pbkdf2(attempt, salt) : _legacySha256(attempt, salt);

    final valid = candidate == hash;

    if (valid) {
      // Upgrade legacy hash to PBKDF2 transparently on next successful login
      if (version < _currentVersion) {
        setPin(attempt);
      }
      _saveAttemptCount(0);
      _saveLockUntil(null);
    } else {
      final attempts = _loadAttempts() + 1;
      _saveAttemptCount(attempts);
      if (attempts >= _maxAttempts) {
        _saveLockUntil(
            DateTime.now().add(const Duration(seconds: _lockSeconds)));
        _saveAttemptCount(0);
      }
    }

    return valid;
  }

  static Future<void> clearPin() async {
    await HiveDatabase.settingsBox.delete(_pinHashKey);
    await HiveDatabase.settingsBox.delete(_pinSaltKey);
    await HiveDatabase.settingsBox.put(_pinSetKey, false);
    await HiveDatabase.settingsBox.delete(_pinVersionKey);
    await HiveDatabase.settingsBox.delete(_failedAttemptsKey);
    await HiveDatabase.settingsBox.delete(_lockUntilKey);
    await HiveDatabase.settingsBox.delete('app_pin');
    _isAuthenticated = false;
    _authTime = null;
  }
}
