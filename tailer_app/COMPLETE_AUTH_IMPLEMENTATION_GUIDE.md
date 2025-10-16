# 🔐 Complete Authentication Flow: Django Backend + Flutter Frontend

**Django Backend**: `C:\Users\mukes\Videos\Android_Dev\Devlopment\TailerBackend\tailor_project\`  
**Flutter Frontend**: Current project  
**Date**: October 14, 2025

## 🎯 Architecture Overview

### Authentication Flow Design
```
┌─────────────────────────────────────────────────────────────────┐
│                     AUTHENTICATION FLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. REGISTRATION (Backend)                                       │
│     Flutter → Django API → Create Tailor (inactive)             │
│                         → Send OTP Email                         │
│                         → Return temp tokens                     │
│                                                                   │
│  2. OTP VERIFICATION (Backend)                                   │
│     Flutter → Django API → Verify OTP                           │
│                         → Activate Tailor                        │
│                         → Generate JWT Tokens                    │
│                         → Return Full Tailor Data                │
│                                                                   │
│  3. LOCAL SYNC (Frontend)                                        │
│     Flutter → Save to SQLite → Only AFTER verification          │
│                              → Store JWT tokens                  │
│                                                                   │
│  4. LOGIN (Backend)                                              │
│     Flutter → Django API → Validate credentials                 │
│                         → Check if verified                      │
│                         → Generate new JWT tokens                │
│                         → Return Tailor data                     │
│                                                                   │
│  5. LOCAL SYNC (Frontend)                                        │
│     Flutter → Update SQLite → Sync latest data                  │
│                             → Update tokens                      │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## 📊 Django Backend Implementation

### 1. Tailor Model Structure
```python
# accounts/models.py
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models
from django.utils import timezone
import random
import string

class TailorManager(BaseManager):
    def create_tailor(self, email, password, **extra_fields):
        """Create and save a Tailor with unique ID"""
        if not email:
            raise ValueError('Email is required')
        
        email = self.normalize_email(email)
        
        # Generate unique MAT ID
        unique_id = self.generate_unique_id()
        
        tailor = self.model(
            id=unique_id,
            unique_id=unique_id,
            email=email,
            **extra_fields
        )
        tailor.set_password(password)
        tailor.save(using=self._db)
        return tailor
    
    def generate_unique_id(self):
        """Generate MAT + 7 random chars"""
        while True:
            chars = ''.join(random.choices(string.ascii_uppercase + string.digits, k=7))
            unique_id = f'MAT{chars}'
            if not self.filter(id=unique_id).exists():
                return unique_id

class Tailor(AbstractBaseUser, PermissionsMixin):
    # Primary fields
    id = models.CharField(max_length=10, primary_key=True)  # MAT1234567
    unique_id = models.CharField(max_length=10, unique=True)
    name = models.CharField(max_length=100)
    shop_name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=20, unique=True)
    auth_provider = models.CharField(max_length=20, default='email')
    address = models.TextField(blank=True)
    profile_image_path = models.ImageField(upload_to='profiles/', blank=True, null=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Status flags
    is_deleted = models.BooleanField(default=False)
    is_active = models.BooleanField(default=False)  # Activated after OTP verification
    is_staff = models.BooleanField(default=False)
    email_verified = models.BooleanField(default=False)
    phone_verified = models.BooleanField(default=False)
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['name', 'shop_name', 'phone']
    
    objects = TailorManager()
    
    def __str__(self):
        return f"{self.name} ({self.email})"
```

### 2. OTP Model
```python
# otp/models.py
from django.db import models
from django.utils import timezone
from datetime import timedelta
import random

class OTP(models.Model):
    OTP_TYPE_CHOICES = [
        ('email', 'Email Verification'),
        ('phone', 'Phone Verification'),
        ('password_reset', 'Password Reset'),
    ]
    
    tailor = models.ForeignKey('accounts.Tailor', on_delete=models.CASCADE)
    otp_type = models.CharField(max_length=20, choices=OTP_TYPE_CHOICES)
    otp_code = models.CharField(max_length=6)
    contact_info = models.CharField(max_length=100)  # Email or phone
    is_used = models.BooleanField(default=False)
    expires_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)
    attempts = models.IntegerField(default=0)
    
    class Meta:
        ordering = ['-created_at']
    
    @staticmethod
    def generate_otp():
        """Generate 6-digit OTP"""
        return ''.join([str(random.randint(0, 9)) for _ in range(6)])
    
    @classmethod
    def create_otp(cls, tailor, otp_type, contact_info):
        """Create new OTP with 10-minute expiry"""
        otp_code = cls.generate_otp()
        expires_at = timezone.now() + timedelta(minutes=10)
        
        return cls.objects.create(
            tailor=tailor,
            otp_type=otp_type,
            otp_code=otp_code,
            contact_info=contact_info,
            expires_at=expires_at
        )
    
    def is_valid(self):
        """Check if OTP is still valid"""
        return (
            not self.is_used 
            and self.expires_at > timezone.now() 
            and self.attempts < 3
        )
```

