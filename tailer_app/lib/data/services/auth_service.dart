import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import '../repositories/tailor_auth_repository.dart';
import '../models/tailor_model.dart';
import '../../core/exceptions/auth_exceptions.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final TailorAuthRepository _tailorAuthRepository = TailorAuthRepository();
  
  Tailor? _currentTailor;
  bool _rememberMe = false;
  
  Tailor? get currentTailor => _currentTailor;
  Tailor? get currentUser => _currentTailor;
  bool get isAuthenticated => _currentTailor != null;
  bool get isLoggedIn => isAuthenticated;
  String? get currentUserEmail => _currentTailor?.email;
  String? get currentTailorEmail => _currentTailor?.email;
  bool get keepSignedIn => _rememberMe;

  Future<void> initialize() async {
    try {
      debugPrint('AuthService: Initializing...');
      final isLoggedIn = await _tailorAuthRepository.isLoggedIn();
      if (isLoggedIn) {
        _currentTailor = await _tailorAuthRepository.getCurrentTailor();
        if (_currentTailor != null) {
          debugPrint('AuthService: Tailor authenticated - ');
        }
      }
    } catch (e) {
      debugPrint('AuthService: Error during initialization: ');
      await signOut();
    }
  }

  Future<Tailor> signUpNewTailor({
    required String name,
    required String shopName,
    required String email,
    required String phone,
    required String password,
    String address = '',
  }) async {
    try {
      _validateSignUpInput(name, shopName, email, password);
      final tailor = await _tailorAuthRepository.signUp(
        name: name,
        shopName: shopName,
        email: email,
        phone: phone,
        password: password,
        address: address,
        authProvider: 'email',
      );
      return tailor;
    } catch (e) {
      debugPrint('AuthService: Sign up failed: ');
      rethrow;
    }
  }

  Future<Tailor> signUpNewUser({
    required String username,
    required String email,
    required String password,
    String? phone,
  }) async {
    return signUpNewTailor(
      name: username,
      shopName: '\'s Shop',
      email: email,
      phone: phone ?? '',
      password: password,
      address: '',
    );
  }

  Future<bool> signInAfterRegistration({
    required String email,
    required String password,
  }) async {
    try {
      return await signIn(email: email, password: password, keepSignedIn: true);
    } catch (e) {
      debugPrint('AuthService: Auto sign-in failed: ');
      return false;
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      return await _tailorAuthRepository.checkEmailExists(email);
    } catch (e) {
      debugPrint('AuthService: Error checking email existence: ');
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
    bool keepSignedIn = false,
  }) async {
    try {
      if (email.trim().isEmpty || password.isEmpty) {
        throw ValidationException(
          fieldErrors: {
            if (email.trim().isEmpty) 'email': 'Email is required',
            if (password.isEmpty) 'password': 'Password is required',
          },
        );
      }

      final tailor = await _tailorAuthRepository.signIn(
        email: email,
        password: password,
        rememberMe: keepSignedIn,
      );

      _currentTailor = tailor;
      _rememberMe = keepSignedIn;
      debugPrint('AuthService: Sign in successful for ');
      return true;
    } catch (e) {
      debugPrint('AuthService: Sign in failed: ');
      throw AuthExceptionHelper.fromException(e);
    }
  }

  Future<void> signOut({bool clearRememberMe = false}) async {
    try {
      await _tailorAuthRepository.signOut();
      _currentTailor = null;
      if (clearRememberMe) {
        _rememberMe = false;
      }
    } catch (e) {
      debugPrint('AuthService: Error during sign out: ');
      rethrow;
    }
  }

  Future<bool> sendForgotPasswordEmail(String email) async {
    try {
      if (email.trim().isEmpty || !_isValidEmail(email)) {
        throw ValidationException(fieldErrors: {'email': 'Invalid email address'});
      }

      final emailExists = await _tailorAuthRepository.checkEmailExists(email);
      if (!emailExists) {
        throw UserNotFoundException(
          email: email.trim(),
          details: 'Email lookup failed during forgot password request',
        );
      }

      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      debugPrint('AuthService: Forgot password error: ');
      rethrow;
    }
  }

  final Map<String, String> _otpStorage = {};

  String generateTestOTP({String? email}) {
    final random = DateTime.now().millisecondsSinceEpoch % 9000 + 1000;
    final otp = random.toString();
    if (email != null) {
      _otpStorage[email] = otp;
    }
    debugPrint(' Generated Test OTP:  ');
    return otp;
  }

  Future<String> sendOTPToEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final otp = generateTestOTP(email: email);
    debugPrint(' OTP sent to: ');
    return otp;
  }

  Future<bool> verifyOTP(String otp, String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final storedOTP = _otpStorage[email];
    if (otp.length == 4 && storedOTP != null && otp == storedOTP) {
      debugPrint(' OTP verified successfully');
      _otpStorage.remove(email);
      return true;
    }
    debugPrint(' Invalid OTP');
    return false;
  }

  Future<bool> resetPassword({
    required String newPassword,
    required String confirmPassword,
    String? email,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (newPassword.length >= 6 && newPassword == confirmPassword) {
      debugPrint('Password reset successfully for: ');
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
  }

  Future<Tailor> updateProfile({
    String? name,
    String? shopName,
    String? phone,
    String? address,
  }) async {
    try {
      if (_currentTailor == null) {
        throw Exception('Tailor not authenticated');
      }

      final updatedTailor = _currentTailor!.copyWith(
        name: name,
        shopName: shopName,
        phone: phone,
        address: address,
      );

      final result = await _tailorAuthRepository.updateProfile(updatedTailor);
      _currentTailor = result;
      return result;
    } catch (e) {
      debugPrint('AuthService: Error updating profile: ');
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (_currentTailor == null) {
        throw Exception('Tailor not authenticated');
      }

      _validatePassword(newPassword);

      await _tailorAuthRepository.changePassword(
        email: _currentTailor!.email,
        oldPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      debugPrint('AuthService: Error changing password: ');
      rethrow;
    }
  }

  Future<void> setKeepLoggedIn(bool keepLoggedIn) async {
    _rememberMe = keepLoggedIn;
  }

  void _validateSignUpInput(String name, String shopName, String email, String password) {
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
    
    try {
      _validatePassword(password);
    } catch (e) {
      if (e is ValidationException) {
        errors.addAll(e.fieldErrors);
      }
    }
    
    if (errors.isNotEmpty) {
      throw ValidationException(fieldErrors: errors);
    }
  }

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

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}');
    return emailRegex.hasMatch(email);
  }

  void reset() {
    _currentTailor = null;
    _rememberMe = false;
  }

  Future<bool> signInWithSocial({
    required String email,
    required String provider,
    required String providerId,
    required String name,
  }) async {
    try {
      final exists = await _tailorAuthRepository.checkEmailExists(email);
      if (exists) {
        final tailor = await _tailorAuthRepository.getCurrentTailor();
        if (tailor != null && tailor.email == email) {
          _currentTailor = tailor;
          _rememberMe = true;
          debugPrint('AuthService: Social sign in successful for  via ');
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('AuthService: Social sign in failed: ');
      return false;
    }
  }

  Future<bool> registerWithSocial({
    required String email,
    required String name,
    required String provider,
    required String providerId,
    String? photoUrl,
    required String shopName,
    String address = '',
  }) async {
    try {
      final tailor = await _tailorAuthRepository.signUp(
        name: name,
        shopName: shopName,
        email: email,
        phone: '',
        password: _generateSocialPassword(providerId),
        address: address,
        authProvider: provider,
      );
      
      _currentTailor = tailor;
      _rememberMe = true;
      debugPrint('AuthService: Social registration successful for  via ');
      return true;
    } catch (e) {
      debugPrint('AuthService: Social registration failed: ');
      return false;
    }
  }

  String _generateSocialPassword(String providerId) {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(bytes) + providerId;
  }
}
