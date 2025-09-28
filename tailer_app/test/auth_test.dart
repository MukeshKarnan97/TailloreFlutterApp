import 'package:flutter_test/flutter_test.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/data/services/auth_service.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('should successfully sign in with valid credentials', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'TestPassword123';

      // Act
      final result = await authService.signIn(
        email: email,
        password: password,
        keepSignedIn: false,
      );

      // Assert
      expect(result, isTrue);
      expect(authService.isLoggedIn, isTrue);
      expect(authService.currentUserEmail, equals(email));
    });

    test('should fail sign in with invalid password', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'short'; // Less than minimum length

      // Act & Assert
      expect(
        () => authService.signIn(email: email, password: password),
        throwsA(isA<AuthException>()),
      );
    });

    test('should sign out successfully', () async {
      // Arrange
      await authService.signIn(
        email: 'test@example.com',
        password: 'TestPassword123',
      );

      // Act
      await authService.signOut();

      // Assert
      expect(authService.isLoggedIn, isFalse);
      expect(authService.currentUserEmail, isNull);
    });

    test('should handle forgot password request', () async {
      // Arrange
      const email = 'test@example.com';

      // Act & Assert - Should not throw any exception
      await expectLater(
        authService.forgotPassword(email),
        completes,
      );
    });
  });

  group('AppConstants Tests', () {
    test('should have correct validation patterns', () {
      // Test email pattern
      final emailRegex = RegExp(AppConstants.emailPattern);
      
      expect(emailRegex.hasMatch('valid@example.com'), isTrue);
      expect(emailRegex.hasMatch('user.name+tag@domain.co.uk'), isTrue);
      expect(emailRegex.hasMatch('invalid-email'), isFalse);
      expect(emailRegex.hasMatch('@domain.com'), isFalse);
      
      // Test password pattern
      final passwordRegex = RegExp(AppConstants.passwordPattern);
      
      expect(passwordRegex.hasMatch('Password123'), isTrue);
      expect(passwordRegex.hasMatch('Test1'), isTrue);
      expect(passwordRegex.hasMatch('password123'), isFalse); // No uppercase
      expect(passwordRegex.hasMatch('PASSWORD123'), isFalse); // No lowercase
      expect(passwordRegex.hasMatch('Password'), isFalse); // No number
    });

    test('should have correct minimum password length', () {
      expect(AppConstants.minPasswordLength, equals(8));
    });

    test('should have correct error messages', () {
      expect(AppConstants.emailRequiredError, isNotEmpty);
      expect(AppConstants.passwordRequiredError, isNotEmpty);
      expect(AppConstants.signInSuccessMessage, isNotEmpty);
    });
  });
}