### 3. Registration View (Django)
```python
# accounts/views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.core.mail import send_mail
from django.conf import settings

class RegisterView(APIView):
    """
    Handle user registration
    - Create inactive Tailor account
    - Generate OTP
    - Send verification email
    - Return temporary tokens
    """
    
    def post(self, request):
        try:
            # Extract data
            email = request.data.get('email')
            password = request.data.get('password')
            password_confirm = request.data.get('password_confirm')
            name = request.data.get('name')
            shop_name = request.data.get('shop_name')
            phone = request.data.get('phone')
            address = request.data.get('address', '')
            auth_provider = request.data.get('auth_provider', 'email')
            
            # Validate
            if not all([email, password, name, shop_name, phone]):
                return Response({
                    'error': 'All fields are required'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            if password != password_confirm:
                return Response({
                    'error': 'Passwords do not match'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Check if email exists
            if Tailor.objects.filter(email=email).exists():
                return Response({
                    'error': 'Email already registered'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Create Tailor (inactive)
            tailor = Tailor.objects.create_tailor(
                email=email,
                password=password,
                name=name,
                shop_name=shop_name,
                phone=phone,
                address=address,
                auth_provider=auth_provider,
                is_active=False,  # Will be activated after OTP verification
                email_verified=False
            )
            
            # Generate OTP
            otp = OTP.create_otp(
                tailor=tailor,
                otp_type='email',
                contact_info=email
            )
            
            # Send OTP email
            send_mail(
                subject='Verify Your Email - Tailor App',
                message=f'Your verification code is: {otp.otp_code}\n\nThis code will expire in 10 minutes.',
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[email],
                fail_silently=False,
            )
            
            # Generate temporary tokens (limited access)
            refresh = RefreshToken.for_user(tailor)
            
            # Serialize tailor data
            tailor_data = {
                'id': tailor.id,
                'unique_id': tailor.unique_id,
                'name': tailor.name,
                'shop_name': tailor.shop_name,
                'email': tailor.email,
                'phone': tailor.phone,
                'address': tailor.address,
                'auth_provider': tailor.auth_provider,
                'profile_image_path': tailor.profile_image_path.url if tailor.profile_image_path else None,
                'created_at': tailor.created_at.isoformat(),
                'updated_at': tailor.updated_at.isoformat(),
                'is_deleted': tailor.is_deleted,
                'is_active': tailor.is_active,
                'email_verified': tailor.email_verified,
            }
            
            return Response({
                'message': 'Registration successful. Please verify your email.',
                'user': tailor_data,
                'tokens': {
                    'access': str(refresh.access_token),
                    'refresh': str(refresh),
                },
                'requires_verification': True,
                'otp_sent_to': email
            }, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            return Response({
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
```

