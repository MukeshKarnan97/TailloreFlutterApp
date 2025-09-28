# Environment Configuration Guide

## 🌍 Environment Management System

The Tailor App uses environment variables to manage configuration across different environments (development, staging, production) without hardcoding sensitive values.

## 📁 Configuration Files

### **Core Files:**
- **`.env`** - Main configuration file (git-ignored)
- **`.env.example`** - Template file for team reference (git-tracked)
- **`.env.development`** - Development-specific settings
- **`.env.production`** - Production-specific settings

### **Code Files:**
- **`lib/core/config/app_config.dart`** - Configuration management class
- **`lib/main.dart`** - Configuration initialization

## 🚀 Quick Setup

### 1. **Install Dependencies**
```bash
flutter pub add flutter_dotenv
```

### 2. **Create Your Environment File**
```bash
cp .env.example .env
```

### 3. **Edit Configuration Values**
Open `.env` and replace placeholder values with your actual configuration:
```env
APP_NAME=Your Tailor App
DATABASE_NAME=your_app.db
API_BASE_URL=https://your-api.com
GOOGLE_CLIENT_ID=your-actual-client-id
```

### 4. **Initialize in Main**
The configuration is automatically initialized in `main.dart`:
```dart
await AppConfig.initialize();
```

## 📋 Configuration Categories

### **🏗️ App Configuration**
```env
APP_NAME=Tailor App                    # Application display name
APP_VERSION=1.0.0                      # Current version
APP_ENVIRONMENT=development            # Environment type
```

### **🗄️ Database Configuration**
```env
DATABASE_NAME=tailor_app.db           # SQLite database filename
DATABASE_VERSION=1                    # Schema version for migrations
DATABASE_TIMEOUT=30                   # Connection timeout (seconds)
```

### **🌐 API Configuration**
```env
API_BASE_URL=https://api.example.com  # Backend API URL
API_TIMEOUT=30000                     # Request timeout (milliseconds)
API_RETRY_COUNT=3                     # Failed request retry attempts
```

### **🔐 Authentication Configuration**
```env
JWT_SECRET_KEY=your-secret-key        # JWT token validation key
JWT_EXPIRATION_TIME=86400             # Token lifespan (seconds)
GOOGLE_CLIENT_ID=your-google-id       # OAuth Google client ID
FACEBOOK_APP_ID=your-facebook-id      # OAuth Facebook app ID
```

### **🔧 Debug Configuration**
```env
ENABLE_DEBUG_LOGS=true                # Enable detailed logging
ENABLE_PERFORMANCE_LOGS=true          # Enable performance monitoring
LOG_LEVEL=0                          # 0=DEBUG, 1=INFO, 2=WARN, 3=ERROR
```

### **⚡ Feature Flags**
```env
ENABLE_GOOGLE_AUTH=true               # Enable Google sign-in
ENABLE_FACEBOOK_AUTH=true             # Enable Facebook sign-in  
ENABLE_BIOMETRIC_AUTH=false           # Enable fingerprint/face unlock
ENABLE_DARK_MODE=true                 # Enable dark mode support
ENABLE_OFFLINE_MODE=true              # Enable offline functionality
```

## 💡 Usage in Code

### **Basic Configuration Access**
```dart
// Get configuration values
String appName = AppConfig.appName;
String dbName = AppConfig.databaseName;
bool debugLogs = AppConfig.enableDebugLogs;

// Environment checks
if (AppConfig.isDevelopment) {
  Logger.info('Config', 'Running in development mode');
}

if (AppConfig.isProduction) {
  Logger.setLogLevel(3); // Only errors in production
}
```

### **Feature Flag Usage**
```dart
// Conditional feature rendering
if (AppConfig.enableGoogleAuth) {
  return GoogleSignInButton();
}

if (AppConfig.enableDarkMode) {
  return ThemeMode.system;
}

// Business logic with configuration
double advanceAmount = orderTotal * (AppConfig.defaultAdvancePercentage / 100);
```

### **Database Configuration**
```dart
class DatabaseService {
  Future<Database> initDatabase() async {
    return openDatabase(
      AppConfig.databaseName,           // From .env
      version: AppConfig.databaseVersion, // From .env
      onCreate: _createTables,
    );
  }
}
```

### **API Configuration**
```dart
class ApiService {
  static final String baseUrl = AppConfig.apiBaseUrl;
  static final int timeout = AppConfig.apiTimeout;
  
  Future<Response> makeRequest() async {
    return http.get(
      Uri.parse('$baseUrl/users'),
      headers: headers,
    ).timeout(Duration(milliseconds: timeout));
  }
}
```

### **Logger Integration**
```dart
void main() async {
  await AppConfig.initialize();
  
  // Configure logger based on environment
  Logger.setLogLevel(AppConfig.logLevel);
  
  if (AppConfig.enableDebugLogs) {
    Logger.info('Main', 'Debug logging enabled');
  }
}
```

## 🌐 Environment-Specific Configurations

