# Django Backend + Flutter Local DB Integration - Complete Implementation

## Overview

This document outlines the complete implementation of hybrid authentication that integrates:
- **Django Backend** (C:\Users\mukes\Videos\Android_Dev\Devlopment\TailerBackend\tailor_project)
- **Flutter Frontend** with local SQLite database synchronization

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    HYBRID AUTHENTICATION                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  1. REGISTRATION (Backend)                                   │
│     • User submits form → Django creates user (inactive)     │
│     • OTP generated and sent via email                       │
│     • JWT tokens issued and stored in secure storage         │
│     • ❌ NOT inserted into local DB yet                      │
│                                                               │
│  2. OTP VERIFICATION (Backend + Local DB)                    │
│     • User enters OTP → Django verifies and activates user   │
│     • ✅ NOW insert into local SQLite database               │
│     • User data synced for offline access                    │
│                                                               │
│  3. LOGIN (Backend + Local DB)                               │
│     • User enters credentials → Django validates             │
│     • JWT tokens issued and stored                           │
│     • ✅ User data synced to local DB                        │
│                                                               │
│  4. PROFILE UPDATE (Backend + Local DB)                      │
│     • User updates profile → Django saves changes            │
│     • ✅ Changes synced to local DB immediately              │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Files Created/Modified

### 1. New Service: `hybrid_auth_service.dart`

**Location:** `lib/data/services/hybrid_auth_service.dart`

**Purpose:** Main authentication service that combines Django backend API with local database synchronization.

**Key Methods:**
- `registerWithBackend()` - Register with Django (user inactive, no local DB insert)
- `verifyOTPAndActivate()` - Verify OTP with Django + insert into local DB
- `loginWithBackend()` - Login with Django + sync to local DB
- `updateProfile()` - Update profile on Django + sync to local DB
- `logout()` - Clear tokens (keeps local DB data)

### 2. Updated: `accounts_api_service.dart`

**Location:** `lib/data/services/accounts_api_service.dart`

**Added Methods:**
- `verifyOTP()` - POST /api/v1/accounts/auth/verify-otp/
- `resendOTP()` - POST /api/v1/accounts/auth/resend-otp/
- `checkEmailExists()` - POST /api/v1/accounts/auth/check-email/
- `requestPasswordReset()` - POST /api/v1/accounts/auth/forgot-password/

### 3. Updated: `auth_models.dart`

**Location:** `lib/data/models/account/auth_models.dart`

**Added Models:**
- `VerifyOTPRequest` - Request model for OTP verification
- `VerifyOTPResponse` - Response model with activated user data
- `ResendOTPRequest` - Request model for resending OTP
- Updated `ResetPasswordRequest` - Now uses OTP instead of token

### 4. Updated: `api_config.dart`

**Location:** `lib/core/config/api_config.dart`

**Added Endpoints:**
- `verifyOTP` - '/accounts/auth/verify-otp/'
- `resendOTP` - '/accounts/auth/resend-otp/'
- `checkEmail` - '/accounts/auth/check-email/'

## Implementation Steps

### Step 1: Update Your Registration Screen

Replace the existing auth service with `HybridAuthService`:

```dart
import 'package:tailer_app/data/services/hybrid_auth_service.dart';

class SignUpScreen extends StatefulWidget {
  // ... existing code
}

class _SignUpScreenState extends State<SignUpScreen> {
  final HybridAuthService _authService = HybridAuthService();
  
  Future<void> _handleRegistration() async {
    try {
      // Step 1: Register with Django backend
      final response = await _authService.registerWithBackend(
        name: _nameController.text.trim(),
        shopName: _shopNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        passwordConfirm: _confirmPasswordController.text,
        address: _addressController.text.trim(),
      );
      
      // At this point:
      // ✅ User created in Django (but inactive)
      // ✅ OTP sent to email
      // ✅ JWT tokens stored in secure storage
      // ❌ NOT in local database yet
      
      // Navigate to OTP verification screen
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/otp-verification',
          arguments: {
            'email': _emailController.text.trim(),
            'fromRegistration': true,
          },
        );
      }
    } catch (e) {
      // Handle error
      _showError(e.toString());
    }
  }
}
```

