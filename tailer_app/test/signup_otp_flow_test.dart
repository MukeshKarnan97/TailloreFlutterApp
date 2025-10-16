import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/features/auth/screens/signup_screen.dart';
import 'package:tailer_app/features/auth/screens/otp_screen.dart';

void main() {
  group('Signup to OTP Flow Tests', () {
    
    testWidgets('should navigate to OTP screen after successful signup', (WidgetTester tester) async {
      // Create a mock GoRouter for testing navigation
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const SignUp(),
          ),
          GoRoute(
            path: '/auth/otp',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return VerificationScreen(
                firstTitle: extra?['firstTitle'] ?? 'EMAIL',
                secondTitle: extra?['secondTitle'] ?? 'VERIFICATION',
                emailText: extra?['emailText'] ?? '',
                email: extra?['email'],
                onVerified: extra?['onVerified'] ?? () {},
              );
            },
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Find the signup screen elements
      expect(find.byType(SignUp), findsOneWidget);
      expect(find.text('SIGN UP'), findsOneWidget);
      
      // Verify form fields are present
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('should show OTP screen with correct test message', (WidgetTester tester) async {
      // Arrange
      void onVerified() {}

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: VerificationScreen(
            firstTitle: 'EMAIL',
            secondTitle: 'VERIFICATION',
            emailText: 'Verification code sent to test@example.com',
            email: 'test@example.com',
            onVerified: onVerified,
          ),
        ),
      );

      // Assert
      expect(find.text('EMAIL VERIFICATION'), findsOneWidget);
      expect(find.text('Verification code sent to test@example.com'), findsOneWidget);
      expect(find.text('For testing: Use OTP 1234'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Verify OTP input fields are present
      expect(find.byType(TextField), findsNWidgets(4)); // 4 OTP input fields
    });

    testWidgets('should validate OTP correctly with hardcoded value', (WidgetTester tester) async {
      // Arrange
      bool verified = false;
      void onVerified() {
        verified = true;
      }

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: VerificationScreen(
            firstTitle: 'EMAIL',
            secondTitle: 'VERIFICATION',
            emailText: 'Verification code sent to test@example.com',
            email: 'test@example.com',
            onVerified: onVerified,
          ),
        ),
      );

      // Find OTP input fields and enter correct OTP
      final otpFields = find.byType(TextFormField);
      expect(otpFields, findsNWidgets(4));

      // Enter correct OTP: 1234
      await tester.enterText(otpFields.at(0), '1');
      await tester.enterText(otpFields.at(1), '2');
      await tester.enterText(otpFields.at(2), '3');
      await tester.enterText(otpFields.at(3), '4');

      // Tap Next button
      await tester.tap(find.text('Next'));
      await tester.pump(); // Initial pump
      
      // Wait for the async operation to complete
      await tester.pump(const Duration(seconds: 2));
      
      // Assert verification was called
      expect(verified, isTrue);
    });

    testWidgets('should show error for incorrect OTP', (WidgetTester tester) async {
      // Arrange
      bool verified = false;
      void onVerified() {
        verified = true;
      }

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: VerificationScreen(
            firstTitle: 'EMAIL',
            secondTitle: 'VERIFICATION',
            emailText: 'Verification code sent to test@example.com',
            email: 'test@example.com',
            onVerified: onVerified,
          ),
        ),
      );

      // Find OTP input fields and enter incorrect OTP
      final otpFields = find.byType(TextFormField);

      // Enter incorrect OTP: 5678
      await tester.enterText(otpFields.at(0), '5');
      await tester.enterText(otpFields.at(1), '6');
      await tester.enterText(otpFields.at(2), '7');
      await tester.enterText(otpFields.at(3), '8');

      // Tap Next button
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Assert verification was not called and error is shown
      expect(verified, isFalse);
      expect(find.text('Invalid OTP. Please enter 1234.'), findsOneWidget);
    });

    testWidgets('should show error for incomplete OTP', (WidgetTester tester) async {
      // Arrange
      bool verified = false;
      void onVerified() {
        verified = true;
      }

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: VerificationScreen(
            firstTitle: 'EMAIL',
            secondTitle: 'VERIFICATION',
            emailText: 'Verification code sent to test@example.com',
            email: 'test@example.com',
            onVerified: onVerified,
          ),
        ),
      );

      // Find OTP input fields and enter incomplete OTP
      final otpFields = find.byType(TextFormField);

      // Enter incomplete OTP: only 12
      await tester.enterText(otpFields.at(0), '1');
      await tester.enterText(otpFields.at(1), '2');

      // Tap Next button
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Assert verification was not called and error is shown
      expect(verified, isFalse);
      expect(find.text('Please enter complete OTP'), findsOneWidget);
    });
  });
}