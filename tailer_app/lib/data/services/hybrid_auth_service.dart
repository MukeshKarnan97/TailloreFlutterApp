/// Hybrid Authentication Service
/// 
/// This service combines Django backend registration with local database authentication.
/// - Backend handles: Registration, OTP generation/verification
/// - Local handles: Authentication, token generation, session management
library;

import 'package:tailer_app/core/utils/logger.dart';
import 'package:tailer_app/data/models/tailor_model.dart';
import 'package:tailer_app/data/models/account/auth_models.dart';
import 'package:tailer_app/data/services/accounts_api_service.dart';
import 'package:tailer_app/data/services/local_db_service.dart';
import 'package:tailer_app/core/services/token_storage_service.dart';
import 'package:tailer_app/core/services/local_token_service.dart';
import 'package:tailer_app/core/exceptions/auth_exceptions.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class HybridAuthService {
  static final HybridAuthService _instance = HybridAuthService._internal();
  factory HybridAuthService() => _instance;
  HybridAuthService._internal();

  final AccountsApiService _apiService = AccountsApiService();
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final TokenStorageService _tokenStorage = TokenStorageService();
  final LocalTokenService _localTokenService = LocalTokenService();

  Tailor? _currentTailor;
  
  Tailor? get currentTailor => _currentTailor;
  bool get isAuthenticated => _currentTailor != null;
  String? get currentUserEmail => _currentTailor?.email;

  // ==================== INITIALIZATION ====================

  /// Initialize the service and restore session if available
  Future<void> initialize() async {
    try {
      Logger.info('HybridAuth', 'Initializing hybrid authentication...');
      
      final isAuthenticated = await _tokenStorage.isAuthenticated();
      if (isAuthenticated) {
        final userId = await _tokenStorage.getUserId();
        if (userId != null) {
          // Try to load from local DB first
          _currentTailor = await _loadTailorFromLocalDB(userId);
          
          if (_currentTailor != null) {
            Logger.info('HybridAuth', 'Session restored from local DB: ${_currentTailor!.email}');
          } else {
            Logger.info('HybridAuth', 'User logged in but not found in local DB, clearing session');
            await _tokenStorage.clearAll();
          }
        }
      }
    } catch (e) {
      Logger.error('HybridAuth', 'Error during initialization', error: e);
      await _tokenStorage.clearAll();
    }
  }

  // ==================== REGISTRATION FLOW ====================

  /// Step 1: Register with backend and insert into local DB
  /// API creates user in Django, returns user data, then insert into local DB
  Future<RegisterResponse> registerWithBackend({
    required String name,
    required String shopName,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirm,
    String address = '',
  }) async {
    try {
      Logger.info('HybridAuth', 'Starting backend registration for: $email');
      
      // Validate inputs
      _validateRegistrationInput(name, shopName, email, password, passwordConfirm);

      // Call Django backend register endpoint
      final request = RegisterRequest(
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
        name: name,
        shopName: shopName,
        phone: phone,
        address: address,
        authProvider: 'email',
      );

      final response = await _apiService.register(request);
      
      // At this point:
      // - User is created in Django backend (not activated yet)
      // - API will send OTP (handled by backend)
      // - Tokens are saved in secure storage
      // - NOW insert into local DB immediately with hashed password
      
      Logger.info('HybridAuth', 'Backend registration successful, inserting into local DB');
      
      // Hash the password locally and add it to user data before syncing
      // (Backend doesn't return password_hash for security)
      final hashedPassword = _hashPassword(password);
      Logger.debug('HybridAuth', 'Generated password hash: ${hashedPassword.substring(0, 16)}... (length: ${hashedPassword.length})');
      Logger.debug('HybridAuth', 'Original user passwordHash from API: "${response.user.passwordHash}"');
      
      final userWithHash = response.user.copyWith(passwordHash: hashedPassword);
      Logger.debug('HybridAuth', 'Updated user passwordHash: "${userWithHash.passwordHash.substring(0, 16)}..."');
      
      await _syncTailorToLocalDB(userWithHash);
      
      Logger.info('HybridAuth', 'User data synced to local DB with password hash, ready for OTP verification');
      return response;
    } catch (e) {
      Logger.error('HybridAuth', 'Backend registration failed', error: e);
      rethrow;
    }
  }

  // ==================== OTP VERIFICATION ====================

  /// Step 2: Verify OTP with backend, then activate user locally
  /// After verification, generate local tokens and mark user as active in DB
  Future<bool> verifyOTPAndActivate({
    required String email,
    required String otpCode,
  }) async {
    try {
      Logger.info('HybridAuth', 'Verifying OTP for: $email');

      // Call Django backend verify-otp endpoint (just for verification)
      final response = await _apiService.verifyOTP(
        email: email,
        otpCode: otpCode,
      );

      if (response.success) {
        Logger.info('HybridAuth', 'OTP verified successfully by backend');
        
        // Fetch user from local DB (already inserted during registration)
        Logger.info('HybridAuth', 'Fetching user from local DB...');
        final results = await _dbService.select(
          'tailor',
          where: 'email = ? AND is_deleted = 0',
          whereArgs: [email],
        );
        
        if (results.isEmpty) {
          Logger.error('HybridAuth', 'User not found in local database');
          throw Exception('User not found in local database. Please register again.');
        }
        
        final user = Tailor.fromMap(results.first);
        Logger.info('HybridAuth', 'User data fetched from local DB: ${user.email}');
        
        // Mark user as active in local DB
        await _dbService.update(
          'tailor',
          {
            'is_active': 1,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [user.id],
        );
        Logger.info('HybridAuth', 'User marked as active in local DB');
        
        // Generate local tokens
        final accessToken = _localTokenService.generateAccessToken(
          userId: user.id,
          email: user.email,
        );
        
        final refreshToken = _localTokenService.generateRefreshToken(
          userId: user.id,
          email: user.email,
        );
        
        // Save local tokens to secure storage
        await _tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        
        // Save user info
        await _tokenStorage.saveUserId(user.id);
        await _tokenStorage.saveUserEmail(user.email);
        await _tokenStorage.saveUserType('tailor');
        await _tokenStorage.saveLoginState(true);
        await _tokenStorage.saveLastLoginDate();
        
        Logger.info('HybridAuth', 'Local tokens generated and saved');
        
        // Set current tailor with active status
        _currentTailor = user.copyWith(
          isActive: true,
          updatedAt: DateTime.now(),
        );
        
        Logger.info('HybridAuth', 'OTP verification complete, user activated and authenticated locally');
        return true;
      } else {
        Logger.error('HybridAuth', 'OTP verification failed: ${response.message}');
        return false;
      }
    } catch (e) {
      Logger.error('HybridAuth', 'OTP verification error', error: e);
      rethrow;
    }
  }

  // ==================== LOGIN FLOW ====================

  /// Login with LOCAL database (offline-first authentication)
  /// Checks email, password, and active status in local DB only
  Future<Tailor> loginWithLocal({
    required String email,
    required String password,
  }) async {
    try {
      Logger.info('HybridAuth', 'Starting local login for: $email');

      // Validate inputs
      if (email.trim().isEmpty || password.isEmpty) {
        throw ValidationException(
          fieldErrors: {
            if (email.trim().isEmpty) 'email': 'Email is required',
            if (password.isEmpty) 'password': 'Password is required',
          },
        );
      }

      // Hash the password for comparison
      final passwordHash = _hashPassword(password);
      Logger.debug('HybridAuth', 'Login attempt - Generated hash: ${passwordHash.substring(0, 16)}... (length: ${passwordHash.length})');

      // First check if user exists at all
      final userCheck = await _dbService.select(
        'tailor',
        where: 'email = ? AND is_deleted = 0',
        whereArgs: [email.trim()],
      );
      
      if (userCheck.isEmpty) {
        Logger.error('HybridAuth', 'No user found with email: $email');
        throw InvalidCredentialsException(
          details: 'No user found with provided email',
        );
      }
      
      // Log what's in the database
      final dbPasswordHash = userCheck.first['password_hash'] as String;
      Logger.debug('HybridAuth', 'DB password_hash: "${dbPasswordHash.isEmpty ? "EMPTY" : dbPasswordHash.substring(0, 16)}" (length: ${dbPasswordHash.length})');
      Logger.debug('HybridAuth', 'Hashes match: ${dbPasswordHash == passwordHash}');

      // Query local database for user with password
      final results = await _dbService.select(
        'tailor',
        where: 'email = ? AND password_hash = ? AND is_deleted = 0',
        whereArgs: [email.trim(), passwordHash],
      );

      if (results.isEmpty) {
        Logger.error('HybridAuth', 'Invalid email or password - Hash mismatch');
        throw InvalidCredentialsException(
          details: 'Invalid password',
        );
      }

      final user = Tailor.fromMap(results.first);

      // Check if user is active (email verified)
      if (!user.isActive) {
        Logger.error('HybridAuth', 'User account not activated');
        throw AccountDisabledException(
          reason: 'Account is not activated. Please verify your email first.',
        );
      }

      Logger.info('HybridAuth', 'User found and active in local DB');

      // Generate local tokens
      final accessToken = _localTokenService.generateAccessToken(
        userId: user.id,
        email: user.email,
      );
      
      final refreshToken = _localTokenService.generateRefreshToken(
        userId: user.id,
        email: user.email,
      );

      // Save tokens and user info
      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      
      await _tokenStorage.saveUserId(user.id);
      await _tokenStorage.saveUserEmail(user.email);
      await _tokenStorage.saveUserType('tailor');
      await _tokenStorage.saveLoginState(true);
      await _tokenStorage.saveLastLoginDate();

      // Update last login in local DB
      await _dbService.update(
        'tailor',
        {
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [user.id],
      );

      // Set current user
      _currentTailor = user;

      Logger.info('HybridAuth', 'Local login successful for: $email');
      return user;
    } catch (e) {
      Logger.error('HybridAuth', 'Local login failed', error: e);
      rethrow;
    }
  }

  /// Login with backend and sync to local DB (DEPRECATED - use loginWithLocal)
  @Deprecated('Use loginWithLocal instead for offline-first authentication')
  Future<Tailor> loginWithBackend({
    required String email,
    required String password,
  }) async {
    // Redirect to local login
    return loginWithLocal(email: email, password: password);
  }

  // ==================== LOGOUT ====================

  /// Logout and clear tokens (keeps local DB data)
  Future<void> logout() async {
    try {
      Logger.info('HybridAuth', 'Logging out user');
      
      // Clear all tokens and session data from secure storage
      await _tokenStorage.clearAll();
      
      // Clear current user from memory
      _currentTailor = null;
      
      // Note: We keep local DB data for offline access
      // Only clear tokens and session
      
      Logger.info('HybridAuth', 'Logout successful - tokens and session cleared');
    } catch (e) {
      Logger.error('HybridAuth', 'Logout error', error: e);
      rethrow;
    }
  }

  // ==================== PROFILE UPDATE ====================

  /// Update profile on backend and sync to local DB
  Future<Tailor> updateProfile({
    String? name,
    String? shopName,
    String? phone,
    String? address,
  }) async {
    try {
      if (_currentTailor == null) {
        throw Exception('User not authenticated');
      }

      Logger.info('HybridAuth', 'Updating profile for: ${_currentTailor!.email}');

      // Call backend update endpoint
      final request = UpdateUserRequest(
        name: name,
        shopName: shopName,
        phone: phone,
        address: address,
      );

      final updatedTailor = await _apiService.updateCurrentUser(request);
      
      // Sync updated data to local DB
      await _syncTailorToLocalDB(updatedTailor);
      
      _currentTailor = updatedTailor;
      
      Logger.info('HybridAuth', 'Profile updated and synced to local DB');
      return updatedTailor;
    } catch (e) {
      Logger.error('HybridAuth', 'Profile update failed', error: e);
      rethrow;
    }
  }

  // ==================== PASSWORD MANAGEMENT ====================

  /// Change password on backend
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    try {
      if (_currentTailor == null) {
        throw Exception('User not authenticated');
      }

      Logger.info('HybridAuth', 'Changing password for: ${_currentTailor!.email}');

      final request = ChangePasswordRequest(
        oldPassword: oldPassword,
        newPassword: newPassword,
        newPasswordConfirm: newPasswordConfirm,
      );

      await _apiService.changePassword(request);
      
      Logger.info('HybridAuth', 'Password changed successfully');
    } catch (e) {
      Logger.error('HybridAuth', 'Password change failed', error: e);
      rethrow;
    }
  }

  /// Request password reset OTP
  /// Returns reset_token needed for password reset
  Future<String> requestPasswordReset(String email) async {
    try {
      Logger.info('HybridAuth', 'Requesting password reset for: $email');

      final resetToken = await _apiService.requestPasswordReset(email);
      
      Logger.info('HybridAuth', 'Password reset OTP sent to email');
      Logger.debug('HybridAuth', 'Reset token received: ${resetToken.substring(0, 10)}...');
      return resetToken;
    } catch (e) {
      Logger.error('HybridAuth', 'Password reset request failed', error: e);
      rethrow;
    }
  }

  /// Reset password with OTP
  /// Updates password in both backend API and local database
  Future<bool> resetPasswordWithOTP({
    required String email,
    required String otpCode,
    required String newPassword,
    required String newPasswordConfirm,
    required String resetToken, // Token from forgot password API
  }) async {
    try {
      Logger.info('HybridAuth', 'Resetting password for: $email');

      // Step 1: Send reset request to backend API
      final request = ResetPasswordRequest(
        email: email,
        otpCode: otpCode,
        newPassword: newPassword,
        newPasswordConfirm: newPasswordConfirm,
        resetToken: resetToken,
      );

      await _apiService.resetPassword(request);
      Logger.info('HybridAuth', 'Password reset successful on backend');
      
      // Step 2: Update password hash in local database
      Logger.info('HybridAuth', 'Updating password hash in local database');
      final newPasswordHash = _hashPassword(newPassword);
      Logger.debug('HybridAuth', 'Generated new password hash: ${newPasswordHash.substring(0, 16)}... (length: ${newPasswordHash.length})');
      
      // Find user in local database
      final results = await _dbService.select(
        'tailor',
        where: 'email = ? AND is_deleted = 0',
        whereArgs: [email.trim()],
      );
      
      if (results.isNotEmpty) {
        Logger.info('HybridAuth', 'User found in local DB, updating password hash');
        
        // Update password hash locally
        await _dbService.update(
          'tailor',
          {
            'password_hash': newPasswordHash,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'email = ? AND is_deleted = 0',
          whereArgs: [email.trim()],
        );
        Logger.info('HybridAuth', 'Password hash updated in local database');
        
        // Verify the update
        final verifyResults = await _dbService.select(
          'tailor',
          where: 'email = ? AND is_deleted = 0',
          whereArgs: [email.trim()],
        );
        if (verifyResults.isNotEmpty) {
          final savedHash = verifyResults.first['password_hash'] as String;
          Logger.debug('HybridAuth', 'Verified password hash in DB: ${savedHash.substring(0, 16)}... (length: ${savedHash.length})');
          Logger.info('HybridAuth', '✅ Local password hash successfully updated and verified');
        }
      } else {
        Logger.warning('HybridAuth', 'User not found in local database, password hash not updated locally');
      }
      
      Logger.info('HybridAuth', '✅ Password reset complete (API + Local DB synced)');
      return true;
    } catch (e) {
      Logger.error('HybridAuth', 'Password reset failed', error: e);
      rethrow;
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Sync Tailor data to local SQLite database
  Future<void> _syncTailorToLocalDB(Tailor tailor) async {
    try {
      Logger.info('HybridAuth', 'Syncing tailor to local DB: ${tailor.email}');
      Logger.debug('HybridAuth', 'Tailor passwordHash to sync: "${tailor.passwordHash.isEmpty ? "EMPTY" : tailor.passwordHash.substring(0, 16)}"... (length: ${tailor.passwordHash.length})');

      // Check if tailor already exists in local DB
      final existing = await _dbService.select(
        'tailor',
        where: 'id = ?',
        whereArgs: [tailor.id],
      );

      final tailorMap = tailor.toMap();
      Logger.debug('HybridAuth', 'Tailor map password_hash: "${tailorMap['password_hash']}"');

      if (existing.isNotEmpty) {
        // Update existing record
        await _dbService.update(
          'tailor',
          tailorMap,
          where: 'id = ?',
          whereArgs: [tailor.id],
        );
        Logger.info('HybridAuth', 'Updated existing tailor in local DB');
      } else {
        // Insert new record
        await _dbService.insertTailor(tailor);
        Logger.info('HybridAuth', 'Inserted new tailor into local DB');
      }
      
      // Verify what was actually saved
      final saved = await _dbService.select(
        'tailor',
        where: 'id = ?',
        whereArgs: [tailor.id],
      );
      if (saved.isNotEmpty) {
        final savedHash = saved.first['password_hash'] as String;
        Logger.debug('HybridAuth', 'Verified saved password_hash: "${savedHash.isEmpty ? "EMPTY" : savedHash.substring(0, 16)}"... (length: ${savedHash.length})');
      }
    } catch (e) {
      Logger.error('HybridAuth', 'Error syncing to local DB', error: e);
      // Don't rethrow - local DB sync failure shouldn't break authentication
    }
  }

  /// Load Tailor from local database
  Future<Tailor?> _loadTailorFromLocalDB(String tailorId) async {
    try {
      final results = await _dbService.select(
        'tailor',
        where: 'id = ? AND is_deleted = 0',
        whereArgs: [tailorId],
      );

      if (results.isNotEmpty) {
        return Tailor.fromMap(results.first);
      }
      return null;
    } catch (e) {
      Logger.error('HybridAuth', 'Error loading from local DB', error: e);
      return null;
    }
  }

  /// Validate registration input
  void _validateRegistrationInput(
    String name,
    String shopName,
    String email,
    String password,
    String passwordConfirm,
  ) {
    Map<String, String> errors = {};

    if (name.trim().isEmpty) {
      errors['name'] = 'Name is required';
    } else if (name.length < 2) {
      errors['name'] = 'Name must be at least 2 characters';
    }

    if (shopName.trim().isEmpty) {
      errors['shopName'] = 'Shop name is required';
    } else if (shopName.length < 2) {
      errors['shopName'] = 'Shop name must be at least 2 characters';
    }

    if (email.trim().isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      errors['email'] = 'Invalid email format';
    }

    if (password.isEmpty) {
      errors['password'] = 'Password is required';
    } else if (password.length < 8) {
      errors['password'] = 'Password must be at least 8 characters';
    }

    if (password != passwordConfirm) {
      errors['passwordConfirm'] = 'Passwords do not match';
    }

    if (errors.isNotEmpty) {
      throw ValidationException(fieldErrors: errors);
    }
  }

  /// Get current user from backend (and update local DB)
  Future<Tailor?> getCurrentUserFromBackend() async {
    try {
      final user = await _apiService.getCurrentUser();
      await _syncTailorToLocalDB(user);
      _currentTailor = user;
      return user;
    } catch (e) {
      Logger.error('HybridAuth', 'Error getting current user', error: e);
      return null;
    }
  }

  /// Check if email exists in backend
  Future<bool> checkEmailExists(String email) async {
    try {
      return await _apiService.checkEmailExists(email);
    } catch (e) {
      Logger.error('HybridAuth', 'Error checking email', error: e);
      return false;
    }
  }

  /// Resend OTP
  Future<bool> resendOTP(String email) async {
    try {
      Logger.info('HybridAuth', 'Resending OTP to: $email');
      await _apiService.resendOTP(email);
      return true;
    } catch (e) {
      Logger.error('HybridAuth', 'Error resending OTP', error: e);
      rethrow;
    }
  }

  /// Hash password using SHA256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