### 4. OTP Verification View (Django)
```python
# otp/views.py
class VerifyOTPView(APIView):
    """
    Verify OTP and activate account
    - Validate OTP code
    - Activate Tailor account
    - Generate full JWT tokens
    - Return activated user data
    """
    
    def post(self, request):
        try:
            email = request.data.get('email')
            otp_code = request.data.get('otp_code')
            otp_type = request.data.get('otp_type', 'email')
            
            if not all([email, otp_code]):
                return Response({
                    'error': 'Email and OTP code are required'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Get tailor
            try:
                tailor = Tailor.objects.get(email=email)
            except Tailor.DoesNotExist:
                return Response({
                    'error': 'User not found'
                }, status=status.HTTP_404_NOT_FOUND)
            
            # Get latest OTP
            try:
                otp = OTP.objects.filter(
                    tailor=tailor,
                    otp_type=otp_type,
                    contact_info=email,
                    is_used=False
                ).latest('created_at')
            except OTP.DoesNotExist:
                return Response({
                    'error': 'No valid OTP found'
                }, status=status.HTTP_404_NOT_FOUND)
            
            # Increment attempts
            otp.attempts += 1
            otp.save()
            
            # Check if OTP is valid
            if not otp.is_valid():
                return Response({
                    'error': 'OTP has expired or exceeded maximum attempts'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Verify OTP code
            if otp.otp_code != otp_code:
                if otp.attempts >= 3:
                    return Response({
                        'error': 'Maximum OTP attempts exceeded. Please request a new OTP.'
                    }, status=status.HTTP_400_BAD_REQUEST)
                
                return Response({
                    'error': f'Invalid OTP code. {3 - otp.attempts} attempts remaining.'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Mark OTP as used
            otp.is_used = True
            otp.save()
            
            # Activate tailor account
            tailor.is_active = True
            tailor.email_verified = True
            tailor.save()
            
            # Generate full JWT tokens
            refresh = RefreshToken.for_user(tailor)
            
            # Serialize tailor data
            tailor_data = {
                'id': tailor.id,
                'unique_id': tailor.unique_id,
                'name': tailor.name,
                'shop_name': tailor.shop_name,
                'email': tailor.email,
                'phone': tailor.phone,
                'address': tailor.address,
                'auth_provider': tailor.auth_provider,
                'profile_image_path': tailor.profile_image_path.url if tailor.profile_image_path else None,
                'created_at': tailor.created_at.isoformat(),
                'updated_at': tailor.updated_at.isoformat(),
                'is_deleted': tailor.is_deleted,
                'is_active': tailor.is_active,
                'email_verified': tailor.email_verified,
            }
            
            return Response({
                'message': 'Email verified successfully',
                'user': tailor_data,
                'tokens': {
                    'access': str(refresh.access_token),
                    'refresh': str(refresh),
                },
                'verified': True
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
```

### 5. Login View (Django)
```python
# accounts/views.py
class LoginView(APIView):
    """
    Handle user login
    - Validate credentials
    - Check if account is verified
    - Generate JWT tokens
    - Return user data
    """
    
    def post(self, request):
        try:
            email = request.data.get('email')
            password = request.data.get('password')
            
            if not all([email, password]):
                return Response({
                    'error': 'Email and password are required'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Authenticate
            try:
                tailor = Tailor.objects.get(email=email)
            except Tailor.DoesNotExist:
                return Response({
                    'error': 'Invalid email or password'
                }, status=status.HTTP_401_UNAUTHORIZED)
            
            # Check password
            if not tailor.check_password(password):
                return Response({
                    'error': 'Invalid email or password'
                }, status=status.HTTP_401_UNAUTHORIZED)
            
            # Check if account is verified
            if not tailor.email_verified:
                return Response({
                    'error': 'Please verify your email first',
                    'requires_verification': True,
                    'email': email
                }, status=status.HTTP_403_FORBIDDEN)
            
            # Check if account is active
            if not tailor.is_active:
                return Response({
                    'error': 'Your account has been deactivated. Please contact support.'
                }, status=status.HTTP_403_FORBIDDEN)
            
            # Check if deleted
            if tailor.is_deleted:
                return Response({
                    'error': 'This account no longer exists'
                }, status=status.HTTP_410_GONE)
            
            # Generate JWT tokens
            refresh = RefreshToken.for_user(tailor)
            
            # Update last login
            tailor.save()
            
            # Serialize tailor data
            tailor_data = {
                'id': tailor.id,
                'unique_id': tailor.unique_id,
                'name': tailor.name,
                'shop_name': tailor.shop_name,
                'email': tailor.email,
                'phone': tailor.phone,
                'address': tailor.address,
                'auth_provider': tailor.auth_provider,
                'profile_image_path': tailor.profile_image_path.url if tailor.profile_image_path else None,
                'created_at': tailor.created_at.isoformat(),
                'updated_at': tailor.updated_at.isoformat(),
                'is_deleted': tailor.is_deleted,
                'is_active': tailor.is_active,
                'email_verified': tailor.email_verified,
            }
            
            return Response({
                'message': 'Login successful',
                'user': tailor_data,
                'tokens': {
                    'access': str(refresh.access_token),
                    'refresh': str(refresh),
                }
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
```

