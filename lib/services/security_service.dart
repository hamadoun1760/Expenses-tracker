import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AuthType { pin, password }

class SecurityService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'expense_tracker_prefs',
      preferencesKeyPrefix: 'expense_tracker_',
    ),
    iOptions: IOSOptions(
      groupId: 'com.example.expenses_tracking.security',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _pinKey = 'user_pin';
  static const String _passwordKey = 'user_password';
  static const String _authTypeKey = 'auth_type';
  static const String _isSecurityEnabledKey = 'security_enabled';
  static const String _autoLockTimeKey = 'auto_lock_time';

  // Hash function for PIN/password
  static String _hashCredential(String credential) {
    var bytes = utf8.encode(credential);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Check if security is enabled
  static Future<bool> isSecurityEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: _isSecurityEnabledKey);
      return enabled == 'true';
    } catch (e) {
      return false;
    }
  }

  // Get authentication type
  static Future<AuthType> getAuthType() async {
    try {
      final authType = await _secureStorage.read(key: _authTypeKey);
      return authType == 'password' ? AuthType.password : AuthType.pin;
    } catch (e) {
      return AuthType.pin;
    }
  }

  // Set up PIN
  static Future<bool> setupPin(String pin) async {
    try {
      if (pin.length != 4 || !RegExp(r'^\d+$').hasMatch(pin)) {
        return false; // PIN must be 4 digits
      }

      final hashedPin = _hashCredential(pin);
      await _secureStorage.write(key: _pinKey, value: hashedPin);
      await _secureStorage.write(key: _authTypeKey, value: 'pin');
      await _secureStorage.write(key: _isSecurityEnabledKey, value: 'true');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Set up password
  static Future<bool> setupPassword(String password) async {
    try {
      if (password.length < 6) {
        return false; // Password must be at least 6 characters
      }

      final hashedPassword = _hashCredential(password);
      await _secureStorage.write(key: _passwordKey, value: hashedPassword);
      await _secureStorage.write(key: _authTypeKey, value: 'password');
      await _secureStorage.write(key: _isSecurityEnabledKey, value: 'true');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Verify PIN
  static Future<bool> verifyPin(String pin) async {
    try {
      final storedPin = await _secureStorage.read(key: _pinKey);
      if (storedPin == null) return false;

      final hashedPin = _hashCredential(pin);
      return storedPin == hashedPin;
    } catch (e) {
      return false;
    }
  }

  // Verify password
  static Future<bool> verifyPassword(String password) async {
    try {
      final storedPassword = await _secureStorage.read(key: _passwordKey);
      if (storedPassword == null) return false;

      final hashedPassword = _hashCredential(password);
      return storedPassword == hashedPassword;
    } catch (e) {
      return false;
    }
  }

  // Verify credential based on auth type
  static Future<bool> verifyCredential(String credential) async {
    final authType = await getAuthType();
    if (authType == AuthType.pin) {
      return await verifyPin(credential);
    } else {
      return await verifyPassword(credential);
    }
  }

  // Disable security
  static Future<bool> disableSecurity() async {
    try {
      await _secureStorage.delete(key: _pinKey);
      await _secureStorage.delete(key: _passwordKey);
      await _secureStorage.delete(key: _authTypeKey);
      await _secureStorage.write(key: _isSecurityEnabledKey, value: 'false');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Change PIN
  static Future<bool> changePin(String oldPin, String newPin) async {
    try {
      final isValidOld = await verifyPin(oldPin);
      if (!isValidOld) return false;

      return await setupPin(newPin);
    } catch (e) {
      return false;
    }
  }

  // Change password
  static Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final isValidOld = await verifyPassword(oldPassword);
      if (!isValidOld) return false;

      return await setupPassword(newPassword);
    } catch (e) {
      return false;
    }
  }

  // Set auto-lock time (in minutes)
  static Future<bool> setAutoLockTime(int minutes) async {
    try {
      await _secureStorage.write(key: _autoLockTimeKey, value: minutes.toString());
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get auto-lock time
  static Future<int> getAutoLockTime() async {
    try {
      final lockTime = await _secureStorage.read(key: _autoLockTimeKey);
      return int.tryParse(lockTime ?? '5') ?? 5; // Default 5 minutes
    } catch (e) {
      return 5;
    }
  }

  // Clear all security data (for testing or reset)
  static Future<void> clearAllSecurityData() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      // Handle error silently
    }
  }
}