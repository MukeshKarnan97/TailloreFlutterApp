import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';

/// AppConfig - Central configuration management using environment variables
/// 
/// This class provides a centralized way to access environment-specific
/// configuration values loaded from the .env file. It includes type-safe
/// getters, fallback values, and logging for configuration access.
/// 
/// Features:
/// - Type-safe configuration access
/// - Fallback values for missing configurations
/// - Environment-specific settings
/// - Centralized configuration management
/// - Logging for configuration access and errors
class AppConfig {
  static const String _className = 'AppConfig';
  
  // Private constructor to prevent instantiation
  AppConfig._();
  
  static bool _isInitialized = false;

  /// Initialize the configuration by loading the .env file
  /// This should be called before runApp() in main.dart
  static Future<void> initialize({String fileName = '.env'}) async {
    return Logger.traceAsyncMethod(_className, 'initialize', () async {
      try {
        Logger.info(_className, 'Loading environment configuration from $fileName');
        await dotenv.load(fileName: fileName);
        _isInitialized = true;
        Logger.info(_className, 'Environment configuration loaded successfully');
        
        // Log current environment
        Logger.info(_className, 'Current environment: ${environment}');
        Logger.debug(_className, 'App name: ${appName}');
        Logger.debug(_className, 'App version: ${appVersion}');
        
      } catch (e, stackTrace) {
        Logger.error(_className, 'Failed to load environment configuration', 
          error: e, stackTrace: stackTrace);
        _isInitialized = false;
        rethrow;
      }
    }, parameters: {'fileName': fileName});
  }

  /// Check if configuration is initialized
  static bool get isInitialized => _isInitialized;

  /// Get environment variable with fallback and logging
  static String _getEnvVar(String key, {String? fallback, bool sensitive = false}) {
    if (!_isInitialized) {
      Logger.warning(_className, 'Configuration not initialized, using fallback for $key');
    }
    
    final value = dotenv.env[key] ?? fallback ?? '';
    
    if (value.isEmpty && fallback == null) {
      Logger.warning(_className, 'Missing required environment variable: $key');
    } else if (!sensitive) {
      Logger.debug(_className, 'Config $key: $value');
    } else {
      Logger.debug(_className, 'Config $key: [SENSITIVE VALUE HIDDEN]');
    }
    
    return value;
  }

  /// Get boolean environment variable
  static bool _getBoolVar(String key, {bool fallback = false}) {
    final value = _getEnvVar(key, fallback: fallback.toString());
    return value.toLowerCase() == 'true';
  }

  /// Get integer environment variable
  static int _getIntVar(String key, {int? fallback}) {
    final value = _getEnvVar(key, fallback: fallback?.toString());
    return int.tryParse(value) ?? fallback ?? 0;
  }

  /// Get double environment variable
  static double _getDoubleVar(String key, {double? fallback}) {
    final value = _getEnvVar(key, fallback: fallback?.toString());
    return double.tryParse(value) ?? fallback ?? 0.0;
  }

  // ==================== APP CONFIGURATION ====================

  /// Application name
  static String get appName => _getEnvVar('APP_NAME', fallback: 'Tailor App');

  /// Application version
  static String get appVersion => _getEnvVar('APP_VERSION', fallback: '1.0.0');

  /// Current environment (development, staging, production)
  static String get environment => _getEnvVar('APP_ENVIRONMENT', fallback: 'development');

  /// Check if running in development environment
  static bool get isDevelopment => environment == 'development';

  /// Check if running in production environment
  static bool get isProduction => environment == 'production';

  /// Check if running in staging environment
  static bool get isStaging => environment == 'staging';

  // ==================== DATABASE CONFIGURATION ====================

  /// Database name
  static String get databaseName => _getEnvVar('DATABASE_NAME', fallback: 'tailor_app.db');

  /// Database version
  static int get databaseVersion => _getIntVar('DATABASE_VERSION', fallback: 4);

  /// Database connection timeout in seconds
  static int get databaseTimeout => _getIntVar('DATABASE_TIMEOUT', fallback: 30);

  // ==================== API CONFIGURATION ====================

  /// API base URL
  static String get apiBaseUrl => _getEnvVar('API_BASE_URL', fallback: 'https://api.tailorapp.com');

