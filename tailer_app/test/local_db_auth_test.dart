import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tailer_app/data/services/auth_service.dart';
import 'package:tailer_app/data/repositories/user_repository.dart';
import 'package:tailer_app/data/services/local_db_service.dart';

void main() {
  // Initialize SQLite and environment for testing
  setUpAll(() async {
    // Initialize the database factory for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    // Initialize SharedPreferences with mock values for testing
    SharedPreferences.setMockInitialValues({});
    
    // Initialize dotenv with basic test values
    try {
      await dotenv.load(fileName: '.env.test');
    } catch (e) {
      // If .env.test doesn't exist, load from memory
      await dotenv.load(mergeWith: {
        'APP_NAME': 'Tailor App Test',
        'APP_VERSION': '1.0.0',
        'ENVIRONMENT': 'test',
        'DATABASE_NAME': 'tailor_app_test.db',
        'DATABASE_VERSION': '1',
        'JWT_SECRET_KEY': 'test_secret_key',
        'AUTH_TOKEN_EXPIRY_HOURS': '24',
        'LOG_LEVEL': 'INFO',
        'API_BASE_URL': 'http://localhost:3000',
        'ENABLE_BIOMETRIC_AUTH': 'true',
        'DEFAULT_THEME': 'light',
        'ENABLE_DEBUG_MODE': 'true',
      });
    }
  });
  group('Local Database Authentication Tests', () {
    late AuthService authService;
    late UserRepository userRepository;
    late LocalDatabaseService dbService;

    setUp(() async {
      authService = AuthService();
      userRepository = UserRepository();
      dbService = LocalDatabaseService();
      
      // Clean up any existing data
      try {
        await dbService.clearAllData();
      } catch (e) {
        // Database might not exist yet, that's okay
      }
    });

    tearDown(() async {
      try {
        await dbService.clearAllData();
        await dbService.closeDatabase();
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('should create user and authenticate successfully', () async {
      // Test user registration
      final user = await authService.signUpNewUser(
        username: 'testuser',
        email: 'test@example.com',
        password: 'testpass123',
        phone: '+1234567890',
      );

      expect(user.username, equals('testuser'));
      expect(user.email, equals('test@example.com'));
      expect(user.id, isNotNull);

      // Test user authentication
      final signInResult = await authService.signIn(
        email: 'test@example.com',
        password: 'testpass123',
        keepSignedIn: true,
      );

      expect(signInResult, isTrue);
      expect(authService.isLoggedIn, isTrue);
      expect(authService.currentUserEmail, equals('test@example.com'));
    });

    test('should handle invalid credentials properly', () async {
      // Try to sign in with non-existent user
      expect(
        () => authService.signIn(
          email: 'nonexistent@example.com',
          password: 'wrongpass',
        ),
        throwsException,
      );
    });

    test('should manage user preferences correctly', () async {
      // Create user
      final user = await authService.signUpNewUser(
        username: 'prefuser',
        email: 'prefs@example.com',
        password: 'testpass123',
      );

      // Get default preferences
      final defaultPrefs = await userRepository.getPreferences(user.id);
      expect(defaultPrefs.themeMode, equals('system'));
      expect(defaultPrefs.language, equals('en'));
      expect(defaultPrefs.notificationsEnabled, isTrue);

      // Update preferences
      final updatedPrefs = await userRepository.updatePreferences(
        userId: user.id,
        themeMode: 'dark',
        language: 'es',
        notificationsEnabled: false,
      );

      expect(updatedPrefs.themeMode, equals('dark'));
      expect(updatedPrefs.language, equals('es'));
      expect(updatedPrefs.notificationsEnabled, isFalse);
    });

    test('should validate email and username uniqueness', () async {
      // Create first user
      await authService.signUpNewUser(
        username: 'uniqueuser',
        email: 'unique@example.com',
        password: 'testpass123',
      );

      // Try to create user with same email
      expect(
        () => authService.signUpNewUser(
          username: 'differentuser',
          email: 'unique@example.com',
          password: 'testpass123',
        ),
        throwsException,
      );

      // Try to create user with same username
      expect(
        () => authService.signUpNewUser(
          username: 'uniqueuser',
          email: 'different@example.com',
          password: 'testpass123',
        ),
        throwsException,
      );
    });

    test('should handle password validation correctly', () async {
      // Test weak password
      expect(
        () => authService.signUpNewUser(
          username: 'weakuser',
          email: 'weak@example.com',
          password: '123',
        ),
        throwsException,
      );

      // Test empty username
      expect(
        () => authService.signUpNewUser(
          username: '',
          email: 'empty@example.com',
          password: 'validpass123',
        ),
        throwsException,
      );

      // Test invalid email
      expect(
        () => authService.signUpNewUser(
          username: 'validuser',
          email: 'invalidemail',
          password: 'validpass123',
        ),
        throwsException,
      );
    });

    test('should check username and email availability', () async {
      // Create a user
      await authService.signUpNewUser(
        username: 'takenuser',
        email: 'taken@example.com',
        password: 'testpass123',
      );

      // Check availability
      expect(await authService.isUsernameAvailable('takenuser'), isFalse);
      expect(await authService.isEmailAvailable('taken@example.com'), isFalse);
      expect(await authService.isUsernameAvailable('availableuser'), isTrue);
      expect(await authService.isEmailAvailable('available@example.com'), isTrue);
    });

    test('should handle OTP verification correctly', () async {
      const testOTP = '1234';
      const email = 'otp@example.com';

      // Generate OTP
      final generatedOTP = authService.generateTestOTP();
      expect(generatedOTP, equals(testOTP));

      // Verify correct OTP
      final verifyResult = await authService.verifyOTP(testOTP, email);
      expect(verifyResult, isTrue);

      // Try wrong OTP
      expect(
        () => authService.verifyOTP('9999', email),
        throwsA(isA<AuthException>()),
      );
    });

    test('should manage auth sessions properly', () async {
      // Create and sign in user
      await authService.signUpNewUser(
        username: 'sessionuser',
        email: 'session@example.com',
        password: 'testpass123',
      );

      await authService.signIn(
        email: 'session@example.com',
        password: 'testpass123',
        keepSignedIn: true,
      );

      expect(authService.isLoggedIn, isTrue);
      expect(authService.currentSession, isNotNull);

      // Sign out
      await authService.signOut();
      expect(authService.isLoggedIn, isFalse);
      expect(authService.currentUser, isNull);
    });

    test('should handle database operations correctly', () async {
      // Test database stats
      final initialStats = await dbService.getDatabaseStats();
      expect(initialStats['users'], equals(0));

      // Create user
      await authService.signUpNewUser(
        username: 'dbuser',
        email: 'db@example.com',
        password: 'testpass123',
      );

      final updatedStats = await dbService.getDatabaseStats();
      expect(updatedStats['users'], equals(1));
      expect(updatedStats['user_preferences'], equals(1));
    });
  });
}