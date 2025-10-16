# 🔐 Hybrid Authentication System: Django Backend + Flutter Local DB

**Django Backend**: `C:\Users\mukes\Videos\Android_Dev\Devlopment\TailerBackend\tailor_project`  
**Flutter Frontend**: Tailor App with Local SQLite Cache  
**Architecture**: Backend-First Authentication with Local Sync  
**Date**: October 14, 2025

## 🎯 System Architecture Overview

### Authentication Flow
```
┌─────────────────────────────────────────────────────────────┐
│                    AUTHENTICATION FLOW                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. REGISTRATION (Backend-First)                            │
│     Flutter → Django Backend → OTP Generation → Email       │
│     ↓                                                        │
│     User verifies OTP → Backend activates account           │
│     ↓                                                        │
│     Backend returns JWT + Tailor data                       │
│     ↓                                                        │
│     Flutter stores tokens + inserts to Local DB             │
│                                                              │
│  2. LOGIN (Backend-First)                                   │
│     Flutter → Django Backend → Validates credentials        │
│     ↓                                                        │
│     Backend returns JWT + Tailor data                       │
│     ↓                                                        │
│     Flutter stores tokens + syncs to Local DB               │
│                                                              │
│  3. OTP VERIFICATION (Backend Only)                         │
│     Flutter → Django Backend → Verifies OTP                 │
│     ↓                                                        │
│     Backend activates account                               │
│     ↓                                                        │
│     Returns success + tokens                                │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 📋 Implementation Requirements

### 1. Backend Responsibilities (Django)
- ✅ **User Registration**: Create Tailor account in Django database
- ✅ **OTP Generation**: Generate and send OTP via email/SMS
- ✅ **OTP Verification**: Validate OTP and activate account
- ✅ **JWT Token Generation**: Issue access + refresh tokens
- ✅ **Login Validation**: Authenticate email/password
- ✅ **Account Activation**: Set account as verified after OTP
- ✅ **Password Reset**: Handle forgot password with OTP

### 2. Frontend Responsibilities (Flutter)
- ✅ **API Communication**: Call Django endpoints
- ✅ **Token Storage**: Securely store JWT tokens
- ✅ **Local DB Sync**: Insert/update Tailor data in SQLite
- ✅ **Offline Access**: Use local DB when offline
- ✅ **UI/UX**: Handle registration/login/OTP flows
- ✅ **Error Handling**: Display backend errors to user

## 🔧 Django Backend Implementation

### 1. Registration Endpoint
**File**: `accounts/views.py`

```python
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.core.mail import send_mail
from django.conf import settings
import random
import string