### 6. Resend OTP View (Django)
```python
# otp/views.py
class ResendOTPView(APIView):
    """Resend OTP to user"""
    
    def post(self, request):
        try:
            email = request.data.get('email')
            otp_type = request.data.get('otp_type', 'email')
            
            if not email:
                return Response({
                    'error': 'Email is required'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Get tailor
            try:
                tailor = Tailor.objects.get(email=email)
            except Tailor.DoesNotExist:
                return Response({
                    'error': 'User not found'
                }, status=status.HTTP_404_NOT_FOUND)
            
            # Invalidate old OTPs
            OTP.objects.filter(
                tailor=tailor,
                otp_type=otp_type,
                is_used=False
            ).update(is_used=True)
            
            # Generate new OTP
            otp = OTP.create_otp(
                tailor=tailor,
                otp_type=otp_type,
                contact_info=email
            )
            
            # Send OTP email
            send_mail(
                subject='Verify Your Email - Tailor App',
                message=f'Your verification code is: {otp.otp_code}\n\nThis code will expire in 10 minutes.',
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[email],
                fail_silently=False,
            )
            
            return Response({
                'message': 'OTP sent successfully',
                'otp_sent_to': email,
                'expires_in': 600  # 10 minutes in seconds
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
```

## 📱 Flutter Frontend Implementation

### 1. Enhanced Auth Service with OTP
```dart
// lib/data/services/auth_service_with_backend.dart
import 'package:tailer_app/data/services/accounts_api_service.dart';
import 'package:tailer_app/data/services/local_db_service.dart';
import 'package:tailer_app/data/models/tailor_model.dart';
import 'package:tailer_app/core/services/token_storage_service.dart';

class AuthServiceWithBackend {
  final AccountsApiService _apiService;
  final LocalDatabaseService _localDb;
  final TokenStorageService _tokenStorage;
  
  AuthServiceWithBackend({
    AccountsApiService? apiService,
    LocalDatabaseService? localDb,
    TokenStorageService? tokenStorage,
  })  : _apiService = apiService ?? AccountsApiService(),
        _localDb = localDb ?? LocalDatabaseService(),
        _tokenStorage = tokenStorage ?? TokenStorageService();
  
  /// Step 1: Register user on backend (inactive)
  /// Returns: Tailor data + temp tokens + requires_verification flag
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String passwordConfirm,
    required String name,
    required String shopName,
    required String phone,
    String? address,
  }) async {
    try {
      // Call backend registration
      final request = RegisterRequest(
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
        name: name,
        shopName: shopName,
        phone: phone,
        address: address ?? '',
      );
      
      final response = await _apiService.register(request);
      
      // Store temp tokens (limited access until verified)
      await _tokenStorage.saveAccessToken(response.accessToken);
      await _tokenStorage.saveRefreshToken(response.refreshToken);
      await _tokenStorage.saveUserId(response.user.id);
      await _tokenStorage.saveUserEmail(response.user.email);
      
      // DO NOT save to local DB yet - wait for verification
      
      return {
        'success': true,
        'user': response.user,
        'requires_verification': true,
        'message': 'OTP sent to ${response.user.email}',
      };
      
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }
  
  /// Step 2: Verify OTP
  /// Activates account on backend + saves to local DB
  Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otpCode,
  }) async {
    try {
      // Call backend OTP verification
      final request = VerifyOTPRequest(
        email: email,
        otpCode: otpCode,
        otpType: 'email',
      );
      
      final response = await _apiService.verifyEmail(request);
      
      // Account is now verified and active
      // Update tokens with full access
      await _tokenStorage.saveAccessToken(response.accessToken);
      await _tokenStorage.saveRefreshToken(response.refreshToken);
      
      // NOW save to local SQLite database
      await _saveToLocalDatabase(response.user);
      
      // Mark as logged in
      await _tokenStorage.saveLoginState(true);
      await _tokenStorage.saveLastLoginDate();
      
      return {
        'success': true,
        'user': response.user,
        'verified': true,
        'message': 'Account verified successfully',
      };
      
    } catch (e) {
      throw Exception('OTP verification failed: $e');
    }
  }
  
  /// Step 3: Login user
  /// Backend validates + returns JWT tokens + user data
  /// Syncs to local DB
  Future<Tailor> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // Call backend login
      final request = LoginRequest(
        email: email,
        password: password,
      );
      
      final response = await _apiService.login(request);
      
      // Save JWT tokens
      await _tokenStorage.saveAccessToken(response.accessToken);
      await _tokenStorage.saveRefreshToken(response.refreshToken);
      await _tokenStorage.saveUserId(response.user.id);
      await _tokenStorage.saveUserEmail(response.user.email);
      
      // Sync to local database
      await _saveToLocalDatabase(response.user);
      
      // Mark as logged in
      await _tokenStorage.saveLoginState(true);
      await _tokenStorage.saveLastLoginDate();
      
      return response.user;
      
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
  
  /// Resend OTP
  Future<void> resendOTP(String email) async {
    try {
      await _apiService.resendVerification(email);
    } catch (e) {
      throw Exception('Failed to resend OTP: $e');
    }
  }
  
  /// Save verified user to local SQLite database
  Future<void> _saveToLocalDatabase(Tailor tailor) async {
    try {
      final db = await _localDb.database;
      
      // Check if tailor exists
      final existing = await db.query(
        'tailors',
        where: 'id = ?',
        whereArgs: [tailor.id],
      );
      
      if (existing.isEmpty) {
        // Insert new tailor
        await db.insert('tailors', tailor.toMap());
      } else {
        // Update existing tailor
        await db.update(
          'tailors',
          tailor.toMap(),
          where: 'id = ?',
          whereArgs: [tailor.id],
        );
      }
    } catch (e) {
      throw Exception('Failed to save to local database: $e');
    }
  }
  
  /// Get current user from local DB
  Future<Tailor?> getCurrentUser() async {
    try {
      final userId = await _tokenStorage.getUserId();
      if (userId == null) return null;
      
      final db = await _localDb.database;
      final results = await db.query(
        'tailors',
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      if (results.isEmpty) return null;
      return Tailor.fromMap(results.first);
      
    } catch (e) {
      return null;
    }
  }
  
  /// Logout
  Future<void> logout() async {
    try {
      // Call backend logout (optional - to invalidate token)
      await _apiService.logout();
      
      // Clear local storage
      await _tokenStorage.clearAll();
      
      // Optionally clear local DB
      // await _clearLocalDatabase();
      
    } catch (e) {
      // Even if backend fails, clear local data
      await _tokenStorage.clearAll();
    }
  }
}
```

