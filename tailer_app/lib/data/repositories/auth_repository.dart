import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import '../models/user_model.dart';
import '../models/auth_session_model.dart';
import '../models/user_preferences_model.dart';
import '../services/local_db_service.dart';
import '../services/auth_storage_service.dart';

class AuthRepository {
  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;
  AuthRepository._internal();

  final LocalDatabaseService _dbService = LocalDatabaseService();
  final AuthStorageService _storageService = AuthStorageService();

  // Password hashing
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  // Session ID generation
  String _generateSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  // Token generation (simple for local use)
  String _generateToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(64, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  // User Registration
  Future<UserModel> signUp({
    required String username,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      debugPrint('Starting user registration for: $email');

      // Check if user already exists
      final existingUsers = await _dbService.select(
        'users',
        where: 'email = ? OR username = ?',
        whereArgs: [email, username],
      );

      if (existingUsers.isNotEmpty) {
        final existing = existingUsers.first;
        if (existing['email'] == email) {
          throw Exception('User with this email already exists');
        }
        if (existing['username'] == username) {
          throw Exception('Username already taken');
        }
      }

      // Create password hash
      final salt = _generateSalt();
      final passwordHash = _hashPassword(password, salt);
      final saltedHash = '$salt:$passwordHash';

      // Create user
      final now = DateTime.now();
      final user = UserModel(
        username: username.trim(),
        email: email.toLowerCase().trim(),
        phone: phone?.trim(),
        passwordHash: saltedHash,
        createdAt: now,
        updatedAt: now,
      );

      // Insert user into database
      final userId = await _dbService.insert('users', user.toMap());
      final createdUser = user.copyWith(id: userId);

      // Create default preferences
      final preferences = UserPreferencesModel.defaultPreferences(userId);
      await _dbService.insert('user_preferences', preferences.toMap());

      debugPrint('User registered successfully with ID: $userId');
      return createdUser;
    } catch (e) {
      debugPrint('Error during sign up: $e');
      rethrow;
    }
  }

  // User Login
  Future<AuthSessionModel> signIn({
    required String emailOrUsername,
    required String password,
    bool rememberMe = false,
    String? deviceInfo,
  }) async {
    try {
      debugPrint('Starting sign in for: $emailOrUsername');

      // Find user by email or username
      final users = await _dbService.select(
        'users',
        where: 'email = ? OR username = ?',
        whereArgs: [emailOrUsername.toLowerCase().trim(), emailOrUsername.trim()],
      );

      if (users.isEmpty) {
        throw Exception('User not found');
      }

      final userData = users.first;
      final user = UserModel.fromMap(userData);

      // Verify password
      final passwordParts = user.passwordHash.split(':');
      if (passwordParts.length != 2) {
        throw Exception('Invalid password hash format');
      }

      final salt = passwordParts[0];
      final storedHash = passwordParts[1];
      final inputHash = _hashPassword(password, salt);

      if (inputHash != storedHash) {
        // Record failed login attempt
        await _recordLoginAttempt(user.id!, false, deviceInfo);
        throw Exception('Invalid password');
      }

      // Create session
      final sessionId = _generateSessionId();
      final accessToken = _generateToken();
      final refreshToken = _generateToken();
      
      final session = AuthSessionModel(
        sessionId: sessionId,
        userId: user.id!,
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        createdAt: DateTime.now(),
        deviceInfo: deviceInfo,
      );

      // Store session in database
      await _dbService.insert('auth_sessions', session.toMap());

      // Store in secure storage
      await _storageService.storeAuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        sessionId: sessionId,
        userId: user.id!.toString(),
        userEmail: user.email,
      );

      // Update remember me preference
      await _storageService.setRememberMe(rememberMe);

      // Update user login info
      await _dbService.update(
        'users',
        {
          'last_login': DateTime.now().toIso8601String(),
          'login_count': user.loginCount + 1,
        },
        where: 'id = ?',
        whereArgs: [user.id],
      );

      // Record successful login attempt
      await _recordLoginAttempt(user.id!, true, deviceInfo);

      debugPrint('User signed in successfully: ${user.email}');
      return session;
    } catch (e) {
      debugPrint('Error during sign in: $e');
      rethrow;
    }
  }