  /// API request timeout in milliseconds
  static int get apiTimeout => _getIntVar('API_TIMEOUT', fallback: 30000);

  /// Number of API retry attempts
  static int get apiRetryCount => _getIntVar('API_RETRY_COUNT', fallback: 3);

  // ==================== AUTHENTICATION CONFIGURATION ====================

  /// JWT secret key for token validation
  static String get jwtSecretKey => _getEnvVar('JWT_SECRET_KEY', 
    fallback: 'default-secret-key', sensitive: true);

  /// JWT token expiration time in seconds
  static int get jwtExpirationTime => _getIntVar('JWT_EXPIRATION_TIME', fallback: 86400);

  /// Refresh token expiration time in seconds
  static int get refreshTokenExpirationTime => 
    _getIntVar('REFRESH_TOKEN_EXPIRATION_TIME', fallback: 604800);

  /// Google OAuth client ID
  static String get googleClientId => _getEnvVar('GOOGLE_CLIENT_ID', sensitive: true);

  /// Google OAuth client secret
  static String get googleClientSecret => _getEnvVar('GOOGLE_CLIENT_SECRET', sensitive: true);

  /// Facebook app ID
  static String get facebookAppId => _getEnvVar('FACEBOOK_APP_ID', sensitive: true);

  /// Facebook app secret
  static String get facebookAppSecret => _getEnvVar('FACEBOOK_APP_SECRET', sensitive: true);

  // ==================== FIREBASE CONFIGURATION ====================

  /// Firebase project ID
  static String get firebaseProjectId => _getEnvVar('FIREBASE_PROJECT_ID');

  /// Firebase API key
  static String get firebaseApiKey => _getEnvVar('FIREBASE_API_KEY', sensitive: true);

  /// Firebase app ID
  static String get firebaseAppId => _getEnvVar('FIREBASE_APP_ID');

  /// Firebase messaging sender ID
  static String get firebaseMessagingSenderId => _getEnvVar('FIREBASE_MESSAGING_SENDER_ID');

  // ==================== STORAGE CONFIGURATION ====================

  /// Maximum image size in MB
  static int get maxImageSizeMB => _getIntVar('MAX_IMAGE_SIZE_MB', fallback: 5);

  /// Maximum images per order
  static int get maxImagesPerOrder => _getIntVar('MAX_IMAGES_PER_ORDER', fallback: 10);

  /// Image upload path
  static String get imageUploadPath => _getEnvVar('IMAGE_UPLOAD_PATH', fallback: '/uploads/images');

  /// Backup interval in hours
  static int get backupIntervalHours => _getIntVar('BACKUP_INTERVAL_HOURS', fallback: 24);

  // ==================== PAYMENT CONFIGURATION ====================

  /// Payment gateway key
  static String get paymentGatewayKey => _getEnvVar('PAYMENT_GATEWAY_KEY', sensitive: true);

  /// Payment gateway secret
  static String get paymentGatewaySecret => _getEnvVar('PAYMENT_GATEWAY_SECRET', sensitive: true);

  /// Default currency code
  static String get currency => _getEnvVar('CURRENCY', fallback: 'INR');

  /// Tax percentage
  static double get taxPercentage => _getDoubleVar('TAX_PERCENTAGE', fallback: 18.0);

  // ==================== NOTIFICATION CONFIGURATION ====================

  /// Push notification key
  static String get pushNotificationKey => _getEnvVar('PUSH_NOTIFICATION_KEY', sensitive: true);

  /// Email service key
  static String get emailServiceKey => _getEnvVar('EMAIL_SERVICE_KEY', sensitive: true);

  /// SMS service key
  static String get smsServiceKey => _getEnvVar('SMS_SERVICE_KEY', sensitive: true);

  // ==================== DEBUG CONFIGURATION ====================

  /// Enable debug logs
  static bool get enableDebugLogs => _getBoolVar('ENABLE_DEBUG_LOGS', fallback: true);

  /// Enable performance logs
  static bool get enablePerformanceLogs => _getBoolVar('ENABLE_PERFORMANCE_LOGS', fallback: true);

  /// Enable network logs
  static bool get enableNetworkLogs => _getBoolVar('ENABLE_NETWORK_LOGS', fallback: true);

