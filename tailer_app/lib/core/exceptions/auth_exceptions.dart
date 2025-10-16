/// AuthExceptions - Custom exception classes for authentication errors
/// 
/// Provides specific exception types for different authentication scenarios,
/// enabling better error handling and user feedback.
library;

abstract class AuthException implements Exception {
  final String message;
  final String userMessage;
  final String? details;
  final DateTime timestamp;

  AuthException({
    required this.message,
    required this.userMessage,
    this.details,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'AuthException: $message${details != null ? ' ($details)' : ''}';
}

/// Exception thrown when user is not found in the database
class UserNotFoundException extends AuthException {
  UserNotFoundException({
    String? email,
    super.details,
  }) : super(
    message: email != null ? 'User not found for email: $email' : 'User not found',
    userMessage: 'User not found. Please check your email address or sign up for a new account.',
  );
}

/// Exception thrown when credentials are invalid
class InvalidCredentialsException extends AuthException {
  InvalidCredentialsException({
    super.details,
  }) : super(
    message: 'Invalid email or password provided',
    userMessage: 'Invalid email or password. Please check your credentials and try again.',
  );
}

/// Exception thrown when account is locked due to multiple failed attempts
class AccountLockedException extends AuthException {
  final DateTime? unlockTime;
  final int failedAttempts;

  AccountLockedException({
    this.unlockTime,
    this.failedAttempts = 0,
    super.details,
  }) : super(
    message: 'Account temporarily locked due to multiple failed login attempts',
    userMessage: 'Account temporarily locked due to multiple failed attempts. Try again later.',
  );
}

/// Exception thrown when email is not verified
class EmailNotVerifiedException extends AuthException {
  final String email;

  EmailNotVerifiedException({
    required this.email,
    super.details,
  }) : super(
    message: 'Email verification required for $email',
    userMessage: 'Please verify your email before signing in. Check your inbox for the verification link.',
  );
}

/// Exception thrown when user account is disabled
class AccountDisabledException extends AuthException {
  final String reason;

  AccountDisabledException({
    required this.reason,
    super.details,
  }) : super(
    message: 'Account has been disabled: $reason',
    userMessage: 'Your account has been disabled. Please contact support for assistance.',
  );
}

/// Exception thrown when password has expired
class PasswordExpiredException extends AuthException {
  PasswordExpiredException({
    super.details,
  }) : super(
    message: 'Password has expired and must be changed',
    userMessage: 'Your password has expired. Please reset your password to continue.',
  );
}

/// Exception thrown when too many requests are made
class TooManyRequestsException extends AuthException {
  final Duration retryAfter;

  TooManyRequestsException({
    required this.retryAfter,
    super.details,
  }) : super(
    message: 'Too many requests. Retry after ${retryAfter.inSeconds} seconds',
    userMessage: 'Too many requests. Please wait a moment before trying again.',
  );
}

/// Exception thrown when there's a network connectivity issue
class NetworkException extends AuthException {
  NetworkException({
    super.details,
  }) : super(
    message: 'Network connectivity error',
    userMessage: 'Network error. Please check your connection and try again.',
  );
}

/// Exception thrown when server returns an error
class ServerException extends AuthException {
  final int? statusCode;

  ServerException({
    this.statusCode,
    super.details,
  }) : super(
    message: statusCode != null ? 'Server error (Code: $statusCode)' : 'Server error',
    userMessage: 'Server error. Please try again later.',
  );
}

/// Exception thrown when user already exists during signup
class UserAlreadyExistsException extends AuthException {
  final String email;

  UserAlreadyExistsException({
    required this.email,
    super.details,
  }) : super(
    message: 'User already exists with email: $email',
    userMessage: 'An account with this email already exists. Try signing in instead.',
  );
}

/// Exception thrown when OTP verification fails
class OtpVerificationException extends AuthException {
  final String? otpType;
  final int? attemptsRemaining;

  OtpVerificationException({
    this.otpType,
    this.attemptsRemaining,
    super.details,
  }) : super(
    message: otpType != null ? 'OTP verification failed for $otpType' : 'OTP verification failed',
    userMessage: 'Invalid OTP. Please check the code and try again.',
  );
}

/// Exception thrown when OTP has expired
class OtpExpiredException extends AuthException {
  OtpExpiredException({
    super.details,
  }) : super(
    message: 'OTP has expired',
    userMessage: 'OTP has expired. Please request a new code.',
  );
}

/// Exception thrown when OTP sending fails
class OtpSendException extends AuthException {
  OtpSendException({
    super.details,
  }) : super(
    message: 'Failed to send OTP',
    userMessage: 'Failed to send OTP. Please try again.',
  );
}

/// Exception thrown when password reset token is invalid
class InvalidTokenException extends AuthException {
  InvalidTokenException({
    super.details,
  }) : super(
    message: 'Invalid or expired reset token',
    userMessage: 'Invalid or expired reset link. Please request a new password reset.',
  );
}

/// Exception thrown for validation errors
class ValidationException extends AuthException {
  final Map<String, String> fieldErrors;

  ValidationException({
    required this.fieldErrors,
    super.details,
  }) : super(
    message: 'Validation failed: ${fieldErrors.keys.join(', ')}',
    userMessage: 'Please check your input and try again.',
  );
}

/// Exception thrown for database-related errors
class DatabaseException extends AuthException {
  DatabaseException({
    String? operation,
    super.details,
  }) : super(
    message: operation != null ? 'Database error during $operation' : 'Database error',
    userMessage: 'A technical error occurred. Please try again later.',
  );
}

/// Exception thrown for unexpected/unknown errors
class UnknownAuthException extends AuthException {
  UnknownAuthException({
    String? originalError,
    super.details,
  }) : super(
    message: originalError != null ? 'Unknown authentication error: $originalError' : 'Unknown authentication error',
    userMessage: 'An unexpected error occurred. Please try again.',
  );
}

/// Helper class to convert generic exceptions to AuthExceptions
class AuthExceptionHelper {
  
  /// Convert a generic exception to an appropriate AuthException
  static AuthException fromException(dynamic exception) {
    if (exception is AuthException) {
      return exception;
    }
    
    final message = exception.toString().toLowerCase();
    
    // Map common error messages to specific exceptions
    if (message.contains('user not found') || 
        message.contains('no user found') ||
        message.contains('user does not exist')) {
      return UserNotFoundException();
    }
    
    if (message.contains('invalid password') || 
        message.contains('wrong password') ||
        message.contains('invalid credentials') ||
        message.contains('authentication failed')) {
      return InvalidCredentialsException();
    }
    
    if (message.contains('account locked') || 
        message.contains('too many attempts') ||
        message.contains('temporarily locked')) {
      return AccountLockedException();
    }
    
    if (message.contains('email not verified') || 
        message.contains('verification required')) {
      return EmailNotVerifiedException(email: 'unknown');
    }
    
    if (message.contains('account disabled') || 
        message.contains('account suspended')) {
      return AccountDisabledException(reason: 'Unknown');
    }
    
    if (message.contains('network') || 
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('no internet')) {
      return NetworkException();
    }
    
    if (message.contains('server error') || 
        message.contains('internal error') ||
        message.contains('service unavailable')) {
      return ServerException();
    }
    
    if (message.contains('user already exists') || 
        message.contains('email already registered')) {
      return UserAlreadyExistsException(email: 'unknown');
    }
    
    if (message.contains('invalid otp') || 
        message.contains('wrong otp') ||
        message.contains('otp verification failed')) {
      return OtpVerificationException();
    }
    
    if (message.contains('otp expired') || 
        message.contains('code expired')) {
      return OtpExpiredException();
    }
    
    if (message.contains('database') || 
        message.contains('sql') ||
        message.contains('table')) {
      return DatabaseException();
    }
    
    // Default to unknown exception
    return UnknownAuthException(
      originalError: exception.toString(),
    );
  }
}