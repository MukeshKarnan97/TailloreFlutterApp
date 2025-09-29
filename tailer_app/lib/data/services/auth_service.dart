import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../models/user_model.dart';
import '../models/auth_session_model.dart';
import '../models/user_preferences_model.dart';
import '../../core/exceptions/auth_exceptions.dart';

/// AuthService - High-level authentication service
/// 
/// This service provides a clean API for authentication operations,
/// combining the repository layer with business logic and state management.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final AuthRepository _authRepository = AuthRepository();
  final UserRepository _userRepository = UserRepository();

  // Current user state
  UserModel? _currentUser;
  AuthSessionModel? _currentSession;
  UserPreferencesModel? _currentPreferences;

  // Getters for current state
  UserModel? get currentUser => _currentUser;
  AuthSessionModel? get currentSession => _currentSession;
  UserPreferencesModel? get currentPreferences => _currentPreferences;
  bool get isAuthenticated => _currentUser != null && _currentSession != null;

  // Legacy compatibility getters
  bool get isLoggedIn => isAuthenticated;
  String? get currentUserEmail => _currentUser?.email;
  bool get keepSignedIn => _currentPreferences?.rememberMe ?? false;

  // ==================== AUTHENTICATION METHODS ====================

  /// Initialize the auth service (call on app startup)
  Future<void> initialize() async {
    try {
      debugPrint('AuthService: Initializing...');
      
      // Check if user is already logged in
      final isLoggedIn = await _authRepository.isLoggedIn();
      debugPrint('AuthService: Repository isLoggedIn check returned: $isLoggedIn');
      
      if (isLoggedIn) {
        debugPrint('AuthService: Loading user data...');
        
        // Load current user data
        _currentUser = await _authRepository.getCurrentUser();
        _currentSession = await _authRepository.getCurrentSession();
        
        debugPrint('AuthService: Current user: ${_currentUser?.email}');
        debugPrint('AuthService: Current session exists: ${_currentSession != null}');
        
        if (_currentUser != null) {
          _currentPreferences = await _userRepository.getPreferences(_currentUser!.id!);
          debugPrint('AuthService: User authenticated - ${_currentUser!.email}');
          debugPrint('AuthService: Remember me preference: ${_currentPreferences?.rememberMe}');
        }

        // Check if session needs refresh
        if (_currentSession != null && _currentSession!.needsRefresh) {
          debugPrint('AuthService: Session needs refresh');
          await refreshSession();
        }

        // Check for auto-logout
        await _checkAutoLogout();
      } else {
        debugPrint('AuthService: No user currently logged in');
      }
      
      debugPrint('AuthService: Initialization complete - isAuthenticated: $isAuthenticated, keepSignedIn: $keepSignedIn');
    } catch (e) {
      debugPrint('AuthService: Error during initialization: $e');
      await signOut(); // Clear potentially corrupted state
    }
  }

  /// Sign up a new user
  Future<UserModel> signUpNewUser({
    required String username,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      debugPrint('AuthService: Starting sign up for $email');

      // Validate input
      _validateSignUpInput(username, email, password);

      // Create user account
      final user = await _authRepository.signUp(
        username: username,
        email: email,
        password: password,
        phone: phone,
      );

      debugPrint('AuthService: Sign up successful for ${user.email}');
      return user;
    } catch (e) {
      debugPrint('AuthService: Sign up failed: $e');
      rethrow;
    }
  }

  
  /// Check if an email already exists in the system
  Future<bool> checkEmailExists(String email) async {
    try {
      debugPrint(' Checking if email exists: ');
      
      // Simulate API call - replace with actual implementation
      await Future.delayed(const Duration(milliseconds: 500));
      
      // For demo purposes, let's say admin@gmail.com already exists
      final existingEmails = ['admin@gmail.com', 'test@test.com', 'user@example.com'];
      
      bool exists = existingEmails.any((existingEmail) => 
        existingEmail.toLowerCase() == email.toLowerCase());
      
      debugPrint(' Email  exists: ');
      return exists;
    } catch (e) {
      debugPrint(' Error checking email existence: ');
      // In case of error, assume email doesn't exist to avoid blocking user
      return false;
    }
  }/// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
    bool keepSignedIn = false,
  }) async {
    try {
      debugPrint('AuthService: Starting sign in for $email');

      // Validate input
      if (email.trim().isEmpty || password.isEmpty) {
        throw ValidationException(
          fieldErrors: {
            if (email.trim().isEmpty) 'email': 'Email is required',
            if (password.isEmpty) 'password': 'Password is required',
          },
        );
      }

      // Attempt authentication
      final session = await _authRepository.signIn(
        emailOrUsername: email,
        password: password,
        rememberMe: keepSignedIn,
        deviceInfo: await _getDeviceInfo(),
      );

      // Load user data and preferences
      await _loadUserData(session.userId);

      // Ensure login status is properly set if keepSignedIn is true
      if (keepSignedIn) {
        debugPrint('AuthService: Setting keep logged in preference after successful sign in');
        await setKeepLoggedIn(true);
      }

      debugPrint('AuthService: Sign in successful for ${_currentUser!.email}');
      debugPrint('AuthService: Keep signed in: $keepSignedIn');
      debugPrint('AuthService: Current auth state - isAuthenticated: $isAuthenticated, keepSignedIn: $keepSignedIn');
      return true;
    } catch (e) {
      debugPrint('AuthService: Sign in failed: $e');
      // Convert generic exceptions to specific AuthExceptions
      throw AuthExceptionHelper.fromException(e);
    }
  }

  /// Sign out current user
  Future<void> signOut({bool clearRememberMe = false}) async {
    try {
      debugPrint('AuthService: Signing out user');
      
      await _authRepository.signOut(clearRememberMe: clearRememberMe);
      
      // Clear local state
      _currentUser = null;
      _currentSession = null;
      _currentPreferences = null;

      debugPrint('AuthService: Sign out complete');
    } catch (e) {
      debugPrint('AuthService: Error during sign out: $e');
      rethrow;
    }
  }

  /// Refresh current session
  Future<bool> refreshSession() async {
    try {
      final refreshedSession = await _authRepository.refreshSession();
      
      if (refreshedSession != null) {
        _currentSession = refreshedSession;
        debugPrint('AuthService: Session refreshed successfully');
        return true;
      }
      
      debugPrint('AuthService: Session refresh failed, signing out');
      await signOut();
      return false;
    } catch (e) {
      debugPrint('AuthService: Error refreshing session: $e');
      await signOut();
      return false;
    }
  }

  // ==================== OTP AND PASSWORD METHODS ====================

  /// Send forgot password email
  Future<bool> sendForgotPasswordEmail(String email) async {
    try {
      debugPrint('AuthService: Checking forgot password request for: $email');
      
      // Validate email format first
      if (email.trim().isEmpty || !_isValidEmail(email)) {
        throw ValidationException(fieldErrors: {'email': 'Invalid email address'});
      }

      // Check if email exists in database
      final user = await _userRepository.getUserByEmail(email.trim());
      if (user == null) {
        debugPrint('AuthService: Email not found in database: $email');
        throw UserNotFoundException(
          email: email.trim(),
          details: 'Email lookup failed during forgot password request',
        );
      }

      // Simulate sending email (replace with actual email service)
      await Future.delayed(const Duration(milliseconds: 500));
      
      debugPrint('AuthService: Password reset email sent to: $email (User ID: ${user.id})');
      return true;
    } catch (e) {
      debugPrint('AuthService: Forgot password error: $e');
      rethrow;
    }
  }

  // Store OTPs for different emails
  final Map<String, String> _otpStorage = {};
  
  /// Generate and return OTP for testing
  String generateTestOTP({String? email}) {
    // Generate a random 4-digit OTP for development
    final random = DateTime.now().millisecondsSinceEpoch % 9000 + 1000;
    final otp = random.toString();
    
    // Store OTP for specific email if provided
    if (email != null) {
      _otpStorage[email] = otp;
    }
    
    debugPrint('🔐 Generated Test OTP: $otp ${email != null ? 'for $email' : ''}');
    debugPrint('📱 Use this OTP for verification: $otp');
    return otp;
  }
  
  /// Send OTP to email for verification
  Future<String> sendOTPToEmail(String email) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Generate OTP for this email
      final otp = generateTestOTP(email: email);
      
      debugPrint('📧 OTP sent to: $email');
      debugPrint('🔐 OTP: $otp');
      
      return otp;
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      throw OtpSendException();
    }
  }

  /// Verify OTP
  Future<bool> verifyOTP(String otp, String email) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check if we have a stored OTP for this email
      final storedOTP = _otpStorage[email];
      
      // Also accept fallback OTP for development
      const fallbackOTP = '1234';
      
      if (otp == storedOTP || otp == fallbackOTP) {
        debugPrint('✅ OTP verified successfully for: $email');
        
        // Clear the used OTP
        _otpStorage.remove(email);
        
        return true;
      } else {
        debugPrint('❌ Invalid OTP entered: $otp (Expected: $storedOTP or $fallbackOTP)');
        throw OtpVerificationException();
      }
    } catch (e) {
      debugPrint('OTP verification error: $e');
      rethrow;
    }
  }

  /// Reset password with new password
  Future<bool> resetPassword({
    required String newPassword,
    required String confirmPassword,
    String? email,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (newPassword.length >= 6 && newPassword == confirmPassword) {
        debugPrint('Password reset successfully for: ${email ?? currentUserEmail}');
        return true;
      } else {
        Map<String, String> errors = {};
        if (newPassword.length < 6) {
          errors['newPassword'] = 'Password must be at least 6 characters';
        }
        if (newPassword != confirmPassword) {
          errors['confirmPassword'] = 'Passwords do not match';
        }
        throw ValidationException(fieldErrors: errors);
      }
    } catch (e) {
      debugPrint('Password reset error: $e');
      rethrow;
    }
  }

  // ==================== USER PROFILE METHODS ====================

  /// Update user profile
  Future<UserModel> updateProfile({
    String? username,
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
    String? profilePicture,
    String? bio,
  }) async {
    try {
      if (_currentUser == null) {
        throw Exception('User not authenticated');
      }

      final updatedUser = await _userRepository.updateProfile(
        userId: _currentUser!.id!,
        username: username,
        email: email,
        phone: phone,
        firstName: firstName,
        lastName: lastName,
        profilePicture: profilePicture,
        bio: bio,
      );

      if (updatedUser != null) {
        _currentUser = updatedUser;
        debugPrint('AuthService: Profile updated successfully');
      }

      return updatedUser!;
    } catch (e) {
      debugPrint('AuthService: Error updating profile: $e');
      rethrow;
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (_currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Validate new password
      _validatePassword(newPassword);

      await _authRepository.changePassword(
        userId: _currentUser!.id!,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      debugPrint('AuthService: Password changed successfully');
    } catch (e) {
      debugPrint('AuthService: Error changing password: $e');
      rethrow;
    }
  }

  /// Update "Keep me logged in" preference
  Future<void> setKeepLoggedIn(bool keepLoggedIn) async {
    try {
      if (_currentUser == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('AuthService: Updating keep logged in preference to: $keepLoggedIn');

      // Update user preferences in database
      _currentPreferences = await _userRepository.updatePreferences(
        userId: _currentUser!.id!,
        rememberMe: keepLoggedIn,
      );

      // Update storage service remember me flag
      await _authRepository.updateRememberMe(keepLoggedIn);

      debugPrint('AuthService: Keep logged in preference updated successfully');
      debugPrint('AuthService: Verification - isAuthenticated: $isAuthenticated, keepSignedIn: $keepSignedIn');
    } catch (e) {
      debugPrint('AuthService: Error updating keep logged in preference: $e');
      rethrow;
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      return await _userRepository.isUsernameAvailable(username);
    } catch (e) {
      debugPrint('AuthService: Error checking username availability: $e');
      return false;
    }
  }



  /// Check if email is available
  Future<bool> isEmailAvailable(String email) async {
    try {
      return await _userRepository.isEmailAvailable(email);
    } catch (e) {
      debugPrint('AuthService: Error checking email availability: $e');
      return false;
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Load user data and preferences
  Future<void> _loadUserData(int userId) async {
    _currentUser = await _authRepository.getCurrentUser();
    _currentSession = await _authRepository.getCurrentSession();
    _currentPreferences = await _userRepository.getPreferences(userId);
  }

  /// Check for auto-logout
  Future<void> _checkAutoLogout() async {
    final shouldLogout = await _authRepository.shouldAutoLogout();
    if (shouldLogout) {
      _currentUser = null;
      _currentSession = null;
      _currentPreferences = null;
    }
  }

  /// Get device information (simple implementation)
  Future<String> _getDeviceInfo() async {
    try {
      // For now, return a simple device identifier
      return 'Flutter App - ${defaultTargetPlatform.name}';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  /// Validate sign up input
  void _validateSignUpInput(String username, String email, String password) {
    Map<String, String> errors = {};
    
    if (username.trim().isEmpty) {
      errors['username'] = 'Username is required';
    } else if (username.length < 3) {
      errors['username'] = 'Username must be at least 3 characters';
    }
    
    if (email.trim().isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      errors['email'] = 'Invalid email format';
    }
    
    try {
      _validatePassword(password);
    } catch (e) {
      if (e is ValidationException) {
        errors.addAll(e.fieldErrors);
      } else {
        errors['password'] = e.toString();
      }
    }
    
    if (errors.isNotEmpty) {
      throw ValidationException(fieldErrors: errors);
    }
  }

  /// Validate password strength
  void _validatePassword(String password) {
    Map<String, String> errors = {};
    
    if (password.isEmpty) {
      errors['password'] = 'Password is required';
    } else if (password.length < 6) {
      errors['password'] = 'Password must be at least 6 characters';
    }
    
    if (errors.isNotEmpty) {
      throw ValidationException(fieldErrors: errors);
    }
  }

  /// Email validation helper
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}");
    return emailRegex.hasMatch(email);
  }

  /// Clean up expired sessions
  Future<void> cleanupExpiredSessions() async {
    try {
      await _authRepository.cleanupExpiredSessions();
      debugPrint('AuthService: Expired sessions cleaned up');
    } catch (e) {
      debugPrint('AuthService: Error cleaning up expired sessions: $e');
    }
  }

  /// Reset auth service (for testing or logout)
  void reset() {
    _currentUser = null;
    _currentSession = null;
    _currentPreferences = null;
  }
  /// Sign in with social provider (Google, Facebook)
  Future<bool> signInWithSocial({
    required String email,
    required String provider,
    required String providerId,
    required String name,
  }) async {
    try {
      debugPrint(' Social sign in attempt - Provider: , Email: ');
      
      // Simulate API call to your backend
      await Future.delayed(const Duration(milliseconds: 800));
      
      // In a real app, send social auth data to your backend
      // Your backend should verify the social token and create/login the user
      
      debugPrint('? Social sign in successful for  via ');
      return true;
    } catch (e) {
      debugPrint('? Social sign in failed: ');
      return false;
    }
  }

  /// Register with social provider (Google, Facebook)
  Future<bool> registerWithSocial({
    required String email,
    required String name,
    required String provider,
    required String providerId,
    String? photoUrl,
  }) async {
    try {
      debugPrint('?? Social registration attempt - Provider: , Email: ');
      
      // Simulate API call to your backend
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // In a real app, send social auth data to your backend to create new user
      // Your backend should:
      // 1. Verify the social token
      // 2. Create user account with social provider data
      // 3. Return authentication token
      
      debugPrint(' Social registration successful for  via ');
      debugPrint(' User name: ');
      if (photoUrl != null) {
        debugPrint(' Photo URL: ');
      }
      
      return true;
    } catch (e) {
      debugPrint(' Social registration failed: ');
      return false;
    }
  }

}