  /// Log level (0=DEBUG, 1=INFO, 2=WARNING, 3=ERROR)
  static int get logLevel => _getIntVar('LOG_LEVEL', fallback: 0);

  // ==================== FEATURE FLAGS ====================

  /// Enable Google authentication
  static bool get enableGoogleAuth => _getBoolVar('ENABLE_GOOGLE_AUTH', fallback: true);

  /// Enable Facebook authentication
  static bool get enableFacebookAuth => _getBoolVar('ENABLE_FACEBOOK_AUTH', fallback: true);

  /// Enable biometric authentication
  static bool get enableBiometricAuth => _getBoolVar('ENABLE_BIOMETRIC_AUTH', fallback: false);

  /// Enable dark mode
  static bool get enableDarkMode => _getBoolVar('ENABLE_DARK_MODE', fallback: true);

  /// Enable offline mode
  static bool get enableOfflineMode => _getBoolVar('ENABLE_OFFLINE_MODE', fallback: true);

  // ==================== BUSINESS CONFIGURATION ====================

  /// Default currency symbol
  static String get defaultCurrencySymbol => _getEnvVar('DEFAULT_CURRENCY_SYMBOL', fallback: '₹');

  /// Default tax rate
  static double get defaultTaxRate => _getDoubleVar('DEFAULT_TAX_RATE', fallback: 18.0);

  /// Default advance percentage
  static double get defaultAdvancePercentage => _getDoubleVar('DEFAULT_ADVANCE_PERCENTAGE', fallback: 50.0);

  /// Maximum customers per tailor
  static int get maxCustomersPerTailor => _getIntVar('MAX_CUSTOMERS_PER_TAILOR', fallback: 1000);

  /// Auto-update order status
  static bool get orderStatusAutoUpdate => _getBoolVar('ORDER_STATUS_AUTO_UPDATE', fallback: true);

  // ==================== SECURITY CONFIGURATION ====================

  /// Encryption key for sensitive data
  static String get encryptionKey => _getEnvVar('ENCRYPTION_KEY', 
    fallback: 'default-encryption-key', sensitive: true);

  /// Session timeout in minutes
  static int get sessionTimeoutMinutes => _getIntVar('SESSION_TIMEOUT_MINUTES', fallback: 30);

  /// Maximum login attempts before lockout
  static int get maxLoginAttempts => _getIntVar('MAX_LOGIN_ATTEMPTS', fallback: 5);

  /// Lockout duration in minutes
  static int get lockoutDurationMinutes => _getIntVar('LOCKOUT_DURATION_MINUTES', fallback: 15);

  // ==================== ANALYTICS CONFIGURATION ====================

  /// Enable analytics
  static bool get analyticsEnabled => _getBoolVar('ANALYTICS_ENABLED', fallback: true);

  /// Enable crash reporting
  static bool get crashReportingEnabled => _getBoolVar('CRASH_REPORTING_ENABLED', fallback: true);

  /// Enable performance monitoring
  static bool get performanceMonitoringEnabled => 
    _getBoolVar('PERFORMANCE_MONITORING_ENABLED', fallback: true);

  // ==================== SPLASH SCREEN CONFIGURATION ====================

  /// Splash screen duration in development (milliseconds)
  static int get splashDurationDev => _getIntVar('SPLASH_DURATION_DEV', fallback: 2000);

  /// Splash screen duration in production (milliseconds)
  static int get splashDurationProd => _getIntVar('SPLASH_DURATION_PROD', fallback: 3000);

  /// Logo fade animation duration (milliseconds)
  static int get splashFadeDuration => _getIntVar('SPLASH_FADE_DURATION', fallback: 1500);

  /// Logo scale animation duration (milliseconds)
  static int get splashScaleDuration => _getIntVar('SPLASH_SCALE_DURATION', fallback: 1200);

  /// Shimmer animation duration (milliseconds)
  static int get splashShimmerDuration => _getIntVar('SPLASH_SHIMMER_DURATION', fallback: 2000);

  /// Enable progress bar on splash screen
  static bool get splashProgressEnabled => _getBoolVar('SPLASH_PROGRESS_ENABLED', fallback: true);

  /// Enable app name animation
  static bool get splashAppNameAnimation => _getBoolVar('SPLASH_APP_NAME_ANIMATION', fallback: true);