### Step 2: Update Your OTP Verification Screen

```dart
import 'package:tailer_app/data/services/hybrid_auth_service.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final bool fromRegistration;
  
  const OTPVerificationScreen({
    Key? key,
    required this.email,
    this.fromRegistration = false,
  }) : super(key: key);
  
  // ... existing code
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final HybridAuthService _authService = HybridAuthService();
  
  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    
    if (otp.length != 6) {
      _showError('Please enter complete OTP');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Step 2: Verify OTP with backend and insert into local DB
      final success = await _authService.verifyOTPAndActivate(
        email: widget.email,
        otpCode: otp,
      );
      
      if (success) {
        // At this point:
        // ✅ User activated in Django
        // ✅ User data inserted into local SQLite database
        // ✅ Ready to use the app
        
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account verified successfully!')),
          );
          
          // Navigate to dashboard
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (route) => false,
          );
        }
      } else {
        _showError('Invalid OTP. Please try again.');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _resendOTP() async {
    try {
      await _authService.resendOTP(widget.email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent to your email')),
        );
      }
    } catch (e) {
      _showError('Failed to resend OTP: ${e.toString()}');
    }
  }
}
```

### Step 3: Update Your Login Screen

```dart
import 'package:tailer_app/data/services/hybrid_auth_service.dart';

class SignInScreen extends StatefulWidget {
  // ... existing code
}

class _SignInScreenState extends State<SignInScreen> {
  final HybridAuthService _authService = HybridAuthService();
  
  Future<void> _handleLogin() async {
    try {
      setState(() => _isLoading = true);
      
      // Step 3: Login with backend and sync to local DB
      final tailor = await _authService.loginWithBackend(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // At this point:
      // ✅ User authenticated with Django
      // ✅ JWT tokens stored
      // ✅ User data synced to local DB
      
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
          (route) => false,
        );
      }
    } catch (e) {
      if (e is ValidationException) {
        // Show field-specific errors
        _showFieldErrors(e.fieldErrors);
      } else {
        _showError('Login failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
```

### Step 4: Update Your Profile Edit Screen

```dart
import 'package:tailer_app/data/services/hybrid_auth_service.dart';

class ProfileEditScreen extends StatefulWidget {
  // ... existing code
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final HybridAuthService _authService = HybridAuthService();
  
  Future<void> _saveProfile() async {
    try {
      setState(() => _isLoading = true);
      
      // Step 4: Update profile on backend and sync to local DB
      final updatedTailor = await _authService.updateProfile(
        name: _nameController.text.trim(),
        shopName: _shopNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );
      
      // At this point:
      // ✅ Profile updated in Django
      // ✅ Changes synced to local DB
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, updatedTailor);
      }
    } catch (e) {
      _showError('Failed to update profile: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
```

## Django Backend Requirements

Your Django backend should have these endpoints (based on your existing code):

### 1. Registration Endpoint
```
POST /api/v1/accounts/auth/register/
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "password_confirm": "securePassword123",
  "name": "John Doe",
  "shop_name": "John's Tailoring",
  "phone": "+1234567890",
  "address": "123 Main St",
  "auth_provider": "email"
}
```

**Response:**
```json
{
  "user": {
    "id": "MAT1234567",
    "unique_id": "MAT1234567",
    "email": "user@example.com",
    "name": "John Doe",
    "shop_name": "John's Tailoring",
    "phone": "+1234567890",
    "address": "123 Main St",
    "auth_provider": "email",
    "is_active": false,
    "created_at": "2025-10-14T10:30:00Z",
    "updated_at": "2025-10-14T10:30:00Z"
  },
  "tokens": {
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  }
}
```

### 2. OTP Verification Endpoint
```
POST /api/v1/accounts/auth/verify-otp/
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "otp_code": "123456",
  "otp_type": "registration"
}
```

**Response:**
```json
{
  "success": true,
  "message": "OTP verified successfully. Account activated.",
  "user": {
    "id": "MAT1234567",
    "unique_id": "MAT1234567",
    "email": "user@example.com",
    "name": "John Doe",
    "shop_name": "John's Tailoring",
    "phone": "+1234567890",
    "address": "123 Main St",
    "auth_provider": "email",
    "is_active": true,
    "created_at": "2025-10-14T10:30:00Z",
    "updated_at": "2025-10-14T10:35:00Z"
  }
}
```