### **🔧 Development Environment**
```env
APP_ENVIRONMENT=development
ENABLE_DEBUG_LOGS=true
DEV_MOCK_PAYMENTS=true
DEV_ENABLE_DEBUG_MENU=true
LOG_LEVEL=0                           # Show all logs
SESSION_TIMEOUT_MINUTES=120           # Longer sessions for dev
```

### **🚀 Production Environment**
```env
APP_ENVIRONMENT=production
ENABLE_DEBUG_LOGS=false
DEV_MOCK_PAYMENTS=false
DEV_ENABLE_DEBUG_MENU=false
LOG_LEVEL=3                          # Only error logs
SESSION_TIMEOUT_MINUTES=30           # Shorter sessions for security
```

### **Loading Different Environment Files**
```dart
// Load specific environment file
await AppConfig.initialize(fileName: '.env.development');
await AppConfig.initialize(fileName: '.env.production');

// Or use conditional loading
String envFile = kDebugMode ? '.env.development' : '.env.production';
await AppConfig.initialize(fileName: envFile);
```

## 🛡️ Security Best Practices

### **✅ DO:**
- Use `.env` files for all configuration
- Keep `.env` files in `.gitignore`
- Use different configurations per environment
- Rotate secrets regularly
- Use environment-specific API keys

### **❌ DON'T:**
- Commit real credentials to version control
- Hardcode sensitive values in source code
- Use production keys in development
- Share `.env` files in plain text
- Use weak encryption keys

### **🔒 Sensitive Configuration Management**
```dart
// AppConfig automatically marks sensitive values
static String get jwtSecretKey => _getEnvVar('JWT_SECRET_KEY', 
  fallback: 'default-secret-key', sensitive: true); // Logs as [HIDDEN]

// Get configuration without logging sensitive data
Map<String, dynamic> config = AppConfig.getAllConfig(includeSensitive: false);
```

## 🔧 Advanced Features

### **Configuration Validation**
```dart
void main() async {
  await AppConfig.initialize();
  
  // Validate required configurations
  if (!AppConfig.validateConfig()) {
    Logger.error('Main', 'Configuration validation failed');
    // Handle invalid configuration
  }
}
```

### **Runtime Configuration Reload**
```dart
// Reload configuration during runtime
await AppConfig.reload(fileName: '.env.staging');
```

### **Dynamic Configuration Access**
```dart
// Access configuration by key name
String value = AppConfig.getConfigValue('CUSTOM_CONFIG_KEY', fallback: 'default');

// Check if configuration exists
if (AppConfig.hasConfigValue('OPTIONAL_FEATURE_FLAG')) {
  // Use optional configuration
}
```

### **Configuration Debugging**
```dart
// Get all configuration for debugging
Map<String, dynamic> allConfig = AppConfig.getAllConfig();
Logger.logObject('Debug', 'allConfig', allConfig);

// Get configuration statistics
Logger.info('Config', 'Configuration loaded: ${AppConfig.isInitialized}');
Logger.info('Config', 'Environment: ${AppConfig.environment}');
```

## 🚨 Troubleshooting

### **Common Issues:**

#### **Configuration Not Loading**
```dart
// Check if initialized
if (!AppConfig.isInitialized) {
  Logger.error('Config', 'Configuration not initialized');
  await AppConfig.initialize();
}
```

#### **Missing Environment Variables**
```dart
// Use fallback values
static String get apiUrl => _getEnvVar('API_URL', fallback: 'https://localhost:3000');
```

#### **Environment Detection Issues**
```dart
// Debug environment detection
Logger.info('Config', 'Environment: ${AppConfig.environment}');
Logger.info('Config', 'Is Development: ${AppConfig.isDevelopment}');
Logger.info('Config', 'Is Production: ${AppConfig.isProduction}');
```

### **Debug Configuration Loading**
```dart
void debugConfiguration() {
  Logger.header('Configuration Debug');
  Logger.info('Config', 'Initialized: ${AppConfig.isInitialized}');
  Logger.info('Config', 'App Name: ${AppConfig.appName}');
  Logger.info('Config', 'Environment: ${AppConfig.environment}');
  Logger.info('Config', 'Database: ${AppConfig.databaseName}');
  Logger.info('Config', 'API URL: ${AppConfig.apiBaseUrl}');
  
  // Validate all required configs
  AppConfig.validateConfig();
}
```

## 📱 Team Workflow

### **For New Team Members:**
1. **Clone repository**
2. **Copy example file:** `cp .env.example .env`
3. **Get credentials** from team lead
4. **Update .env** with actual values
5. **Test configuration:** `flutter run`

### **For Environment Updates:**
1. **Update .env.example** with new variables
2. **Document changes** in team chat/wiki
3. **Update all environments** (.env.development, .env.production)
4. **Test thoroughly** before deployment

### **For Production Deployment:**
1. **Create production .env** with production credentials
2. **Validate configuration** using `AppConfig.validateConfig()`
3. **Test in staging** environment first
4. **Deploy with proper .env** file

This configuration system provides a robust, secure, and maintainable way to manage your app's settings across all environments! 🎯