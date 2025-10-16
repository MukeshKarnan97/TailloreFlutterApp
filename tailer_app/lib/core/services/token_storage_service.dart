/// Token Storage Service
/// Manages JWT tokens using flutter_secure_storage for secure storage
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tailer_app/core/config/api_config.dart';
import 'package:tailer_app/core/utils/logger.dart';

class TokenStorageService {
  static final TokenStorageService _instance = TokenStorageService._internal();
  factory TokenStorageService() => _instance;
  TokenStorageService._internal();

  // Secure storage instance with configuration
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // ==================== TOKEN MANAGEMENT ====================

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: StorageKeys.accessToken, value: token);
      Logger.info('TokenStorage', '✅ Access token saved');
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to save access token', error: e);
      rethrow;
    }
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: StorageKeys.accessToken);
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to read access token', error: e);
      return null;
    }
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: StorageKeys.refreshToken, value: token);
      Logger.info('TokenStorage', '✅ Refresh token saved');
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to save refresh token', error: e);
      rethrow;
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: StorageKeys.refreshToken);
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to read refresh token', error: e);
      return null;
    }
  }

  /// Save both access and refresh tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await Future.wait([
        saveAccessToken(accessToken),
        saveRefreshToken(refreshToken),
      ]);
      Logger.info('TokenStorage', '✅ Both tokens saved');
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to save tokens', error: e);
      rethrow;
    }
  }

  /// Clear all tokens
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: StorageKeys.accessToken),
        _storage.delete(key: StorageKeys.refreshToken),
      ]);
      Logger.info('TokenStorage', '✅ Tokens cleared');
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to clear tokens', error: e);
      rethrow;
    }
  }

  /// Check if access token exists
  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Check if user is authenticated (has valid tokens)
  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty;
  }

  // ==================== USER DATA STORAGE ====================

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: StorageKeys.userId, value: userId);
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to save user ID', error: e);
    }
  }

  /// Get user ID
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: StorageKeys.userId);
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to read user ID', error: e);
      return null;
    }
  }

  /// Save user email
  Future<void> saveUserEmail(String email) async {
    try {
      await _storage.write(key: StorageKeys.userEmail, value: email);
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to save user email', error: e);
    }
  }

  /// Get user email
  Future<String?> getUserEmail() async {
    try {
      return await _storage.read(key: StorageKeys.userEmail);
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to read user email', error: e);
      return null;
    }
  }

  /// Save user type
  Future<void> saveUserType(String userType) async {
    try {
      await _storage.write(key: StorageKeys.userType, value: userType);
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to save user type', error: e);
    }
  }

  /// Get user type
  Future<String?> getUserType() async {
    try {
      return await _storage.read(key: StorageKeys.userType);
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to read user type', error: e);
      return null;
    }
  }

  /// Save login state
  Future<void> saveLoginState(bool isLoggedIn) async {
    try {
      await _storage.write(
        key: StorageKeys.isLoggedIn,
        value: isLoggedIn.toString(),
      );
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to save login state', error: e);
    }
  }

  /// Get login state
  Future<bool> getLoginState() async {
    try {
      final value = await _storage.read(key: StorageKeys.isLoggedIn);
      return value == 'true';
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to read login state', error: e);
      return false;
    }
  }

  /// Save last login date
  Future<void> saveLastLoginDate() async {
    try {
      await _storage.write(
        key: StorageKeys.lastLoginDate,
        value: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to save last login date', error: e);
    }
  }

  /// Get last login date
  Future<DateTime?> getLastLoginDate() async {
    try {
      final value = await _storage.read(key: StorageKeys.lastLoginDate);
      return value != null ? DateTime.parse(value) : null;
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to read last login date', error: e);
      return null;
    }
  }

  /// Save device token (for push notifications)
  Future<void> saveDeviceToken(String token) async {
    try {
      await _storage.write(key: StorageKeys.deviceToken, value: token);
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to save device token', error: e);
    }
  }

  /// Get device token
  Future<String?> getDeviceToken() async {
    try {
      return await _storage.read(key: StorageKeys.deviceToken);
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to read device token', error: e);
      return null;
    }
  }

  // ==================== CLEAR ALL DATA ====================

  /// Clear all stored data (logout)
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      Logger.info('TokenStorage', '✅ All stored data cleared');
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to clear all data', error: e);
      rethrow;
    }
  }

  /// Clear only user-related data (keep tokens)
  Future<void> clearUserData() async {
    try {
      await Future.wait([
        _storage.delete(key: StorageKeys.userId),
        _storage.delete(key: StorageKeys.userEmail),
        _storage.delete(key: StorageKeys.userType),
        _storage.delete(key: StorageKeys.isLoggedIn),
      ]);
      Logger.info('TokenStorage', '✅ User data cleared');
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to clear user data', error: e);
      rethrow;
    }
  }

  // ==================== DEBUG & UTILITY ====================

  /// Get all keys (for debugging)
  Future<Map<String, String>> getAllKeys() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to read all keys', error: e);
      return {};
    }
  }

  /// Check if a specific key exists
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      Logger.error('TokenStorage', 'Failed to check key existence', error: e);
      return false;
    }
  }
}