### 3. Login Endpoint
```
POST /api/v1/accounts/auth/login/
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response:**
```json
{
  "user": {
    "id": "MAT1234567",
    "unique_id": "MAT1234567",
    "email": "user@example.com",
    "name": "John Doe",
    "shop_name": "John's Tailoring",
    "phone": "+1234567890",
    "address": "123 Main St",
    "auth_provider": "email",
    "is_active": true,
    "created_at": "2025-10-14T10:30:00Z",
    "updated_at": "2025-10-14T10:35:00Z"
  },
  "tokens": {
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  }
}
```

### 4. Resend OTP Endpoint
```
POST /api/v1/accounts/auth/resend-otp/
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "otp_type": "registration"
}
```

**Response:**
```json
{
  "message": "OTP resent successfully to your email"
}
```

### 5. Update Profile Endpoint
```
PATCH /api/v1/accounts/users/me/
Authorization: Bearer {access_token}
```

**Request Body:**
```json
{
  "name": "John Updated",
  "shop_name": "John's Premium Tailoring",
  "phone": "+1234567890",
  "address": "456 New Address"
}
```

**Response:**
```json
{
  "id": "MAT1234567",
  "unique_id": "MAT1234567",
  "email": "user@example.com",
  "name": "John Updated",
  "shop_name": "John's Premium Tailoring",
  "phone": "+1234567890",
  "address": "456 New Address",
  "auth_provider": "email",
  "is_active": true,
  "created_at": "2025-10-14T10:30:00Z",
  "updated_at": "2025-10-14T11:00:00Z"
}
```

## Local Database Schema

The Tailor model is automatically synced to this SQLite table:

```sql
CREATE TABLE tailor (
  id TEXT PRIMARY KEY,  -- MAT1234567 format
  unique_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  shop_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT,
  password_hash TEXT,
  auth_provider TEXT DEFAULT 'email',
  address TEXT,
  profile_image_path TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  is_deleted INTEGER DEFAULT 0
);
```

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      REGISTRATION FLOW                           │
└─────────────────────────────────────────────────────────────────┘

User enters registration details
         │
         ▼
┌─────────────────────────┐
│ HybridAuthService       │
│ registerWithBackend()   │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ Django Backend          │
│ POST /auth/register/    │
│                         │
│ • Create user (inactive)│
│ • Generate OTP          │
│ • Send email            │
│ • Return JWT tokens     │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ TokenStorageService     │
│ • Save access token     │
│ • Save refresh token    │
│ • Save user email       │
└─────────────────────────┘
            │
            ▼
    Navigate to OTP Screen
    (❌ NOT in local DB yet)


┌─────────────────────────────────────────────────────────────────┐
│                   OTP VERIFICATION FLOW                          │
└─────────────────────────────────────────────────────────────────┘

User enters OTP code
         │
         ▼
┌─────────────────────────┐
│ HybridAuthService       │
│ verifyOTPAndActivate()  │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ Django Backend          │
│ POST /auth/verify-otp/  │
│                         │
│ • Verify OTP code       │
│ • Activate user         │
│ • Return user data      │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ LocalDatabaseService    │
│ insertTailor()          │
│                         │
│ ✅ Insert into SQLite   │
└─────────────────────────┘
            │
            ▼
    Navigate to Dashboard


┌─────────────────────────────────────────────────────────────────┐
│                        LOGIN FLOW                                │
└─────────────────────────────────────────────────────────────────┘

User enters credentials
         │
         ▼
┌─────────────────────────┐
│ HybridAuthService       │
│ loginWithBackend()      │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ Django Backend          │
│ POST /auth/login/       │
│                         │
│ • Validate credentials  │
│ • Return JWT tokens     │
│ • Return user data      │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ LocalDatabaseService    │
│ insertTailor() or       │
│ update() if exists      │
│                         │
│ ✅ Sync to SQLite       │
└───────────┬─────────────┘
            │
            ▼
    Navigate to Dashboard
```

