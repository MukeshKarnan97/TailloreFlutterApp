/// Authentication Request & Response Models
library;

import 'package:tailer_app/data/models/tailor_model.dart';

// ==================== LOGIN ====================

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class LoginResponse {
  final Tailor user;
  final String accessToken;
  final String refreshToken;

  const LoginResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: Tailor.fromMap(json['user']),
      accessToken: json['tokens']['access'],
      refreshToken: json['tokens']['refresh'],
    );
  }
}

// ==================== REGISTER ====================

class RegisterRequest {
  final String email;
  final String password;
  final String passwordConfirm;
  final String name;
  final String shopName;
  final String phone;
  final String address;
  final String authProvider;

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.passwordConfirm,
    required this.name,
    required this.shopName,
    required this.phone,
    this.address = '',
    this.authProvider = 'email',
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'password_confirm': passwordConfirm,
      'name': name,
      'shop_name': shopName,
      'phone': phone,
      'address': address,
      'auth_provider': authProvider,
    };
  }
}

class RegisterResponse {
  final Tailor user;
  final String accessToken;
  final String refreshToken;
  final String? message;

  const RegisterResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.message,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    // Handle both response formats:
    // 1. Direct format: {"user": {...}, "tokens": {...}}
    // 2. Wrapped format: {"success": true, "data": {"tailor": {...}, "tokens": {...}}}
    
    final Map<String, dynamic> userData;
    final Map<String, dynamic> tokensData;
    final String? msg;
    
    if (json.containsKey('data')) {
      // Wrapped format from Django
      final data = json['data'] as Map<String, dynamic>;
      userData = data['tailor'] as Map<String, dynamic>;
      tokensData = data['tokens'] as Map<String, dynamic>;
      msg = json['message'] as String?;
    } else {
      // Direct format
      userData = json['user'] as Map<String, dynamic>;
      tokensData = json['tokens'] as Map<String, dynamic>;
      msg = json['message'] as String?;
    }
    
    return RegisterResponse(
      user: Tailor.fromMap(userData),
      accessToken: tokensData['access'] as String,
      refreshToken: tokensData['refresh'] as String,
      message: msg,
    );
  }
}

// ==================== TOKEN REFRESH ====================

class RefreshTokenRequest {
  final String refreshToken;

  const RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {
      'refresh': refreshToken,
    };
  }
}

class RefreshTokenResponse {
  final String accessToken;
  final String? refreshToken; // May or may not rotate

  const RefreshTokenResponse({
    required this.accessToken,
    this.refreshToken,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      accessToken: json['access'],
      refreshToken: json['refresh'],
    );
  }
}

// ==================== PASSWORD CHANGE ====================

class ChangePasswordRequest {
  final String oldPassword;
  final String newPassword;
  final String newPasswordConfirm;

  const ChangePasswordRequest({
    required this.oldPassword,
    required this.newPassword,
    required this.newPasswordConfirm,
  });

  Map<String, dynamic> toJson() {
    return {
      'old_password': oldPassword,
      'new_password': newPassword,
      'new_password_confirm': newPasswordConfirm,
    };
  }
}

// ==================== OTP VERIFICATION ====================

class VerifyOTPRequest {
  final String email;
  final String otpCode;
  final String otpType;

  const VerifyOTPRequest({
    required this.email,
    required this.otpCode,
    this.otpType = 'registration',
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp_code': otpCode,
      'otp_type': otpType,
    };
  }
}

class VerifyOTPResponse {
  final bool success;
  final String message;
  final Tailor? user; // Made optional since Django may not return user data

  const VerifyOTPResponse({
    required this.success,
    required this.message,
    this.user, // Optional
  });

  factory VerifyOTPResponse.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw const FormatException('VerifyOTPResponse JSON cannot be null');
    }

    // Handle both response formats:
    // 1. Direct format: {"success": true, "message": "...", "user": {...}}
    // 2. Wrapped format: {"success": true, "data": {"tailor": {...}}, "message": "..."}
    // 3. Minimal format: {"success": true, "message": "..."} (Django without user data)
    
    final Map<String, dynamic>? userData;
    final bool isSuccess;
    final String msg;
    
    if (json.containsKey('data') && json['data'] != null) {
      // Wrapped format from Django
      final data = json['data'] as Map<String, dynamic>?;
      userData = data?['tailor'] as Map<String, dynamic>? ?? 
                 data?['user'] as Map<String, dynamic>?;
      isSuccess = json['success'] ?? true;
      msg = json['message'] ?? 'OTP verified successfully';
    } else {
      // Direct format or minimal format
      userData = json['user'] as Map<String, dynamic>? ?? 
                 json['tailor'] as Map<String, dynamic>?;
      isSuccess = json['success'] ?? true;
      msg = json['message'] ?? 'OTP verified successfully';
    }
    
    // User data is now optional - Django may not return it
    return VerifyOTPResponse(
      success: isSuccess,
      message: msg,
      user: userData != null ? Tailor.fromMap(userData) : null,
    );
  }
}

