import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import '../models/tailor_model.dart';
import '../services/local_db_service.dart';
import '../services/auth_storage_service.dart';

/// TailorAuthRepository - Authentication repository using Tailor model
/// 
/// This repository handles authentication using the tailor table as the
/// single source of truth for user identity and shop information.
class TailorAuthRepository {
  static final TailorAuthRepository _instance = TailorAuthRepository._internal();
  factory TailorAuthRepository() => _instance;
  TailorAuthRepository._internal();

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

  // Token generation for session management
  String _generateToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(64, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Register a new tailor with shop details
  Future<Tailor> signUp({
    required String name,
    required String shopName,
    required String email,
    required String phone,
    required String password,
    String address = '',
    String authProvider = 'email',
  }) async {
    try {
      debugPrint('TailorAuthRepository: Starting tailor registration for: $email');

      // Check if tailor already exists
      final existingTailors = await _dbService.select(
        'tailor',
        where: 'email = ? AND is_deleted = 0',
        whereArgs: [email.toLowerCase().trim()],
      );

      if (existingTailors.isNotEmpty) {
        throw Exception('Tailor with this email already exists');
      }

      // Create password hash
      final salt = _generateSalt();
      final passwordHash = _hashPassword(password, salt);
      final saltedHash = '$salt:$passwordHash';

      // Create tailor using factory method (generates MAT ID)
      final tailor = Tailor.create(
        name: name.trim(),
        shopName: shopName.trim(),
        email: email.toLowerCase().trim(),
        phone: phone.trim(),
        passwordHash: saltedHash,
        authProvider: authProvider,
        address: address.trim(),
      );

      // Insert tailor into database
      // Note: Using rawInsert instead of insert to avoid getting an integer ID
      final db = await _dbService.database;
      await db.insert('tailor', tailor.toMap());
      
      debugPrint('TailorAuthRepository: Tailor registered successfully with ID: ${tailor.id}');
      return tailor;
    } catch (e) {
      debugPrint('TailorAuthRepository: Error during sign up: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<Tailor> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      debugPrint('TailorAuthRepository: Starting sign in for: $email');

      // Find tailor by email
      final tailors = await _dbService.select(
        'tailor',
        where: 'email = ? AND is_deleted = 0',
        whereArgs: [email.toLowerCase().trim()],
      );

      if (tailors.isEmpty) {
        throw Exception('Tailor not found');
      }

      final tailorData = tailors.first;
      final tailor = Tailor.fromMap(tailorData);

      // Verify password
      final passwordParts = tailor.passwordHash.split(':');
      if (passwordParts.length != 2) {
        throw Exception('Invalid password hash format');
      }

      final salt = passwordParts[0];
      final storedHash = passwordParts[1];
      final inputHash = _hashPassword(password, salt);

      if (inputHash != storedHash) {
        throw Exception('Invalid password');
      }

      // Generate session token
      final accessToken = _generateToken();

      // Store in secure storage
      await _storageService.storeAuthTokens(
        accessToken: accessToken,
        refreshToken: _generateToken(),
        sessionId: tailor.id, // Use tailor ID as session ID
        userId: tailor.id, // Use tailor ID as user ID
        userEmail: tailor.email,
      );

      // Update remember me preference
      await _storageService.setRememberMe(rememberMe);

      debugPrint('TailorAuthRepository: Tailor signed in successfully: ${tailor.email}');
      return tailor;
    } catch (e) {
      debugPrint('TailorAuthRepository: Error during sign in: $e');
      rethrow;
    }
  }

  /// Get current tailor from storage
  Future<Tailor?> getCurrentTailor() async {
    try {
      debugPrint('TailorAuthRepository: Getting current tailor from storage');
      
      final userEmail = await _storageService.getUserEmail();
      if (userEmail == null) {
        debugPrint('TailorAuthRepository: No user email in storage');
        return null;
      }

      // Find tailor by email
      final tailors = await _dbService.select(
        'tailor',
        where: 'email = ? AND is_deleted = 0',
        whereArgs: [userEmail],
      );

      if (tailors.isEmpty) {
        debugPrint('TailorAuthRepository: No tailor found for email: $userEmail');
        return null;
      }

      final tailor = Tailor.fromMap(tailors.first);
      debugPrint('TailorAuthRepository: Found current tailor: ${tailor.email}');
      return tailor;
    } catch (e) {
      debugPrint('TailorAuthRepository: Error getting current tailor: $e');
      return null;
    }
  }

  /// Check if a tailor is currently logged in
  Future<bool> isLoggedIn() async {
    try {
      final accessToken = await _storageService.getAccessToken();
      final userEmail = await _storageService.getUserEmail();
      
      debugPrint('TailorAuthRepository: Checking login status');
      debugPrint('  - Has access token: ${accessToken != null}');
      debugPrint('  - Has user email: ${userEmail != null}');
      
      return accessToken != null && userEmail != null;
    } catch (e) {
      debugPrint('TailorAuthRepository: Error checking login status: $e');
      return false;
    }
  }

  /// Sign out the current tailor
  Future<void> signOut() async {
    try {
      debugPrint('TailorAuthRepository: Signing out');
      await _storageService.clearAuthData();
      debugPrint('TailorAuthRepository: Sign out successful');
    } catch (e) {
      debugPrint('TailorAuthRepository: Error during sign out: $e');
      rethrow;
    }
  }

  /// Update tailor profile
  Future<Tailor> updateProfile(Tailor tailor) async {
    try {
      debugPrint('TailorAuthRepository: Updating tailor profile: ${tailor.email}');

      final updatedTailor = tailor.copyWith(
        updatedAt: DateTime.now(),
      );

      await _dbService.update(
        'tailor',
        updatedTailor.toMap(),
        where: 'id = ?',
        whereArgs: [tailor.id],
      );

      debugPrint('TailorAuthRepository: Profile updated successfully');
      return updatedTailor;
    } catch (e) {
      debugPrint('TailorAuthRepository: Error updating profile: $e');
      rethrow;
    }
  }

  /// Change password
  Future<void> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      debugPrint('TailorAuthRepository: Changing password for: $email');

      // Verify current password by signing in
      final tailor = await signIn(email: email, password: oldPassword);

      // Create new password hash
      final salt = _generateSalt();
      final passwordHash = _hashPassword(newPassword, salt);
      final saltedHash = '$salt:$passwordHash';

      // Update password
      await _dbService.update(
        'tailor',
        {
          'password_hash': saltedHash,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [tailor.id],
      );

      debugPrint('TailorAuthRepository: Password changed successfully');
    } catch (e) {
      debugPrint('TailorAuthRepository: Error changing password: $e');
      rethrow;
    }
  }

  /// Check if email already exists
  Future<bool> checkEmailExists(String email) async {
    try {
      final tailors = await _dbService.select(
        'tailor',
        where: 'email = ? AND is_deleted = 0',
        whereArgs: [email.toLowerCase().trim()],
      );
      return tailors.isNotEmpty;
    } catch (e) {
      debugPrint('TailorAuthRepository: Error checking email existence: $e');
      return false;
    }
  }
}