  /// Enable tagline on splash screen
  static bool get splashTaglineEnabled => _getBoolVar('SPLASH_TAGLINE_ENABLED', fallback: true);

  /// Enable version info on splash screen
  static bool get splashVersionInfoEnabled => _getBoolVar('SPLASH_VERSION_INFO_ENABLED', fallback: true);

  /// Enable error retry functionality
  static bool get splashErrorRetryEnabled => _getBoolVar('SPLASH_ERROR_RETRY_ENABLED', fallback: true);

  /// Show debug info in splash error screen
  static bool get splashErrorDebugInfo => _getBoolVar('SPLASH_ERROR_DEBUG_INFO', fallback: true);

  /// Get splash duration based on current environment
  static Duration get splashDuration => Duration(
    milliseconds: isDevelopment ? splashDurationDev : splashDurationProd,
  );

  // ==================== DEVELOPMENT CONFIGURATION ====================

  /// Mock payments in development
  static bool get devMockPayments => _getBoolVar('DEV_MOCK_PAYMENTS', fallback: true);

  /// Skip email verification in development
  static bool get devSkipEmailVerification => _getBoolVar('DEV_SKIP_EMAIL_VERIFICATION', fallback: false);

  /// Use local database in development
  static bool get devUseLocalDatabase => _getBoolVar('DEV_USE_LOCAL_DATABASE', fallback: true);

  /// Enable debug menu in development
  static bool get devEnableDebugMenu => _getBoolVar('DEV_ENABLE_DEBUG_MENU', fallback: true);

  // ==================== UTILITY METHODS ====================

  /// Get all configuration as a map (for debugging)
  static Map<String, dynamic> getAllConfig({bool includeSensitive = false}) {
    return Logger.traceMethod(_className, 'getAllConfig', () {
      final config = <String, dynamic>{};
      
      // Add non-sensitive configurations
      config.addAll({
        'appName': appName,
        'appVersion': appVersion,
        'environment': environment,
        'databaseName': databaseName,
        'databaseVersion': databaseVersion,
        'apiBaseUrl': apiBaseUrl,
        'apiTimeout': apiTimeout,
        'currency': currency,
        'taxPercentage': taxPercentage,
        'enableDebugLogs': enableDebugLogs,
        'enableGoogleAuth': enableGoogleAuth,
        'enableFacebookAuth': enableFacebookAuth,
        'enableDarkMode': enableDarkMode,
        'enableOfflineMode': enableOfflineMode,
      });

      if (includeSensitive) {
        Logger.warning(_className, 'Including sensitive configuration in output');
        config.addAll({
          'jwtSecretKey': jwtSecretKey,
          'googleClientId': googleClientId,
          'encryptionKey': encryptionKey,
        });
      }

      Logger.info(_className, 'Retrieved ${config.length} configuration values');
      return config;
    }, parameters: {'includeSensitive': includeSensitive});
  }

  /// Validate required configurations
  static bool validateConfig() {
    return Logger.traceMethod(_className, 'validateConfig', () {
      final requiredConfigs = <String, String>{
        'APP_NAME': appName,
        'DATABASE_NAME': databaseName,
        'API_BASE_URL': apiBaseUrl,
      };

      bool isValid = true;
      
      for (final entry in requiredConfigs.entries) {
        if (entry.value.isEmpty) {
          Logger.error(_className, 'Missing required configuration: ${entry.key}');
          isValid = false;
        }
      }

      if (isValid) {
        Logger.info(_className, 'All required configurations are valid');
      } else {
        Logger.error(_className, 'Configuration validation failed');
      }

      return isValid;
    });
  }

  /// Reload configuration from .env file
  static Future<void> reload({String fileName = '.env'}) async {
    return Logger.traceAsyncMethod(_className, 'reload', () async {
      Logger.info(_className, 'Reloading configuration from $fileName');
      await dotenv.load(fileName: fileName);
      Logger.info(_className, 'Configuration reloaded successfully');
    }, parameters: {'fileName': fileName});
  }

  /// Get configuration value by key (for dynamic access)
  static String getConfigValue(String key, {String? fallback}) {
    return _getEnvVar(key, fallback: fallback);
  }

  /// Check if configuration key exists
  static bool hasConfigValue(String key) {
    return dotenv.env.containsKey(key);
  }
}