import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/user_preferences_model.dart';
import '../services/local_db_service.dart';
import '../services/auth_storage_service.dart';

class UserRepository {
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();

  final LocalDatabaseService _dbService = LocalDatabaseService();
  final AuthStorageService _storageService = AuthStorageService();

  // Get user by ID
  Future<UserModel?> getUserById(int userId) async {
    try {
      final users = await _dbService.select(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (users.isEmpty) return null;
      return UserModel.fromMap(users.first);
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      return null;
    }
  }

  // Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final users = await _dbService.select(
        'users',
        where: 'email = ?',
        whereArgs: [email.toLowerCase().trim()],
      );

      if (users.isEmpty) return null;
      return UserModel.fromMap(users.first);
    } catch (e) {
      debugPrint('Error getting user by email: $e');
      return null;
    }
  }

  // Get user by username
  Future<UserModel?> getUserByUsername(String username) async {
    try {
      final users = await _dbService.select(
        'users',
        where: 'username = ?',
        whereArgs: [username.trim()],
      );

      if (users.isEmpty) return null;
      return UserModel.fromMap(users.first);
    } catch (e) {
      debugPrint('Error getting user by username: $e');
      return null;
    }
  }

  // Update user profile
  Future<UserModel?> updateProfile({
    required int userId,
    String? username,
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
    String? profilePicture,
    String? bio,
    Map<String, dynamic>? socialLinks,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Validate and add fields to update
      if (username != null && username.trim().isNotEmpty) {
        // Check if username is already taken by another user
        final existingUser = await getUserByUsername(username.trim());
        if (existingUser != null && existingUser.id != userId) {
          throw Exception('Username already taken');
        }
        updateData['username'] = username.trim();
      }

      if (email != null && email.trim().isNotEmpty) {
        // Validate email format
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
        if (!emailRegex.hasMatch(email)) {
          throw Exception('Invalid email format');
        }
        
        // Check if email is already taken by another user
        final existingUser = await getUserByEmail(email);
        if (existingUser != null && existingUser.id != userId) {
          throw Exception('Email already in use');
        }
        updateData['email'] = email.toLowerCase().trim();
      }

      if (phone != null) {
        if (phone.trim().isNotEmpty) {
          // Basic phone validation
          final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
          if (!phoneRegex.hasMatch(phone.trim())) {
            throw Exception('Invalid phone number format');
          }
        }
        updateData['phone'] = phone.trim().isEmpty ? null : phone.trim();
      }

      if (firstName != null) {
        updateData['first_name'] = firstName.trim().isEmpty ? null : firstName.trim();
      }

      if (lastName != null) {
        updateData['last_name'] = lastName.trim().isEmpty ? null : lastName.trim();
      }

      if (profilePicture != null) {
        updateData['profile_picture'] = profilePicture.trim().isEmpty ? null : profilePicture.trim();
      }

      if (bio != null) {
        updateData['bio'] = bio.trim().isEmpty ? null : bio.trim();
      }

      if (socialLinks != null) {
        updateData['social_links'] = socialLinks.isEmpty ? null : socialLinks.toString();
      }

      // Update the user
      await _dbService.update(
        'users',
        updateData,
        where: 'id = ?',
        whereArgs: [userId],
      );

      // Return updated user
      return await getUserById(userId);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  // Update profile picture
  Future<UserModel?> updateProfilePicture({
    required int userId,
    required String imagePath,
  }) async {
    try {
      await _dbService.update(
        'users',
        {
          'profile_picture': imagePath,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      return await getUserById(userId);
    } catch (e) {
      debugPrint('Error updating profile picture: $e');
      rethrow;
    }
  }

  // Remove profile picture
  Future<UserModel?> removeProfilePicture(int userId) async {
    try {
      await _dbService.update(
        'users',
        {
          'profile_picture': null,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      return await getUserById(userId);
    } catch (e) {
      debugPrint('Error removing profile picture: $e');
      rethrow;
    }
  }

  // Get user preferences
  Future<UserPreferencesModel> getPreferences(int userId) async {
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
      return UserPreferencesModel.defaultPreferences(userId);
    }
  }

  // Update user preferences
  Future<UserPreferencesModel> updatePreferences({
    required int userId,
    String? themeMode,
    String? language,
    bool? notificationsEnabled,
    bool? biometricEnabled,
    bool? rememberMe,
    int? autoLogoutDuration,
    Map<String, dynamic>? customSettings,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Validate and add preference updates
      if (themeMode != null) {
        final validThemes = ['light', 'dark', 'system'];
        if (!validThemes.contains(themeMode)) {
          throw Exception('Invalid theme mode. Must be one of: ${validThemes.join(', ')}');
        }
        updateData['theme_mode'] = themeMode;
      }

      if (language != null) {
        final validLanguages = ['en', 'es', 'fr', 'de', 'hi', 'ar'];
        if (!validLanguages.contains(language)) {
          throw Exception('Unsupported language code');
        }
        updateData['language'] = language;
      }

      if (notificationsEnabled != null) {
        updateData['notifications_enabled'] = notificationsEnabled ? 1 : 0;
      }

      if (biometricEnabled != null) {
        updateData['biometric_enabled'] = biometricEnabled ? 1 : 0;
        // Update storage service
        await _storageService.setBiometricEnabled(biometricEnabled);
      }

      if (rememberMe != null) {
        updateData['remember_me'] = rememberMe ? 1 : 0;
        // Update storage service
        await _storageService.setRememberMe(rememberMe);
      }

      if (autoLogoutDuration != null) {
        if (autoLogoutDuration < 0) {
          throw Exception('Auto-logout duration must be positive');
        }
        updateData['auto_logout_duration'] = autoLogoutDuration;
      }

      if (customSettings != null) {
        updateData['custom_settings'] = customSettings.isEmpty ? null : customSettings.toString();
      }

      // Update preferences
      final existingPrefs = await _dbService.select(
        'user_preferences',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (existingPrefs.isEmpty) {
        // Create new preferences with defaults
        final defaultPrefs = UserPreferencesModel.defaultPreferences(userId);
        final newPrefsData = defaultPrefs.toMap();
        newPrefsData.addAll(updateData);
        await _dbService.insert('user_preferences', newPrefsData);
      } else {
        // Update existing preferences
        await _dbService.update(
          'user_preferences',
          updateData,
          where: 'user_id = ?',
          whereArgs: [userId],
        );
      }

      // Return updated preferences
      return await getPreferences(userId);
    } catch (e) {
      debugPrint('Error updating user preferences: $e');
      rethrow;
    }
  }

  // Reset preferences to defaults
  Future<UserPreferencesModel> resetPreferencesToDefaults(int userId) async {
    try {
      final defaultPrefs = UserPreferencesModel.defaultPreferences(userId);
      
      await _dbService.update(
        'user_preferences',
        defaultPrefs.toMap(),
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      // Reset storage service preferences
      await _storageService.setRememberMe(true); // Default remember me
      await _storageService.setBiometricEnabled(false); // Default biometric

      return defaultPrefs;
    } catch (e) {
      debugPrint('Error resetting preferences to defaults: $e');
      rethrow;
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics(int userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      // Get login history count
      final loginHistory = await _dbService.select(
        'login_history',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      // Get successful logins count
      final successfulLogins = await _dbService.select(
        'login_history',
        where: 'user_id = ? AND was_successful = 1',
        whereArgs: [userId],
      );

      // Get active sessions count
      final activeSessions = await _dbService.select(
        'auth_sessions',
        where: 'user_id = ? AND is_active = 1',
        whereArgs: [userId],
      );

      // Calculate account age
      final accountAge = DateTime.now().difference(user.createdAt);

      return {
        'total_logins': loginHistory.length,
        'successful_logins': successfulLogins.length,
        'failed_logins': loginHistory.length - successfulLogins.length,
        'active_sessions': activeSessions.length,
        'account_age_days': accountAge.inDays,
        'last_login': user.lastLogin?.toIso8601String(),
        'login_count': user.loginCount,
        'created_at': user.createdAt.toIso8601String(),
        'updated_at': user.updatedAt.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting user statistics: $e');
      return {};
    }
  }

  // Search users (for admin purposes or friend search)
  Future<List<UserModel>> searchUsers({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final users = await _dbService.select(
        'users',
        where: 'username LIKE ? OR email LIKE ? OR first_name LIKE ? OR last_name LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
        limit: limit,
        offset: offset,
        orderBy: 'username ASC',
      );

      return users.map((userData) => UserModel.fromMap(userData)).toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Check username availability
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final user = await getUserByUsername(username);
      return user == null;
    } catch (e) {
      debugPrint('Error checking username availability: $e');
      return false;
    }
  }

  // Check email availability
  Future<bool> isEmailAvailable(String email) async {
    try {
      final user = await getUserByEmail(email);
      return user == null;
    } catch (e) {
      debugPrint('Error checking email availability: $e');
      return false;
    }
  }

  // Get user activity summary
  Future<Map<String, dynamic>> getUserActivity(int userId, {int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      
      // Get recent logins
      final recentLogins = await _dbService.select(
        'login_history',
        where: 'user_id = ? AND login_time >= ?',
        whereArgs: [userId, startDate.toIso8601String()],
        orderBy: 'login_time DESC',
      );

      // Group logins by date
      final loginsByDate = <String, int>{};
      for (final login in recentLogins) {
        final loginDate = DateTime.parse(login['login_time'] as String);
        final dateKey = '${loginDate.year}-${loginDate.month.toString().padLeft(2, '0')}-${loginDate.day.toString().padLeft(2, '0')}';
        loginsByDate[dateKey] = (loginsByDate[dateKey] ?? 0) + 1;
      }

      // Get device usage
      final deviceUsage = <String, int>{};
      for (final login in recentLogins) {
        final deviceInfo = login['device_info'] as String?;
        if (deviceInfo != null && deviceInfo.isNotEmpty) {
          deviceUsage[deviceInfo] = (deviceUsage[deviceInfo] ?? 0) + 1;
        }
      }

      return {
        'total_logins_period': recentLogins.length,
        'logins_by_date': loginsByDate,
        'device_usage': deviceUsage,
        'most_active_day': loginsByDate.entries.isNotEmpty
            ? loginsByDate.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : null,
        'period_days': days,
        'start_date': startDate.toIso8601String(),
        'end_date': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting user activity: $e');
      return {};
    }
  }

  // Delete user account (soft delete)
  Future<void> softDeleteUser(int userId) async {
    try {
      await _dbService.update(
        'users',
        {
          'is_active': 0,
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      // Deactivate all sessions
      await _dbService.update(
        'auth_sessions',
        {'is_active': 0},
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      debugPrint('User account soft deleted: $userId');
    } catch (e) {
      debugPrint('Error soft deleting user: $e');
      rethrow;
    }
  }

  // Restore deleted user account
  Future<void> restoreUser(int userId) async {
    try {
      await _dbService.update(
        'users',
        {
          'is_active': 1,
          'deleted_at': null,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      debugPrint('User account restored: $userId');
    } catch (e) {
      debugPrint('Error restoring user: $e');
      rethrow;
    }
  }

  // Get all users (admin function)
  Future<List<UserModel>> getAllUsers({
    int limit = 50,
    int offset = 0,
    bool includeDeleted = false,
  }) async {
    try {
      final whereClause = includeDeleted ? null : 'is_active = 1';
      
      final users = await _dbService.select(
        'users',
        where: whereClause,
        whereArgs: whereClause != null ? [1] : null,
        limit: limit,
        offset: offset,
        orderBy: 'created_at DESC',
      );

      return users.map((userData) => UserModel.fromMap(userData)).toList();
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  // Get user count
  Future<int> getUserCount({bool includeDeleted = false}) async {
    try {
      final whereClause = includeDeleted ? null : 'is_active = 1';
      
      final result = await _dbService.select(
        'users',
        columns: ['COUNT(*) as count'],
        where: whereClause,
        whereArgs: whereClause != null ? [1] : null,
      );

      return result.first['count'] as int;
    } catch (e) {
      debugPrint('Error getting user count: $e');
      return 0;
    }
  }
}