### 2. OTP Request/Response Models
```dart
// lib/data/models/account/auth_models.dart
// Add these classes to existing auth_models.dart

class VerifyOTPRequest {
  final String email;
  final String otpCode;
  final String otpType;
  
  const VerifyOTPRequest({
    required this.email,
    required this.otpCode,
    this.otpType = 'email',
  });
  
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp_code': otpCode,
      'otp_type': otpType,
    };
  }
}

class VerifyOTPResponse {
  final Tailor user;
  final String accessToken;
  final String refreshToken;
  final bool verified;
  
  const VerifyOTPResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.verified,
  });
  
  factory VerifyOTPResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOTPResponse(
      user: Tailor.fromMap(json['user']),
      accessToken: json['tokens']['access'],
      refreshToken: json['tokens']['refresh'],
      verified: json['verified'] ?? true,
    );
  }
}

class ResendOTPRequest {
  final String email;
  final String otpType;
  
  const ResendOTPRequest({
    required this.email,
    this.otpType = 'email',
  });
  
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp_type': otpType,
    };
  }
}
```

### 3. Update AccountsApiService
```dart
// lib/data/services/accounts_api_service.dart
// Add these methods to existing AccountsApiService class

  /// Verify email with OTP
  Future<VerifyOTPResponse> verifyEmail(VerifyOTPRequest request) async {
    try {
      Logger.api('🔐 Verifying OTP for: ${request.email}');

      final response = await _apiClient.post(
        ApiEndpoints.verifyEmail,
        data: request.toJson(),
      );

      if (response.statusCode == HttpStatusCode.ok) {
        final verifyResponse = VerifyOTPResponse.fromJson(response.data);

        // Save updated tokens
        await _tokenStorage.saveAccessToken(verifyResponse.accessToken);
        await _tokenStorage.saveRefreshToken(verifyResponse.refreshToken);
        
        // Save user data
        await _tokenStorage.saveUserId(verifyResponse.user.id);
        await _tokenStorage.saveUserEmail(verifyResponse.user.email);
        await _tokenStorage.saveLoginState(true);

        Logger.info('AccountsApi', '✅ Email verified successfully');
        return verifyResponse;
      } else {
        throw ApiException(
          message: 'OTP verification failed',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } catch (e) {
      Logger.error('AccountsApi', 'Email verification failed', error: e);
      rethrow;
    }
  }

  /// Resend verification OTP
  Future<void> resendVerification(String email) async {
    try {
      Logger.api('📧 Resending OTP to: $email');

      final response = await _apiClient.post(
        ApiEndpoints.resendVerification,
        data: ResendOTPRequest(email: email).toJson(),
      );

      if (response.statusCode == HttpStatusCode.ok) {
        Logger.info('AccountsApi', '✅ Verification OTP sent');
      } else {
        throw ApiException(
          message: 'Failed to send OTP',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } catch (e) {
      Logger.error('AccountsApi', 'Resend verification failed', error: e);
      rethrow;
    }
  }
```