## Testing Checklist

### 1. Registration Flow
- [ ] User can register with valid details
- [ ] Django creates user in inactive state
- [ ] OTP email is sent successfully
- [ ] JWT tokens are saved in secure storage
- [ ] User is NOT in local database yet
- [ ] Navigate to OTP screen with email parameter

### 2. OTP Verification Flow
- [ ] User receives OTP via email
- [ ] Valid OTP activates user in Django
- [ ] User data is inserted into local SQLite database
- [ ] Check local DB: `SELECT * FROM tailor WHERE email = 'user@example.com'`
- [ ] User can navigate to dashboard after verification

### 3. Login Flow
- [ ] User can login with correct credentials
- [ ] JWT tokens are saved
- [ ] User data is synced to local database
- [ ] If user exists in local DB, it's updated
- [ ] If user doesn't exist, it's inserted

### 4. Profile Update Flow
- [ ] User can update name, shop name, phone, address
- [ ] Changes are saved in Django backend
- [ ] Changes are synced to local database immediately
- [ ] Check local DB: `SELECT * FROM tailor WHERE id = 'MAT1234567'`

### 5. Offline Access
- [ ] After login, user data exists in local DB
- [ ] App can load user profile from local DB when offline
- [ ] Orders and customers can reference tailor ID from local DB

### 6. Error Handling
- [ ] Invalid OTP shows appropriate error
- [ ] Network errors are handled gracefully
- [ ] Validation errors show field-specific messages
- [ ] OTP expiry is handled properly

## Security Considerations

1. **Password Storage**
   - ✅ Passwords are hashed in Django backend
   - ❌ Password hash is stored in local DB (for offline login fallback)
   - Consider removing password_hash from local DB if not needed

2. **JWT Tokens**
   - ✅ Stored in FlutterSecureStorage (encrypted)
   - ✅ Access token expires in 1 hour
   - ✅ Refresh token expires in 7 days
   - ✅ Auto-refresh mechanism in ApiClient

3. **OTP Security**
   - ✅ 6-digit random code
   - ✅ 10-minute expiry
   - ✅ Single-use only
   - ✅ Email verification

4. **Local Database**
   - ⚠️ SQLite database is not encrypted by default
   - Consider using `sqflite_sqlcipher` for encryption
   - Sensitive data should be minimal

## Next Steps

1. **Test the complete flow:**
   ```powershell
   # Make sure Django backend is running
   cd C:\Users\mukes\Videos\Android_Dev\Devlopment\TailerBackend\tailor_project
   python manage.py runserver
   
   # In another terminal, run Flutter app
   cd C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app
   flutter run
   ```

2. **Verify database insertion:**
   ```powershell
   # Use SQLite viewer or command line
   sqlite3 path_to_database.db
   SELECT * FROM tailor;
   ```

3. **Check logs:**
   - Look for `HybridAuth` tags in Flutter console
   - Check Django backend logs for API calls

4. **Update existing screens:**
   - Replace `AuthService` with `HybridAuthService`
   - Update all authentication-related screens

## Common Issues and Solutions

### Issue 1: User not inserted into local DB after OTP verification
**Solution:** Check that `verifyOTPAndActivate()` is being called, not just backend's `verifyOTP()`.

### Issue 2: Duplicate user errors
**Solution:** The `_syncTailorToLocalDB()` method checks for existing users and updates instead of inserting.

### Issue 3: Network errors during login
**Solution:** The service handles network errors gracefully. Check Django backend is running at `http://127.0.0.1:8000`.

### Issue 4: JWT token expiry
**Solution:** `ApiClient` has auto-refresh interceptor that automatically refreshes expired access tokens.

## Summary

You now have a complete hybrid authentication system that:
- ✅ Uses Django backend for all authentication operations
- ✅ Sends OTP via email for verification
- ✅ Issues JWT tokens for API access
- ✅ Syncs user data to local SQLite database ONLY after verification
- ✅ Keeps local and backend data in sync
- ✅ Supports offline access to user profile
- ✅ Handles profile updates with dual sync

All authentication authority remains with Django backend, while local database provides offline access and performance optimization.
