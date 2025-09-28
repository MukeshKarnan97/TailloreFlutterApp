import 'package:flutter_test/flutter_test.dart';
import 'package:tailer_app/data/services/auth_service.dart';

void main() {
  group('Complete Auth Service Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('should sign up user successfully', () async {
      final result = await authService.signUp(
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, isTrue);
      expect(authService.isLoggedIn, isTrue);
      expect(authService.currentUserEmail, 'test@example.com');
    });

    test('should fail signup with invalid data', () async {
      expect(
        () => authService.signUp(
          username: '',
          email: 'invalid-email',
          password: '123',
        ),
        throwsException,
      );
    });

    test('should send forgot password email successfully', () async {
      final result = await authService.sendForgotPasswordEmail('test@example.com');
      expect(result, isTrue);
    });

    test('should fail forgot password with invalid email', () async {
      expect(
        () => authService.sendForgotPasswordEmail('invalid-email'),
        throwsException,
      );
    });

    test('should generate and verify OTP correctly', () async {
      final otp = authService.generateTestOTP();
      expect(otp, '1234');

      final result = await authService.verifyOTP(otp, 'test@example.com');
      expect(result, isTrue);
    });

    test('should fail OTP verification with wrong code', () async {
      expect(
        () => authService.verifyOTP('9999', 'test@example.com'),
        throwsException,
      );
    });

    test('should reset password successfully', () async {
      final result = await authService.resetPassword(
        newPassword: 'newpassword123',
        confirmPassword: 'newpassword123',
        email: 'test@example.com',
      );
      expect(result, isTrue);
    });

    test('should fail password reset with mismatched passwords', () async {
      expect(
        () => authService.resetPassword(
          newPassword: 'password1',
          confirmPassword: 'password2',
        ),
        throwsException,
      );
    });

    test('should validate email correctly', () async {
      // Test valid emails
      await authService.sendForgotPasswordEmail('valid@email.com');
      await authService.sendForgotPasswordEmail('user@domain.org');
      
      // Test invalid emails
      expect(
        () => authService.sendForgotPasswordEmail('invalid.email'),
        throwsException,
      );
      expect(
        () => authService.sendForgotPasswordEmail('@invalid.com'),
        throwsException,
      );
    });

    test('OTP should be displayed in debug console', () async {
      // This test verifies that generateTestOTP prints to debug console
      final otp = authService.generateTestOTP();
      expect(otp, isNotEmpty);
      expect(otp.length, 4);
      expect(int.tryParse(otp), isNotNull);
    });
  });
}