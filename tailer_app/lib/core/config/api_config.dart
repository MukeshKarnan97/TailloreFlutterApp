/// API Configuration for Django Backend
/// Contains base URLs, endpoints, and API constants
library;

class ApiConfig {
  // Environment
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  // Base URLs
  static const String developmentBaseUrl = 'http://192.168.0.7:8000';
  static const String productionBaseUrl = 'https://api.yourdomain.com';

  /// Get the current base URL based on environment
  static String get baseUrl {
    switch (environment) {
      case 'production':
        return productionBaseUrl;
      case 'staging':
        return 'https://staging-api.yourdomain.com';
      default:
        return developmentBaseUrl;
    }
  }

  // API Version
  static const String apiVersion = 'v1';
  static const String apiPrefix = '/api/$apiVersion';

  /// Get full API URL
  static String get apiUrl => '$baseUrl$apiPrefix';

  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Headers
  static const String contentType = 'application/json';
  static const String acceptHeader = 'application/json';
}

/// API Endpoints
class ApiEndpoints {
  // Base paths
  static const String accounts = '/accounts';
  static const String tailors = '/tailors';
  static const String customers = '/customers';
  static const String measurements = '/measurements';
  static const String orders = '/orders';
  static const String payments = '/payments';
  static const String notifications = '/notifications';
  static const String analytics = '/analytics';

  // ==================== AUTHENTICATION ENDPOINTS ====================
  
  // Authentication
  static const String register = '/auth/register/';
  static const String login = '/auth/login/';
  static const String refreshToken = '/auth/refresh/';
  static const String logout = '/auth/logout/';
  static const String verifyEmail = '/auth/verify-email/';
  static const String resendVerification = '/auth/resend-verification/';
  
  // OTP endpoints
  static const String verifyOTP = '/auth/verify-email/';
  static const String resendOTP = '/auth/resend-otp/';
  static const String checkEmail = '/auth/check-email/';
  
  // Password management
  static const String changePassword = '/auth/change-password/';
  static const String forgotPassword = '/auth/forgot-password/';
  static const String resetPassword = '/auth/reset-password/';
  
  // User management
  static const String currentUser = '/auth/users/me/';
  static const String updateUser = '/auth/users/me/';
  static const String deleteUser = '/auth/users/me/';
  
  // User preferences
  static const String userPreferences = '/auth/users/me/preferences/';
  
  // ==================== CUSTOMERS ENDPOINTS ====================
  // (Placeholder for future implementation)
  static const String customersList = '$customers/';
  static String customerDetail(String id) => '$customers/$id/';
  
  // ==================== ORDERS ENDPOINTS ====================
  // (Placeholder for future implementation)
  static const String ordersList = '$orders/';
  static String orderDetail(String id) => '$orders/$id/';
  
  // ==================== MEASUREMENTS ENDPOINTS ====================
  // (Placeholder for future implementation)
  static const String measurementsList = '$measurements/';
  static String measurementDetail(String id) => '$measurements/$id/';
}

/// HTTP Status Codes
class HttpStatusCode {
  // Success
  static const int ok = 200;
  static const int created = 201;
  static const int accepted = 202;
  static const int noContent = 204;

  // Client Errors
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int methodNotAllowed = 405;
  static const int conflict = 409;
  static const int unprocessableEntity = 422;
  static const int tooManyRequests = 429;

  // Server Errors
  static const int internalServerError = 500;
  static const int badGateway = 502;
  static const int serviceUnavailable = 503;
  static const int gatewayTimeout = 504;
}

/// API Error Messages
class ApiErrorMessages {
  static const String networkError = 'No internet connection. Please check your network.';
  static const String serverError = 'Server error. Please try again later.';
  static const String timeoutError = 'Request timeout. Please try again.';
  static const String unknownError = 'An unexpected error occurred.';
  static const String unauthorized = 'Unauthorized. Please login again.';
  static const String forbidden = 'Access forbidden.';
  static const String notFound = 'Resource not found.';
  static const String validationError = 'Validation failed. Please check your input.';
  static const String tokenExpired = 'Session expired. Please login again.';
  
  /// Get user-friendly error message based on status code
  static String getErrorMessage(int? statusCode) {
    switch (statusCode) {
      case HttpStatusCode.badRequest:
      case HttpStatusCode.unprocessableEntity:
        return validationError;
      case HttpStatusCode.unauthorized:
        return unauthorized;
      case HttpStatusCode.forbidden:
        return forbidden;
      case HttpStatusCode.notFound:
        return notFound;
      case HttpStatusCode.tooManyRequests:
        return 'Too many requests. Please try again later.';
      case HttpStatusCode.internalServerError:
      case HttpStatusCode.badGateway:
      case HttpStatusCode.serviceUnavailable:
      case HttpStatusCode.gatewayTimeout:
        return serverError;
      default:
        return unknownError;
    }
  }
}

/// Storage Keys for SharedPreferences/Secure Storage
class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userType = 'user_type';
  static const String isLoggedIn = 'is_logged_in';
  static const String lastLoginDate = 'last_login_date';
  static const String deviceToken = 'device_token';
  
  // User preferences
  static const String theme = 'theme';
  static const String language = 'language';
  static const String currency = 'currency';
}
