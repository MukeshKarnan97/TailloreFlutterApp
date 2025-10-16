/// Comprehensive Test Cases for Registration and OTP Verification
/// Tests all scenarios including success, failure, edge cases, and API response formats
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tailer_app/data/models/account/auth_models.dart';

void main() {
  group('Registration Tests', () {
    group('RegisterRequest', () {
      test('should create valid registration request with all fields', () {
        final request = RegisterRequest(
          email: 'test@example.com',
          password: 'Test@1234',
          passwordConfirm: 'Test@1234',
          name: 'John Doe',
          shopName: 'John\'s Tailoring',
          phone: '+1234567890',
          address: '123 Main St',
          authProvider: 'email',
        );

        final json = request.toJson();

        expect(json['email'], 'test@example.com');
        expect(json['password'], 'Test@1234');
        expect(json['password_confirm'], 'Test@1234');
        expect(json['name'], 'John Doe');
        expect(json['shop_name'], 'John\'s Tailoring');
        expect(json['phone'], '+1234567890');
        expect(json['address'], '123 Main St');
        expect(json['auth_provider'], 'email');
      });

      test('should create request with default values', () {
        final request = RegisterRequest(
          email: 'test@example.com',
          password: 'Test@1234',
          passwordConfirm: 'Test@1234',
          name: 'John Doe',
          shopName: 'John\'s Tailoring',
          phone: '+1234567890',
        );

        final json = request.toJson();

        expect(json['address'], '');
        expect(json['auth_provider'], 'email');
      });

      test('should handle special characters in fields', () {
        final request = RegisterRequest(
          email: 'test+tag@example.com',
          password: 'P@ssw0rd!#\$',
          passwordConfirm: 'P@ssw0rd!#\$',
          name: 'O\'Brien & Sons',
          shopName: 'Best "Tailor" Shop',
          phone: '+1-234-567-8900',
          address: '123 Main St, Apt #456',
        );

        final json = request.toJson();

        expect(json['email'], 'test+tag@example.com');
        expect(json['name'], 'O\'Brien & Sons');
        expect(json['shop_name'], 'Best "Tailor" Shop');
      });
    });

    group('RegisterResponse - Direct Format', () {
      test('should parse direct format response successfully', () {
        final jsonResponse = {
          'user': {
            'id': 1,
            'email': 'test@example.com',
            'name': 'John Doe',
            'shop_name': 'John\'s Tailoring',
            'phone': '+1234567890',
            'address': '123 Main St',
            'auth_provider': 'email',
            'created_at': '2024-01-15T10:30:00Z',
            'updated_at': '2024-01-15T10:30:00Z',
          },
          'tokens': {
            'access': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.access',
            'refresh': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.refresh',
          },
          'message': 'Registration successful',
        };

        final response = RegisterResponse.fromJson(jsonResponse);

        expect(response.user.email, 'test@example.com');
        expect(response.user.name, 'John Doe');
        expect(response.user.shopName, 'John\'s Tailoring');
        expect(response.accessToken, contains('access'));
        expect(response.refreshToken, contains('refresh'));
        expect(response.message, 'Registration successful');
      });
    });

    group('RegisterResponse - Wrapped Format (Django)', () {
      test('should parse Django wrapped format response successfully', () {
        final jsonResponse = {
          'success': true,
          'data': {
            'tailor': {
              'id': 1,
              'email': 'test@example.com',
              'name': 'John Doe',
              'shop_name': 'John\'s Tailoring',
              'phone': '+1234567890',
              'address': '123 Main St',
              'auth_provider': 'email',
              'created_at': '2024-01-15T10:30:00Z',
              'updated_at': '2024-01-15T10:30:00Z',
            },
            'tokens': {
              'access': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.access',
              'refresh': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.refresh',
            },
          },
          'message': 'User registered successfully',
        };

        final response = RegisterResponse.fromJson(jsonResponse);

        expect(response.user.email, 'test@example.com');
        expect(response.user.name, 'John Doe');
        expect(response.user.shopName, 'John\'s Tailoring');
        expect(response.accessToken, contains('access'));
        expect(response.refreshToken, contains('refresh'));
        expect(response.message, 'User registered successfully');
      });

      test('should handle wrapped format with nullable phone', () {
        final jsonResponse = {
          'success': true,
          'data': {
            'tailor': {
              'id': 1,
              'email': 'test@example.com',
              'name': 'John Doe',
              'shop_name': 'John\'s Tailoring',
              'phone': null, // Nullable phone
              'address': '',
              'auth_provider': 'email',
              'created_at': '2024-01-15T10:30:00Z',
              'updated_at': '2024-01-15T10:30:00Z',
            },
            'tokens': {
              'access': 'access_token',
              'refresh': 'refresh_token',
            },
          },
        };

        final response = RegisterResponse.fromJson(jsonResponse);

        expect(response.user.phone, ''); // Tailor model converts null to empty string
        expect(response.user.email, 'test@example.com');
      });
    });

    group('RegisterResponse - Error Cases', () {
      test('should handle missing user data gracefully', () {
        final jsonResponse = {
          'tokens': {
            'access': 'access_token',
            'refresh': 'refresh_token',
          },
        };

        expect(
          () => RegisterResponse.fromJson(jsonResponse),
          throwsA(isA<TypeError>()),
        );
      });

      test('should handle missing tokens gracefully', () {
        final jsonResponse = {
          'user': {
            'id': 1,
            'email': 'test@example.com',
            'name': 'John Doe',
            'shop_name': 'John\'s Tailoring',
          },
        };

        expect(
          () => RegisterResponse.fromJson(jsonResponse),
          throwsA(isA<TypeError>()),
        );
      });
    });
  });

  group('OTP Verification Tests', () {
    group('VerifyOTPRequest', () {
      test('should create valid OTP verification request', () {
        final request = VerifyOTPRequest(
          email: 'test@example.com',
          otpCode: '123456',
          otpType: 'registration',
        );

        final json = request.toJson();

        expect(json['email'], 'test@example.com');
        expect(json['otp_code'], '123456');
        expect(json['otp_type'], 'registration');
      });

      test('should use default OTP type', () {
        final request = VerifyOTPRequest(
          email: 'test@example.com',
          otpCode: '123456',
        );

        final json = request.toJson();

        expect(json['otp_type'], 'registration');
      });

      test('should handle different OTP types', () {
        final resetRequest = VerifyOTPRequest(
          email: 'test@example.com',
          otpCode: '654321',
          otpType: 'password_reset',
        );

        final json = resetRequest.toJson();

        expect(json['otp_type'], 'password_reset');
      });
    });

    group('VerifyOTPResponse - Direct Format', () {
      test('should parse direct format response successfully', () {
        final jsonResponse = {
          'success': true,
          'message': 'OTP verified successfully',
          'user': {
            'id': 1,
            'email': 'test@example.com',
            'name': 'John Doe',
            'shop_name': 'John\'s Tailoring',
            'phone': '+1234567890',
            'address': '123 Main St',
            'auth_provider': 'email',
            'created_at': '2024-01-15T10:30:00Z',
            'updated_at': '2024-01-15T10:35:00Z',
          },
        };

        final response = VerifyOTPResponse.fromJson(jsonResponse);

        expect(response.success, true);
        expect(response.message, 'OTP verified successfully');
        expect(response.user?.email, 'test@example.com');
      });

      test('should use default values when missing', () {
        final jsonResponse = {
          'user': {
            'id': 1,
            'email': 'test@example.com',
            'name': 'John Doe',
            'shop_name': 'John\'s Tailoring',
            'created_at': '2024-01-15T10:30:00Z',
            'updated_at': '2024-01-15T10:35:00Z',
          },
        };

        final response = VerifyOTPResponse.fromJson(jsonResponse);

        expect(response.success, true); // Default value
        expect(response.message, 'OTP verified successfully'); // Default value
      });
    });

    group('VerifyOTPResponse - Wrapped Format (Django)', () {
      test('should parse Django wrapped format with tailor key', () {
        final jsonResponse = {
          'success': true,
          'data': {
            'tailor': {
              'id': 1,
              'email': 'test@example.com',
              'name': 'John Doe',
              'shop_name': 'John\'s Tailoring',
              'phone': '+1234567890',
              'created_at': '2024-01-15T10:30:00Z',
              'updated_at': '2024-01-15T10:35:00Z',
            },
          },
          'message': 'Account activated successfully',
        };

        final response = VerifyOTPResponse.fromJson(jsonResponse);

        expect(response.success, true);
        expect(response.message, 'Account activated successfully');
        expect(response.user?.email, 'test@example.com');
      });

      test('should parse Django wrapped format with user key', () {
        final jsonResponse = {
          'success': true,
          'data': {
            'user': {
              'id': 1,
              'email': 'test@example.com',
              'name': 'John Doe',
              'shop_name': 'John\'s Tailoring',
              'created_at': '2024-01-15T10:30:00Z',
              'updated_at': '2024-01-15T10:35:00Z',
            },
          },
          'message': 'Verified',
        };

        final response = VerifyOTPResponse.fromJson(jsonResponse);

        expect(response.user?.email, 'test@example.com');
      });
    });

    group('VerifyOTPResponse - Error Cases', () {
      test('should throw FormatException when JSON is null', () {
        expect(
          () => VerifyOTPResponse.fromJson(null),
          throwsA(isA<FormatException>()),
        );
      });

      test('should handle minimal Django response without user data', () {
        // This is the actual Django response format
        final jsonResponse = {
          'success': true,
          'message': 'Email verified successfully',
        };

        final response = VerifyOTPResponse.fromJson(jsonResponse);

        expect(response.success, true);
        expect(response.message, 'Email verified successfully');
        expect(response.user, isNull); // User data not provided
      });

      test('should handle minimal response with custom message', () {
        final jsonResponse = {
          'success': true,
          'message': 'OTP verified and account activated',
        };

        final response = VerifyOTPResponse.fromJson(jsonResponse);

        expect(response.success, true);
        expect(response.message, 'OTP verified and account activated');
        expect(response.user, isNull);
      });
    });

    group('ResendOTPRequest', () {
      test('should create valid resend OTP request', () {
        final request = ResendOTPRequest(
          email: 'test@example.com',
          otpType: 'registration',
        );

        final json = request.toJson();

        expect(json['email'], 'test@example.com');
        expect(json['otp_type'], 'registration');
      });

      test('should use default OTP type', () {
        final request = ResendOTPRequest(
          email: 'test@example.com',
        );

        final json = request.toJson();

        expect(json['otp_type'], 'registration');
      });
    });
  });

  group('Integration Scenarios', () {
    test('Complete registration flow data transformation', () {
      // Step 1: Create registration request
      final registerRequest = RegisterRequest(
        email: 'mukesh.dmc97@gmail.com',
        password: 'SecurePass@123',
        passwordConfirm: 'SecurePass@123',
        name: 'Mukesh Kumar',
        shopName: 'Mukesh Tailoring',
        phone: '+919876543210',
        address: 'Chennai, India',
      );

      final reqJson = registerRequest.toJson();
      expect(reqJson['email'], 'mukesh.dmc97@gmail.com');

      // Step 2: Parse registration response (Django format)
      final registerResponseJson = {
        'success': true,
        'data': {
          'tailor': {
            'id': 42,
            'email': 'mukesh.dmc97@gmail.com',
            'name': 'Mukesh Kumar',
            'shop_name': 'Mukesh Tailoring',
            'phone': '+919876543210',
            'address': 'Chennai, India',
            'auth_provider': 'email',
            'created_at': '2024-01-15T10:30:00Z',
            'updated_at': '2024-01-15T10:30:00Z',
          },
          'tokens': {
            'access': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.access_token_here',
            'refresh': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.refresh_token_here',
          },
        },
        'message': 'Registration successful. OTP sent to email.',
      };

      final registerResponse = RegisterResponse.fromJson(registerResponseJson);
      expect(registerResponse.user.email, 'mukesh.dmc97@gmail.com');
      expect(registerResponse.accessToken, isNotEmpty);

      // Step 3: Create OTP verification request
      final otpRequest = VerifyOTPRequest(
        email: 'mukesh.dmc97@gmail.com',
        otpCode: '123456',
        otpType: 'registration',
      );

      final otpReqJson = otpRequest.toJson();
      expect(otpReqJson['otp_code'], '123456');

      // Step 4: Parse OTP verification response
      final otpResponseJson = {
        'success': true,
        'data': {
          'tailor': {
            'id': 42,
            'email': 'mukesh.dmc97@gmail.com',
            'name': 'Mukesh Kumar',
            'shop_name': 'Mukesh Tailoring',
            'phone': '+919876543210',
            'address': 'Chennai, India',
            'auth_provider': 'email',
            'created_at': '2024-01-15T10:30:00Z',
            'updated_at': '2024-01-15T10:35:00Z',
          },
        },
        'message': 'Account activated successfully',
      };

      final otpResponse = VerifyOTPResponse.fromJson(otpResponseJson);
      expect(otpResponse.success, true);
      expect(otpResponse.user?.email, 'mukesh.dmc97@gmail.com');
      expect(otpResponse.user?.id, '42');
    });

    test('Handle OTP resend flow', () {
      // User didn't receive OTP, request resend
      final resendRequest = ResendOTPRequest(
        email: 'mukesh.dmc97@gmail.com',
        otpType: 'registration',
      );

      final json = resendRequest.toJson();
      expect(json['email'], 'mukesh.dmc97@gmail.com');
      expect(json['otp_type'], 'registration');
    });
  });

  group('Edge Cases and Boundary Tests', () {
    test('should handle empty optional fields', () {
      final request = RegisterRequest(
        email: 'test@example.com',
        password: 'Pass@123',
        passwordConfirm: 'Pass@123',
        name: 'Test User',
        shopName: 'Test Shop',
        phone: '',
        address: '',
      );

      final json = request.toJson();
      expect(json['phone'], '');
      expect(json['address'], '');
    });

    test('should handle very long OTP codes', () {
      final request = VerifyOTPRequest(
        email: 'test@example.com',
        otpCode: '123456789012',
      );

      final json = request.toJson();
      expect(json['otp_code'], '123456789012');
    });

    test('should handle Unicode characters in names', () {
      final request = RegisterRequest(
        email: 'test@example.com',
        password: 'Pass@123',
        passwordConfirm: 'Pass@123',
        name: 'मुकेश कुमार', // Hindi characters
        shopName: '北京裁缝店', // Chinese characters
        phone: '+1234567890',
      );

      final json = request.toJson();
      expect(json['name'], 'मुकेश कुमार');
      expect(json['shop_name'], '北京裁缝店');
    });

    test('should handle email with multiple dots and plus signs', () {
      final request = RegisterRequest(
        email: 'test.user+tag@sub.domain.example.com',
        password: 'Pass@123',
        passwordConfirm: 'Pass@123',
        name: 'Test',
        shopName: 'Shop',
        phone: '1234567890',
      );

      final json = request.toJson();
      expect(json['email'], 'test.user+tag@sub.domain.example.com');
    });
  });
}