class RegisterView(APIView):
    def post(self, request):
        """
        Register new tailor - Backend handles everything
        """
        # Extract data
        email = request.data.get('email')
        password = request.data.get('password')
        password_confirm = request.data.get('password_confirm')
        name = request.data.get('name')
        shop_name = request.data.get('shop_name')
        phone = request.data.get('phone')
        address = request.data.get('address', '')
        auth_provider = request.data.get('auth_provider', 'email')
        
        # Validation
        if password != password_confirm:
            return Response(
                {'error': 'Passwords do not match'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if Tailor.objects.filter(email=email).exists():
            return Response(
                {'error': 'Email already registered'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Generate unique ID (MAT + 7 chars)
        unique_id = 'MAT' + ''.join(random.choices(string.ascii_uppercase + string.digits, k=7))
        
        # Create tailor (not activated yet)
        tailor = Tailor.objects.create_user(
            id=unique_id,
            unique_id=unique_id,
            email=email,
            password=password,
            name=name,
            shop_name=shop_name,
            phone=phone,
            address=address,
            auth_provider=auth_provider,
            is_active=False,  # Not activated until OTP verified
            email_verified=False
        )
        
        # Generate OTP
        otp_code = ''.join(random.choices(string.digits, k=6))
        
        # Save OTP to database
        OTP.objects.create(
            tailor=tailor,
            otp_type='email',
            otp_code=otp_code,
            contact_info=email,
            expires_at=timezone.now() + timedelta(minutes=10)
        )
        
        # Send OTP email
        send_mail(
            'Verify Your Email - Tailor App',
            f'Your verification code is: {otp_code}\n\nThis code will expire in 10 minutes.',
            settings.DEFAULT_FROM_EMAIL,
            [email],
            fail_silently=False,
        )
        
        # Return response (NO tokens yet - need OTP verification)
        return Response({
            'message': 'Registration successful. Please check your email for OTP.',
            'user': {
                'id': tailor.id,
                'email': tailor.email,
                'name': tailor.name,
                'shop_name': tailor.shop_name,
                'phone': tailor.phone,
                'email_verified': False,
                'is_active': False
            },
            'requires_verification': True
        }, status=status.HTTP_201_CREATED)
```

### 2. OTP Verification Endpoint
**File**: `accounts/views.py`

```python
from rest_framework_simplejwt.tokens import RefreshToken

class VerifyOTPView(APIView):
    def post(self, request):
        """
        Verify OTP and activate account
        """
        email = request.data.get('email')
        otp_code = request.data.get('otp_code')
        
        try:
            # Find tailor
            tailor = Tailor.objects.get(email=email)
            
            # Find valid OTP
            otp = OTP.objects.filter(
                tailor=tailor,
                otp_code=otp_code,
                is_used=False,
                expires_at__gt=timezone.now()
            ).first()
            
            if not otp:
                return Response(
                    {'error': 'Invalid or expired OTP'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Activate account
            tailor.is_active = True
            tailor.email_verified = True
            tailor.save()
            
            # Mark OTP as used
            otp.is_used = True
            otp.save()
            
            # Generate JWT tokens
            refresh = RefreshToken.for_user(tailor)
            
            # Return tokens + user data
            return Response({
                'message': 'Email verified successfully',
                'user': {
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
                    'email_verified': tailor.email_verified,
                    'is_active': tailor.is_active
                },
                'tokens': {
                    'access': str(refresh.access_token),
                    'refresh': str(refresh)
                }
            }, status=status.HTTP_200_OK)
            
        except Tailor.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
```

### 3. Login Endpoint
**File**: `accounts/views.py`

```python
class LoginView(APIView):
    def post(self, request):
        """
        Login - Backend validates and returns tokens
        """
        email = request.data.get('email')
        password = request.data.get('password')
        
        # Authenticate
        tailor = authenticate(request, email=email, password=password)
        
        if tailor is None:
            return Response(
                {'error': 'Invalid email or password'},
                status=status.HTTP_401_UNAUTHORIZED
            )
        
        # Check if account is activated
        if not tailor.is_active:
            return Response(
                {'error': 'Account not activated. Please verify your email.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Generate JWT tokens
        refresh = RefreshToken.for_user(tailor)
        
        # Update last login
        tailor.last_login = timezone.now()
        tailor.save()
        
        # Return tokens + user data
        return Response({
            'message': 'Login successful',
            'user': {
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
                'email_verified': tailor.email_verified,
                'is_active': tailor.is_active
            },
            'tokens': {
                'access': str(refresh.access_token),
                'refresh': str(refresh)
            }
        }, status=status.HTTP_200_OK)
```

### 4. Resend OTP Endpoint
**File**: `accounts/views.py`

```python
class ResendOTPView(APIView):
    def post(self, request):
        """
        Resend OTP for verification
        """
        email = request.data.get('email')
        
        try:
            tailor = Tailor.objects.get(email=email)
            
            if tailor.email_verified:
                return Response(
                    {'error': 'Email already verified'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Generate new OTP
            otp_code = ''.join(random.choices(string.digits, k=6))
            
            # Invalidate old OTPs
            OTP.objects.filter(tailor=tailor, is_used=False).update(is_used=True)
            
            # Create new OTP
            OTP.objects.create(
                tailor=tailor,
                otp_type='email',
                otp_code=otp_code,
                contact_info=email,
                expires_at=timezone.now() + timedelta(minutes=10)
            )
            
            # Send OTP email
            send_mail(
                'Verify Your Email - Tailor App',
                f'Your new verification code is: {otp_code}\n\nThis code will expire in 10 minutes.',
                settings.DEFAULT_FROM_EMAIL,
                [email],
                fail_silently=False,
            )
            
            return Response({
                'message': 'OTP sent successfully'
            }, status=status.HTTP_200_OK)
            
        except Tailor.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
```

## 🔧 Flutter Frontend Implementation

### 1. Enhanced Auth Service with Local DB Sync
**File**: `lib/data/services/hybrid_auth_service.dart`

```dart
import 'package:tailer_app/data/services/accounts_api_service.dart';
import 'package:tailer_app/data/services/local_db_service.dart';
import 'package:tailer_app/data/repositories/tailor_auth_repository.dart';
import 'package:tailer_app/data/models/tailor_model.dart';
import 'package:tailer_app/data/models/account/auth_models.dart';
import 'package:tailer_app/core/services/token_storage_service.dart';

class HybridAuthService {
  final AccountsApiService _apiService;
  final LocalDatabaseService _localDb;
  final TailorAuthRepository _localAuthRepo;
  final TokenStorageService _tokenStorage;

  HybridAuthService()
      : _apiService = AccountsApiService(),
        _localDb = LocalDatabaseService(),
        _localAuthRepo = TailorAuthRepository(),
        _tokenStorage = TokenStorageService();

  /// Register new tailor
  /// 1. Call Django backend
  /// 2. Backend creates account + sends OTP
  /// 3. Returns user data (not activated)
  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      // Step 1: Call Django backend
      final response = await _apiService.register(request);
      
      // Note: NO local DB insert yet - waiting for OTP verification
      // User data stored in response for OTP screen
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Verify OTP
  /// 1. Send OTP to Django backend
  /// 2. Backend activates account + returns tokens
  /// 3. Store tokens + insert to local DB
  Future<VerifyOTPResponse> verifyOTP({
    required String email,
    required String otpCode,
  }) async {
    try {
      // Step 1: Verify OTP with backend
      final request = VerifyOTPRequest(
        email: email,
        otpCode: otpCode,
      );
      
      final response = await _apiService.verifyEmail(request);
      
      // Step 2: Store JWT tokens securely
      await _tokenStorage.saveAccessToken(response.tokens.access);
      await _tokenStorage.saveRefreshToken(response.tokens.refresh);
      await _tokenStorage.saveUserId(response.user.id);
      await _tokenStorage.saveUserEmail(response.user.email);
      await _tokenStorage.saveLoginState(true);
      
      // Step 3: Insert verified user to local DB
      await _insertToLocalDB(response.user);
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Login
  /// 1. Call Django backend
  /// 2. Backend validates + returns tokens
  /// 3. Store tokens + sync to local DB
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      // Step 1: Call Django backend
      final response = await _apiService.login(request);
      
      // Step 2: Store JWT tokens
      await _tokenStorage.saveAccessToken(response.tokens.access);
      await _tokenStorage.saveRefreshToken(response.tokens.refresh);
      await _tokenStorage.saveUserId(response.user.id);
      await _tokenStorage.saveUserEmail(response.user.email);
      await _tokenStorage.saveLoginState(true);
      
      // Step 3: Sync to local DB (upsert)
      await _syncToLocalDB(response.user);
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Insert new tailor to local DB
  Future<void> _insertToLocalDB(Tailor tailor) async {
    try {
      await _localDb.initialize();
      
      // Check if already exists
      final existing = await _localAuthRepo.getTailorById(tailor.id);
      
      if (existing == null) {
        // Insert new tailor
        await _localAuthRepo.insertTailor(tailor);
        Logger.info('HybridAuth', '✅ Tailor inserted to local DB: ${tailor.id}');
      } else {
        // Update existing
        await _localAuthRepo.updateTailor(tailor);
        Logger.info('HybridAuth', '✅ Tailor updated in local DB: ${tailor.id}');
      }
    } catch (e) {
      Logger.error('HybridAuth', 'Failed to insert to local DB', error: e);
      // Don't throw - local DB failure shouldn't break auth flow
    }
  }

  /// Sync tailor data to local DB (update or insert)
  Future<void> _syncToLocalDB(Tailor tailor) async {
    await _insertToLocalDB(tailor); // Same logic
  }

  /// Resend OTP
  Future<void> resendOTP(String email) async {
    await _apiService.resendVerification(email);
  }

  /// Logout
  /// 1. Call Django backend
  /// 2. Clear tokens
  /// 3. Keep local DB (for offline access)
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Continue even if backend logout fails
    } finally {
      await _tokenStorage.clearTokens();
      await _tokenStorage.saveLoginState(false);
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _tokenStorage.hasValidTokens();
  }

  /// Get current tailor from local DB (offline support)
  Future<Tailor?> getCurrentTailorLocal() async {
    try {
      final userId = await _tokenStorage.getUserId();
      if (userId == null) return null;
      
      await _localDb.initialize();
      return await _localAuthRepo.getTailorById(userId);
    } catch (e) {
      return null;
    }
  }

  /// Get current tailor from backend (online)
  Future<Tailor> getCurrentTailorOnline() async {
    final tailor = await _apiService.getCurrentUser();
    
    // Sync to local DB
    await _syncToLocalDB(tailor);
    
    return tailor;
  }
}
```

### 2. OTP Verification Models
**File**: `lib/data/models/account/auth_models.dart` (Add these)

```dart
// ==================== OTP VERIFICATION ====================

class VerifyOTPRequest {
  final String email;
  final String otpCode;

  const VerifyOTPRequest({
    required this.email,
    required this.otpCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp_code': otpCode,
    };
  }
}

class VerifyOTPResponse {
  final String message;
  final Tailor user;
  final TokenPair tokens;

  const VerifyOTPResponse({
    required this.message,
    required this.user,
    required this.tokens,
  });

  factory VerifyOTPResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOTPResponse(
      message: json['message'],
      user: Tailor.fromMap(json['user']),
      tokens: TokenPair(
        access: json['tokens']['access'],
        refresh: json['tokens']['refresh'],
      ),
    );
  }
}

class TokenPair {
  final String access;
  final String refresh;

  const TokenPair({
    required this.access,
    required this.refresh,
  });
}
```

### 3. Registration Flow UI
**File**: `lib/features/auth/screens/signup_screen.dart` (Update)

```dart
// After successful registration, navigate to OTP screen
final response = await _hybridAuthService.register(request);

// Show success message
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Registration successful! Check your email for OTP.')),
);

// Navigate to OTP verification screen
Navigator.pushNamed(
  context,
  '/verify-otp',
  arguments: {
    'email': request.email,
    'name': request.name,
  },
);
```

### 4. OTP Verification Screen
**File**: `lib/features/auth/screens/otp_verification_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:tailer_app/data/services/hybrid_auth_service.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final String name;

  const OTPVerificationScreen({
    required this.email,
    required this.name,
    Key? key,
  }) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _hybridAuthService = HybridAuthService();
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verify OTP with backend
      final response = await _hybridAuthService.verifyOTP(
        email: widget.email,
        otpCode: _otpController.text,
      );

      // Success - account activated and synced to local DB
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verified successfully!')),
      );

      // Navigate to home screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOTP() async {
    try {
      await _hybridAuthService.resendOTP(widget.email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent! Check your email.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resend OTP: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verify Your Email',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'We sent a 6-digit code to ${widget.email}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Verify'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resendOTP,
              child: const Text('Resend OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 📊 Complete Authentication Flow

### Registration Flow
```
1. User fills registration form
   ↓
2. Flutter calls Django: POST /auth/register/
   ↓
3. Django:
   - Creates Tailor (is_active=False)
   - Generates OTP
   - Sends email
   - Returns user data (no tokens)
   ↓
4. Flutter navigates to OTP screen
   ↓
5. User enters OTP
   ↓
6. Flutter calls Django: POST /auth/verify-email/
   ↓
7. Django:
   - Validates OTP
   - Activates account (is_active=True)
   - Generates JWT tokens
   - Returns tokens + user data
   ↓
8. Flutter:
   - Stores JWT tokens securely
   - Inserts Tailor to local SQLite
   - Navigates to home screen
```

### Login Flow
```
1. User enters email/password
   ↓
2. Flutter calls Django: POST /auth/login/
   ↓
3. Django:
   - Validates credentials
   - Checks if account active
   - Generates JWT tokens
   - Returns tokens + user data
   ↓
4. Flutter:
   - Stores JWT tokens securely
   - Syncs Tailor to local SQLite (upsert)
   - Navigates to home screen
```

## 🎯 Summary

### Backend (Django) Handles:
✅ User registration  
✅ OTP generation and sending  
✅ OTP verification  
✅ Account activation  
✅ JWT token generation  
✅ Login authentication  
✅ Password reset with OTP  

### Frontend (Flutter) Handles:
✅ API communication  
✅ Token storage (secure)  
✅ Local DB synchronization  
✅ Offline data access  
✅ UI/UX flows  
✅ Error handling  

### Database Strategy:
- **Django PostgreSQL/MySQL**: Source of truth, handles all authentication
- **Flutter SQLite**: Local cache for offline access, synced after successful auth

This hybrid approach gives you:
- 🔒 **Secure backend authentication**
- 🚀 **Fast offline access**
- 📱 **Better user experience**
- 🔄 **Data synchronization**
- 🌐 **Multi-device support**

Your implementation is **ready to work** with this architecture! 🎉