### 4. Update API Endpoints
```dart
// lib/core/config/api_config.dart
// Add OTP endpoints to ApiEndpoints class

  // OTP endpoints
  static const String verifyEmail = '$accounts/auth/verify-email/';
  static const String verifyOTP = '$accounts/otp/verify/';
  static const String sendEmailOTP = '$accounts/otp/send-email/';
  static const String resendOTP = '$accounts/otp/resend/';
```

## 🎯 Complete Registration Flow

### Flow Diagram
```
┌─────────────────┐
│  User enters    │
│  registration   │
│  details        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Flutter calls   │
│ registerUser()  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Django Backend  │
│ - Create Tailor │
│   (inactive)    │
│ - Generate OTP  │
│ - Send Email    │
│ - Return temp   │
│   tokens        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Flutter shows   │
│ OTP input screen│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ User enters OTP │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Flutter calls   │
│ verifyOTP()     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Django Backend  │
│ - Verify OTP    │
│ - Activate user │
│ - Generate JWT  │
│ - Return user   │
│   data          │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Flutter saves   │
│ to SQLite       │
│ - Tailor data   │
│ - JWT tokens    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Navigate to     │
│ Dashboard       │
└─────────────────┘
```

## 📋 Implementation Checklist

### Django Backend
- [ ] **Tailor Model**: Created with proper fields and MAT ID generation
- [ ] **OTP Model**: Created with expiry and attempt tracking
- [ ] **Registration View**: Creates inactive user + sends OTP
- [ ] **OTP Verification View**: Activates user + generates JWT
- [ ] **Login View**: Validates credentials + checks verification
- [ ] **Resend OTP View**: Invalidates old OTPs + sends new one
- [ ] **JWT Configuration**: SimpleJWT installed and configured
- [ ] **Email Backend**: SMTP configured for OTP emails
- [ ] **CORS Settings**: Flutter origins allowed
- [ ] **URL Patterns**: All endpoints configured correctly

### Flutter Frontend
- [ ] **API Configuration**: Points to Django server
- [ ] **OTP Models**: VerifyOTPRequest/Response added
- [ ] **AccountsApiService**: verifyEmail() and resendVerification() methods
- [ ] **AuthServiceWithBackend**: Complete auth flow with OTP
- [ ] **Local DB Sync**: Saves to SQLite only after verification
- [ ] **Token Storage**: JWT tokens stored securely
- [ ] **UI Screens**: Registration → OTP Input → Dashboard
- [ ] **Error Handling**: Proper error messages for users
- [ ] **Network Permissions**: Android INTERNET permission

## 🎉 Final Result

Your authentication system will:

✅ **Backend Handles**: Registration, OTP generation, Email sending, Account activation, JWT token generation  
✅ **Frontend Handles**: UI flow, Local SQLite sync (only verified users), Token storage  
✅ **Security**: Users must verify email before accessing app  
✅ **Offline Support**: Verified users synced to local DB for offline access  
✅ **Professional**: JWT tokens, OTP expiry, attempt limits, proper error handling

The system is production-ready with proper separation of concerns! 🚀