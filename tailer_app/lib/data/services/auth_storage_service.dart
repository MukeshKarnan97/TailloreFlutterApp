import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class AuthStorageService {
  static final AuthStorageService _instance = AuthStorageService._internal();
  factory AuthStorageService() => _instance;
  AuthStorageService._internal();

  // Simple encoding for sensitive data (not production-grade encryption)
  String _encodeValue(String value) {
    final bytes = utf8.encode(value);
    return base64Encode(bytes);
  }

  String _decodeValue(String encodedValue) {
    final bytes = base64Decode(encodedValue);
    return utf8.decode(bytes);
  }

  // Storage keys
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keySessionId = 'session_id';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyLastLoginTime = 'last_login_time';
  static const String _keyDeviceId = 'device_id';

  // Authentication token management
  Future<void> storeAuthTokens({
    required String accessToken,
    String? refreshToken,
    required String sessionId,
    required String userId,
    required String userEmail,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_keyAccessToken, _encodeValue(accessToken)),
        prefs.setString(_keySessionId, _encodeValue(sessionId)),
        prefs.setString(_keyUserId, userId),
        prefs.setString(_keyUserEmail, userEmail),
        if (refreshToken != null)
          prefs.setString(_keyRefreshToken, _encodeValue(refreshToken)),
      ]);
      
      await _setLoginStatus(true);
      await _setLastLoginTime(DateTime.now());
      
      debugPrint('Auth tokens stored successfully');
    } catch (e) {
      debugPrint('Error storing auth tokens: $e');
      rethrow;
    }
  }

  Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_keyAccessToken);
      return encoded != null ? _decodeValue(encoded) : null;
    } catch (e) {
      debugPrint('Error reading access token: $e');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_keyRefreshToken);
      return encoded != null ? _decodeValue(encoded) : null;
    } catch (e) {
      debugPrint('Error reading refresh token: $e');
      return null;
    }
  }

  Future<String?> getSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_keySessionId);
      return encoded != null ? _decodeValue(encoded) : null;
    } catch (e) {
      debugPrint('Error reading session ID: $e');
      return null;
    }
  }

  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserId);
    } catch (e) {
      debugPrint('Error reading user ID: $e');
      return null;
    }
  }

  Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserEmail);
    } catch (e) {
      debugPrint('Error reading user email: $e');
      return null;
    }
  }

  // Login state management
  Future<void> _setLoginStatus(bool isLoggedIn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, isLoggedIn);
    } catch (e) {
      debugPrint('Error setting login status: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      
      // Double-check by verifying we have tokens
      if (isLoggedIn) {
        final token = await getAccessToken();
        return token != null;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }

  // Remember me functionality
  Future<void> setRememberMe(bool rememberMe) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRememberMe, rememberMe);
    } catch (e) {
      debugPrint('Error setting remember me: $e');
    }
  }

  Future<bool> getRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyRememberMe) ?? false;
    } catch (e) {
      debugPrint('Error getting remember me: $e');
      return false;
    }
  }

  // Biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBiometricEnabled, enabled);
    } catch (e) {
      debugPrint('Error setting biometric enabled: $e');
    }
  }

  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyBiometricEnabled) ?? false;
    } catch (e) {
      debugPrint('Error getting biometric enabled: $e');
      return false;
    }
  }

  // Device management
  Future<void> setDeviceId(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDeviceId, _encodeValue(deviceId));
    } catch (e) {
      debugPrint('Error setting device ID: $e');
    }
  }

  Future<String?> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_keyDeviceId);
      return encoded != null ? _decodeValue(encoded) : null;
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      return null;
    }
  }

  // Last login time
  Future<void> _setLastLoginTime(DateTime dateTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastLoginTime, dateTime.toIso8601String());
    } catch (e) {
      debugPrint('Error setting last login time: $e');
    }
  }

  Future<DateTime?> getLastLoginTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString(_keyLastLoginTime);
      return timeString != null ? DateTime.parse(timeString) : null;
    } catch (e) {
      debugPrint('Error getting last login time: $e');
      return null;
    }
  }

  // Clear all authentication data
  Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_keyAccessToken),
        prefs.remove(_keyRefreshToken),
        prefs.remove(_keySessionId),
        prefs.remove(_keyUserId),
        prefs.remove(_keyUserEmail),
        _setLoginStatus(false),
      ]);
      
      debugPrint('Auth data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing auth data: $e');
      rethrow;
    }
  }

  // Clear all stored data (including preferences)
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      debugPrint('All stored data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing all data: $e');
      rethrow;
    }
  }

  // Update tokens (for refresh functionality)
  Future<void> updateTokens({
    String? newAccessToken,
    String? newRefreshToken,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final futures = <Future>[];
      
      if (newAccessToken != null) {
        futures.add(prefs.setString(_keyAccessToken, _encodeValue(newAccessToken)));
      }
      
      if (newRefreshToken != null) {
        futures.add(prefs.setString(_keyRefreshToken, _encodeValue(newRefreshToken)));
      }
      
      await Future.wait(futures);
      debugPrint('Tokens updated successfully');
    } catch (e) {
      debugPrint('Error updating tokens: $e');
      rethrow;
    }
  }

  // Get all auth data as a map
  Future<Map<String, String?>> getAllAuthData() async {
    try {
      return {
        'access_token': await getAccessToken(),
        'refresh_token': await getRefreshToken(),
        'session_id': await getSessionId(),
        'user_id': await getUserId(),
        'user_email': await getUserEmail(),
        'device_id': await getDeviceId(),
        'is_logged_in': (await isLoggedIn()).toString(),
        'remember_me': (await getRememberMe()).toString(),
        'biometric_enabled': (await isBiometricEnabled()).toString(),
        'last_login': (await getLastLoginTime())?.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting all auth data: $e');
      return {};
    }
  }

  // Check if tokens exist and are not empty
  Future<bool> hasValidTokens() async {
    try {
      final accessToken = await getAccessToken();
      final sessionId = await getSessionId();
      return accessToken != null && 
             accessToken.isNotEmpty && 
             sessionId != null && 
             sessionId.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking valid tokens: $e');
      return false;
    }
  }
}