  // Record login attempt
  Future<void> _recordLoginAttempt(int userId, bool wasSuccessful, String? deviceInfo) async {
    try {
      await _dbService.insert('login_history', {
        'user_id': userId,
        'login_time': DateTime.now().toIso8601String(),
        'device_info': deviceInfo,
        'login_method': 'password',
        'was_successful': wasSuccessful ? 1 : 0,
      });
    } catch (e) {
      debugPrint('Error recording login attempt: $e');
      // Don't throw, as this shouldn't block login
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final isLoggedIn = await _storageService.isLoggedIn();
      if (!isLoggedIn) return false;

      // Verify session exists and is valid
      final sessionId = await _storageService.getSessionId();
      if (sessionId == null) return false;

      final sessions = await _dbService.select(
        'auth_sessions',
        where: 'session_id = ? AND is_active = 1',
        whereArgs: [sessionId],
      );

      if (sessions.isEmpty) return false;

      final session = AuthSessionModel.fromMap(sessions.first);
      return session.isValid;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      final userId = await _storageService.getUserId();
      if (userId == null) return null;

      final users = await _dbService.select(
        'users',
        where: 'id = ?',
        whereArgs: [int.parse(userId)],
      );

      if (users.isEmpty) return null;
      return UserModel.fromMap(users.first);
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  // Get current session
  Future<AuthSessionModel?> getCurrentSession() async {
    try {
      final sessionId = await _storageService.getSessionId();
      if (sessionId == null) return null;

      final sessions = await _dbService.select(
        'auth_sessions',
        where: 'session_id = ? AND is_active = 1',
        whereArgs: [sessionId],
      );

      if (sessions.isEmpty) return null;
      return AuthSessionModel.fromMap(sessions.first);
    } catch (e) {
      debugPrint('Error getting current session: $e');
      return null;
    }
  }

  // Refresh session
  Future<AuthSessionModel?> refreshSession() async {
    try {
      final currentSession = await getCurrentSession();
      if (currentSession == null) return null;

      if (!currentSession.needsRefresh) {
        return currentSession; // No need to refresh yet
      }

      // Generate new tokens
      final newAccessToken = _generateToken();
      final newRefreshToken = _generateToken();
      
      // Update session in database
      final updatedSession = currentSession.renewSession(
        newAccessToken: newAccessToken,
        newRefreshToken: newRefreshToken,
      );

      await _dbService.update(
        'auth_sessions',
        updatedSession.toMap(),
        where: 'id = ?',
        whereArgs: [currentSession.id],
      );

      // Update storage
      await _storageService.updateTokens(
        newAccessToken: newAccessToken,
        newRefreshToken: newRefreshToken,
      );

      debugPrint('Session refreshed successfully');
      return updatedSession;
    } catch (e) {
      debugPrint('Error refreshing session: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut({bool clearRememberMe = false}) async {
    try {
      final sessionId = await _storageService.getSessionId();
      
      if (sessionId != null) {
        // Deactivate session in database
        await _dbService.update(
          'auth_sessions',
          {'is_active': 0},
          where: 'session_id = ?',
          whereArgs: [sessionId],
        );
      }

      // Clear storage
      await _storageService.clearAuthData();
      
      if (clearRememberMe) {
        await _storageService.setRememberMe(false);
      }

      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Error during sign out: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<UserModel> updateUserProfile({
    required int userId,
    String? username,
    String? phone,
    String? profilePicture,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (username != null) updateData['username'] = username.trim();
      if (phone != null) updateData['phone'] = phone.trim();
      if (profilePicture != null) updateData['profile_picture'] = profilePicture;

      if (updateData.isNotEmpty) {
        await _dbService.update(
          'users',
          updateData,
          where: 'id = ?',
          whereArgs: [userId],
        );
      }

      // Get updated user
      final users = await _dbService.select(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      return UserModel.fromMap(users.first);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  // Change password
  Future<void> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Get current user
      final users = await _dbService.select(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (users.isEmpty) {
        throw Exception('User not found');
      }

      final user = UserModel.fromMap(users.first);

      // Verify current password
      final passwordParts = user.passwordHash.split(':');
      if (passwordParts.length != 2) {
        throw Exception('Invalid password hash format');
      }

      final salt = passwordParts[0];
      final storedHash = passwordParts[1];
      final currentHash = _hashPassword(currentPassword, salt);

      if (currentHash != storedHash) {
        throw Exception('Current password is incorrect');
      }

      // Create new password hash
      final newSalt = _generateSalt();
      final newPasswordHash = _hashPassword(newPassword, newSalt);
      final newSaltedHash = '$newSalt:$newPasswordHash';

      // Update password in database
      await _dbService.update(
        'users',
        {'password_hash': newSaltedHash},
        where: 'id = ?',
        whereArgs: [userId],
      );

      // Invalidate all other sessions for security
      await _dbService.update(
        'auth_sessions',
        {'is_active': 0},
        where: 'user_id = ? AND session_id != ?',
        whereArgs: [userId, await _storageService.getSessionId()],
      );

      debugPrint('Password changed successfully for user: $userId');
    } catch (e) {
      debugPrint('Error changing password: $e');
      rethrow;
    }
  }

  // Get user preferences
  Future<UserPreferencesModel?> getUserPreferences(int userId) async {
    try {
      final preferences = await _dbService.select(
        'user_preferences',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (preferences.isEmpty) {
        // Create default preferences if none exist
        final defaultPrefs = UserPreferencesModel.defaultPreferences(userId);
        await _dbService.insert('user_preferences', defaultPrefs.toMap());
        return defaultPrefs;
      }

      return UserPreferencesModel.fromMap(preferences.first);
    } catch (e) {
      debugPrint('Error getting user preferences: $e');
      return null;
    }
  }

  // Update user preferences
  Future<UserPreferencesModel> updateUserPreferences({
    required int userId,
    String? themeMode,
    String? language,
    bool? notificationsEnabled,
    bool? biometricEnabled,
    bool? rememberMe,
    int? autoLogoutDuration,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (themeMode != null) updateData['theme_mode'] = themeMode;
      if (language != null) updateData['language'] = language;
      if (notificationsEnabled != null) updateData['notifications_enabled'] = notificationsEnabled ? 1 : 0;
      if (biometricEnabled != null) updateData['biometric_enabled'] = biometricEnabled ? 1 : 0;
      if (rememberMe != null) updateData['remember_me'] = rememberMe ? 1 : 0;
      if (autoLogoutDuration != null) updateData['auto_logout_duration'] = autoLogoutDuration;

      if (updateData.isNotEmpty) {
        await _dbService.update(
          'user_preferences',
          updateData,
          where: 'user_id = ?',
          whereArgs: [userId],
        );
      }

      // Update storage service preferences
      if (rememberMe != null) {
        await _storageService.setRememberMe(rememberMe);
      }
      if (biometricEnabled != null) {
        await _storageService.setBiometricEnabled(biometricEnabled);
      }

      // Get updated preferences
      final preferences = await _dbService.select(
        'user_preferences',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      return UserPreferencesModel.fromMap(preferences.first);
    } catch (e) {
      debugPrint('Error updating user preferences: $e');
      rethrow;
    }
  }

  // Get login history
  Future<List<Map<String, dynamic>>> getLoginHistory(int userId, {int limit = 10}) async {
    try {
      return await _dbService.select(
        'login_history',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'login_time DESC',
        limit: limit,
      );
    } catch (e) {
      debugPrint('Error getting login history: $e');
      return [];
    }
  }

  // Cleanup expired sessions
  Future<void> cleanupExpiredSessions() async {
    try {
      final now = DateTime.now().toIso8601String();
      await _dbService.update(
        'auth_sessions',
        {'is_active': 0},
        where: 'expires_at < ?',
        whereArgs: [now],
      );
      debugPrint('Expired sessions cleaned up');
    } catch (e) {
      debugPrint('Error cleaning up expired sessions: $e');
    }
  }

  // Auto-logout check
  Future<bool> shouldAutoLogout() async {
    try {
      final userId = await _storageService.getUserId();
      if (userId == null) return true;

      final preferences = await getUserPreferences(int.parse(userId));
      if (preferences == null) return false;

      final lastLoginTime = await _storageService.getLastLoginTime();
      if (lastLoginTime == null) return true;

      final autoLogoutDuration = preferences.autoLogoutDurationAsDuration;
      final shouldLogout = DateTime.now().difference(lastLoginTime) > autoLogoutDuration;
      
      if (shouldLogout) {
        debugPrint('Auto-logout triggered');
        await signOut();
      }
      
      return shouldLogout;
    } catch (e) {
      debugPrint('Error checking auto-logout: $e');
      return false;
    }
  }

  /// Update remember me preference in storage
  Future<void> updateRememberMe(bool rememberMe) async {
    try {
      await _storageService.setRememberMe(rememberMe);
      debugPrint('AuthRepository: Remember me updated to: $rememberMe');
    } catch (e) {
      debugPrint('AuthRepository: Error updating remember me: $e');
      rethrow;
    }
  }
}