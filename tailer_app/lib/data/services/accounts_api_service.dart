/// Accounts API Service
/// Handles all account-related API calls (auth, user management, preferences)
library;

import 'package:tailer_app/core/config/api_config.dart';
import 'package:tailer_app/core/services/api_client.dart';
import 'package:tailer_app/core/services/token_storage_service.dart';
import 'package:tailer_app/core/utils/logger.dart';
import 'package:tailer_app/data/models/tailor_model.dart';
import 'package:tailer_app/data/models/account/auth_models.dart';

class AccountsApiService {
  final ApiClient _apiClient;
  final TokenStorageService _tokenStorage;

  AccountsApiService({
    ApiClient? apiClient,
    TokenStorageService? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorageService();

  // ==================== AUTHENTICATION ====================

  /// Register a new user
  ///
  /// POST /api/v1/accounts/auth/register/
  ///
  /// Returns [RegisterResponse] with user data and tokens
  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      Logger.api('🔐 Registering user: ${request.email}');

      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: request.toJson(),
      );

      if (response.statusCode == HttpStatusCode.created) {
        final registerResponse = RegisterResponse.fromJson(response.data);

        // Save tokens
        await _tokenStorage.saveTokens(
          accessToken: registerResponse.accessToken,
          refreshToken: registerResponse.refreshToken,
        );

        // Save user data
        await _tokenStorage.saveUserId(registerResponse.user.id);
        await _tokenStorage.saveUserEmail(registerResponse.user.email);
        await _tokenStorage.saveUserType('tailor');
        await _tokenStorage.saveLoginState(true);
        await _tokenStorage.saveLastLoginDate();

        Logger.info('AccountsApi', '✅ User registered successfully: ${request.email}');
        return registerResponse;
      } else {
        throw ApiException(
          message: 'Registration failed',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } catch (e) {
      Logger.error('AccountsApi', 'Registration failed', error: e);
      rethrow;
    }
  }

  /// Login user
  ///
  /// POST /api/v1/accounts/auth/login/
  ///
  /// Returns [LoginResponse] with user data and tokens
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      Logger.api('🔐 Logging in user: ${request.email}');

      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      if (response.statusCode == HttpStatusCode.ok) {
        final loginResponse = LoginResponse.fromJson(response.data);

        // Save tokens
        await _tokenStorage.saveTokens(
          accessToken: loginResponse.accessToken,
          refreshToken: loginResponse.refreshToken,
        );

        // Save user data
        await _tokenStorage.saveUserId(loginResponse.user.id);
        await _tokenStorage.saveUserEmail(loginResponse.user.email);
        await _tokenStorage.saveUserType('tailor');
        await _tokenStorage.saveLoginState(true);
        await _tokenStorage.saveLastLoginDate();

        Logger.info('AccountsApi', '');
        return loginResponse;
      } else {
        throw ApiException(
          message: 'Invalid email or password',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } catch (e) {
      Logger.error('AccountsApi', '', error: e);
      rethrow;
    }
  }

  /// Logout user
  ///
  /// Clears local tokens and user data
  Future<void> logout() async {
    try {
      Logger.api('🔐 Logging out user');

      // Clear all stored data
      await _tokenStorage.clearAll();

      Logger.info('AccountsApi', '');
    } catch (e) {
      Logger.error('AccountsApi', '', error: e);
      rethrow;
    }
  }

  /// Refresh access token
  ///
  /// POST /api/v1/accounts/auth/refresh/
  ///
  /// Returns [RefreshTokenResponse] with new access token
  Future<RefreshTokenResponse> refreshToken() async {
    try {
      Logger.api('🔄 Refreshing token');

      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        throw ApiException(message: 'No refresh token found');
      }

      final response = await _apiClient.post(
        ApiEndpoints.refreshToken,
        data: RefreshTokenRequest(refreshToken: refreshToken).toJson(),
      );

      if (response.statusCode == HttpStatusCode.ok) {
        final refreshResponse = RefreshTokenResponse.fromJson(response.data);

        // Save new access token
        await _tokenStorage.saveAccessToken(refreshResponse.accessToken);

        // Save new refresh token if provided (token rotation)
        if (refreshResponse.refreshToken != null) {
          await _tokenStorage.saveRefreshToken(refreshResponse.refreshToken!);
        }

        Logger.info('AccountsApi', '');
        return refreshResponse;
      } else {
        throw ApiException(
          message: 'Token refresh failed',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } catch (e) {
      Logger.error('AccountsApi', '', error: e);
      rethrow;
    }
  }

  // ==================== USER MANAGEMENT ====================

  /// Get current user details
  ///
  /// GET /api/v1/accounts/users/me/
  ///
  /// Returns [Tailor] object
  Future<Tailor> getCurrentUser() async {
    try {
      Logger.api('👤 Getting current user');

      final response = await _apiClient.get(ApiEndpoints.currentUser);

      if (response.statusCode == HttpStatusCode.ok) {
        final user = Tailor.fromMap(response.data);

        // Update stored user data
        await _tokenStorage.saveUserId(user.id);
        await _tokenStorage.saveUserEmail(user.email);
        await _tokenStorage.saveUserType('tailor');

        Logger.info('AccountsApi', '');
        return user;
      } else {
        throw ApiException(
          message: 'Failed to get user data',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } catch (e) {
      Logger.error('AccountsApi', '', error: e);
      rethrow;
    }
  }

  /// Update current user details
  ///
  /// PATCH /api/v1/accounts/users/me/
  ///
  /// Returns updated [Tailor] object
  Future<Tailor> updateCurrentUser(UpdateUserRequest request) async {
    try {
      Logger.api('📝 Updating current user');

      final response = await _apiClient.patch(
        ApiEndpoints.updateUser,
        data: request.toJson(),
      );

      if (response.statusCode == HttpStatusCode.ok) {
        final user = Tailor.fromMap(response.data);

        // Update stored user data
        await _tokenStorage.saveUserEmail(user.email);

        Logger.info('AccountsApi', '');
        return user;
      } else {
        throw ApiException(
          message: 'Failed to update user',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } catch (e) {
      Logger.error('AccountsApi', '', error: e);
      rethrow;
    }
  }

  /// Change user password
  ///
  /// POST /api/v1/accounts/users/me/password/
  ///
  /// Returns success message
  Future<String> changePassword(ChangePasswordRequest request) async {
    try {
      Logger.api('🔒 Changing password');

      final response = await _apiClient.post(
        ApiEndpoints.changePassword,
        data: request.toJson(),
      );

      if (response.statusCode == HttpStatusCode.ok) {
        final message = response.data['detail'] ?? 'Password updated successfully';
        Logger.info('AccountsApi', '');
        return message;
      } else {
        throw ApiException(
          message: 'Failed to change password',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } catch (e) {
      Logger.error('AccountsApi', '', error: e);
      rethrow;
    }
  }

  /// Request password reset (forgot password)
  ///
  /// POST /api/v1/accounts/auth/forgot-password/
  ///
  /// Sends reset email to user
  Future<String> forgotPassword(ForgotPasswordRequest request) async {
    try {
      Logger.api('📧 Requesting password reset for: ${request.email}');

      final response = await _apiClient.post(
        ApiEndpoints.forgotPassword,
        data: request.toJson(),
      );

      if (response.statusCode == HttpStatusCode.ok) {
        final message = response.data['detail'] ??
            'Password reset email sent successfully';
        Logger.info('AccountsApi', '');
        return message;
      } else {
        throw ApiException(
          message: 'Failed to send reset email',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } catch (e) {
      Logger.error('AccountsApi', '', error: e);
      rethrow;
    }
  }

  /// Reset password with token
  ///
  /// POST /api/v1/accounts/auth/reset-password/
  ///
  /// Resets password using token from email
  Future<String> resetPassword(ResetPasswordRequest request) async {
    try {
      Logger.api('🔒 Resetting password with token');

      final response = await _apiClient.post(
        ApiEndpoints.resetPassword,
        data: request.toJson(),
      );

      if (response.statusCode == HttpStatusCode.ok) {
        final message =
            response.data['detail'] ?? 'Password reset successfully';
        Logger.info('AccountsApi', '');
        return message;
      } else {
        throw ApiException(
          message: 'Failed to reset password',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } catch (e) {
      Logger.error('AccountsApi', '', error: e);
      rethrow;
    }
  }

  /// Delete user account
  ///
  /// DELETE /api/v1/accounts/users/me/
  ///
  /// Permanently deletes user account
  Future<void> deleteAccount() async {
    try {
      Logger.api('🗑️ Deleting user account');

      final response = await _apiClient.delete(ApiEndpoints.deleteUser);

      if (response.statusCode == HttpStatusCode.noContent ||
          response.statusCode == HttpStatusCode.ok) {
        // Clear all stored data
        await _tokenStorage.clearAll();

        Logger.info('AccountsApi', '');
      } else {
        throw ApiException(
          message: 'Failed to delete account',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } catch (e) {
      Logger.error('AccountsApi', '', error: e);
      rethrow;
    }
  }

  // ==================== OTP VERIFICATION ====================

  /// Verify OTP and activate user
  ///
  /// POST /api/v1/accounts/auth/verify-otp/
  ///
  /// Returns [VerifyOTPResponse] with activated user data
  Future<VerifyOTPResponse> verifyOTP({
    required String email,
    required String otpCode,
    String otpType = 'registration',
  }) async {
    try {
      Logger.api('🔐 Verifying OTP for: $email');

      final request = VerifyOTPRequest(
        email: email,
        otpCode: otpCode,
        otpType: otpType,
      );

      final response = await _apiClient.post(
        ApiEndpoints.verifyOTP,
        data: request.toJson(),
      );

      if (response.statusCode == HttpStatusCode.ok) {
        final verifyResponse = VerifyOTPResponse.fromJson(response.data);
        Logger.info('AccountsApi', '✅ OTP verified successfully for: $email');
        return verifyResponse;
      } else {
        throw ApiException(
          message: 'OTP verification failed',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } catch (e) {
      Logger.error('AccountsApi', 'OTP verification failed', error: e);
      rethrow;
    }
  }

  /// Resend OTP to email
  ///
  /// POST /api/v1/accounts/auth/resend-otp/
  ///
  /// Resends OTP to user's email
  Future<void> resendOTP(String email, {String otpType = 'registration'}) async {
    try {
      Logger.api('📧 Resending OTP to: $email');

      final request = ResendOTPRequest(
        email: email,
        otpType: otpType,
      );

      final response = await _apiClient.post(
        ApiEndpoints.resendOTP,
        data: request.toJson(),
      );

      if (response.statusCode == HttpStatusCode.ok) {
        Logger.info('AccountsApi', '✅ OTP resent successfully to: $email');
      } else {
        throw ApiException(
          message: 'Failed to resend OTP',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } catch (e) {
      Logger.error('AccountsApi', 'Failed to resend OTP', error: e);
      rethrow;
    }
  }

  /// Request password reset OTP
  ///
  /// POST /api/v1/accounts/auth/forgot-password/
  ///
  /// Sends password reset OTP to user's email
  Future<String> requestPasswordReset(String email) async {
    try {
      Logger.api('🔒 Requesting password reset for: $email');

      final request = ForgotPasswordRequest(email: email);

      final response = await _apiClient.post(
        ApiEndpoints.forgotPassword,
        data: request.toJson(),
      );

      if (response.statusCode == HttpStatusCode.ok) {
        Logger.info('AccountsApi', '✅ Password reset OTP sent to: $email');
        
        // Extract reset_token from response
        final data = response.data['data'] as Map<String, dynamic>?;
        final resetToken = data?['reset_token'] as String?;
        
        if (resetToken == null || resetToken.isEmpty) {
          throw ApiException(
            message: 'Reset token not received from server',
            statusCode: response.statusCode,
            data: response.data,
          );
        }
        
        Logger.debug('AccountsApi', 'Received reset token: ${resetToken.substring(0, 10)}...');
        return resetToken;
      } else {
        throw ApiException(
          message: 'Failed to send password reset OTP',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } catch (e) {
      Logger.error('AccountsApi', 'Password reset request failed', error: e);
      rethrow;
    }
  }

  /// Check if email exists
  ///
  /// POST /api/v1/accounts/auth/check-email/
  ///
  /// Returns true if email exists
  Future<bool> checkEmailExists(String email) async {
    try {
      Logger.api('📧 Checking if email exists: $email');

      final response = await _apiClient.post(
        ApiEndpoints.checkEmail,
        data: {'email': email},
      );

      if (response.statusCode == HttpStatusCode.ok) {
        final exists = response.data['exists'] ?? false;
        Logger.info('AccountsApi', 'Email exists: $exists');
        return exists;
      } else {
        return false;
      }
    } catch (e) {
      Logger.error('AccountsApi', 'Error checking email', error: e);
      return false;
    }
  }

  // ==================== EMAIL VERIFICATION ====================

  /// Verify email with token
  ///
  /// POST /api/v1/accounts/auth/verify-email/
  ///
  /// Verifies user's email address
  Future<String> verifyEmail(EmailVerificationRequest request) async {
    try {
      Logger.api('📧 Verifying email');

      final response = await _apiClient.post(
        ApiEndpoints.verifyEmail,
        data: request.toJson(),
      );

      if (response.statusCode == HttpStatusCode.ok) {
        final message =
            response.data['detail'] ?? 'Email verified successfully';
        Logger.info('AccountsApi', '');
        return message;
      } else {
        throw ApiException(
          message: 'Failed to verify email',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } catch (e) {
      Logger.error('AccountsApi', '', error: e);
      rethrow;
    }
  }

  /// Resend email verification
  ///
  /// POST /api/v1/accounts/auth/resend-verification/
  ///
  /// Resends verification email
  Future<String> resendEmailVerification() async {
    try {
      Logger.api('📧 Resending verification email');

      final response = await _apiClient.post(ApiEndpoints.resendVerification);

      if (response.statusCode == HttpStatusCode.ok) {
        final message =
            response.data['detail'] ?? 'Verification email sent successfully';
        Logger.info('AccountsApi', '');
        return message;
      } else {
        throw ApiException(
          message: 'Failed to send verification email',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } catch (e) {
      Logger.error('AccountsApi', '', error: e);
      rethrow;
    }
  }



  // ==================== UTILITY ====================

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _tokenStorage.isAuthenticated();
  }

  /// Get stored user ID
  Future<String?> getUserId() async {
    return await _tokenStorage.getUserId();
  }

  /// Get stored user email
  Future<String?> getUserEmail() async {
    return await _tokenStorage.getUserEmail();
  }

  /// Get stored user type
  Future<String?> getUserType() async {
    return await _tokenStorage.getUserType();
  }
}