class ResendOTPRequest {
  final String email;
  final String otpType;

  const ResendOTPRequest({
    required this.email,
    this.otpType = 'registration',
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp_type': otpType,
    };
  }
}

// ==================== PASSWORD RESET ====================

class ForgotPasswordRequest {
  final String email;

  const ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}

class ResetPasswordRequest {
  final String email;
  final String otpCode;
  final String newPassword;
  final String newPasswordConfirm;
  final String resetToken; // Token from forgot password API

  const ResetPasswordRequest({
    required this.email,
    required this.otpCode,
    required this.newPassword,
    required this.newPasswordConfirm,
    required this.resetToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp_code': otpCode,
      'new_password': newPassword,
      'confirm_password': newPasswordConfirm,
      'reset_token': resetToken,
    };
  }
}

// ==================== UPDATE USER ====================

class UpdateUserRequest {
  final String? name;
  final String? shopName;
  final String? phone;
  final String? address;

  const UpdateUserRequest({
    this.name,
    this.shopName,
    this.phone,
    this.address,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (shopName != null) data['shop_name'] = shopName;
    if (phone != null) data['phone'] = phone;
    if (address != null) data['address'] = address;
    return data;
  }
}

// ==================== EMAIL VERIFICATION ====================

class EmailVerificationRequest {
  final String token;

  const EmailVerificationRequest({required this.token});

  Map<String, dynamic> toJson() {
    return {
      'token': token,
    };
  }
}

// ==================== API RESPONSE WRAPPER ====================

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? errors;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? json['detail'],
      data: fromJsonT != null && json['data'] != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      errors: json['errors'],
    );
  }
}

// ==================== SOCIAL AUTHENTICATION ====================

class GoogleAuthRequest {
  final String idToken;
  final String? accessToken;
  final String? serverAuthCode;

  const GoogleAuthRequest({
    required this.idToken,
    this.accessToken,
    this.serverAuthCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_token': idToken,
      'access_token': accessToken,
      'server_auth_code': serverAuthCode,
    };
  }
}

class FacebookAuthRequest {
  final String accessToken;
  final String userId;

  const FacebookAuthRequest({
    required this.accessToken,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'user_id': userId,
    };
  }
}

class SocialAuthResponse {
  final Tailor user;
  final String accessToken;
  final String refreshToken;
  final bool isNewUser;
  final String? message;

  const SocialAuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.isNewUser = false,
    this.message,
  });

  factory SocialAuthResponse.fromJson(Map<String, dynamic> json) {
    // Handle both response formats:
    // 1. Direct format: {"user": {...}, "tokens": {...}}
    // 2. Wrapped format: {"success": true, "data": {"tailor": {...}, "tokens": {...}}}
    
    final Map<String, dynamic> userData;
    final Map<String, dynamic> tokensData;
    final bool newUser;
    final String? msg;
    
    if (json.containsKey('data')) {
      // Wrapped format from Django
      final data = json['data'] as Map<String, dynamic>;
      userData = data['tailor'] as Map<String, dynamic>? ?? 
                 data['user'] as Map<String, dynamic>;
      tokensData = data['tokens'] as Map<String, dynamic>;
      newUser = data['is_new_user'] ?? false;
      msg = json['message'] as String?;
    } else {
      // Direct format
      userData = json['user'] as Map<String, dynamic>? ?? 
                 json['tailor'] as Map<String, dynamic>;
      tokensData = json['tokens'] as Map<String, dynamic>;
      newUser = json['is_new_user'] ?? false;
      msg = json['message'] as String?;
    }
    
    return SocialAuthResponse(
      user: Tailor.fromMap(userData),
      accessToken: tokensData['access'] as String,
      refreshToken: tokensData['refresh'] as String,
      isNewUser: newUser,
      message: msg,
    );
  }
}
