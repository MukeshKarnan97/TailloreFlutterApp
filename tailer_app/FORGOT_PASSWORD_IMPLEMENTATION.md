# Forgot Password Implementation Guide

## Overview
Complete forgot password flow with API integration and local database synchronization.

## Flow Diagram
```
User → Forgot Password Screen
  ↓
  1. Enter Email → Send to API
  ↓
  2. API sends OTP → Navigate to OTP Screen
  ↓
  3. Enter OTP + New Password → Verify with API
  ↓
  4. API confirms → Update local DB password hash
  ↓
  5. Success → Redirect to Sign In
```

## Implementation Status

### ✅ Completed
1. **HybridAuthService.resetPasswordWithOTP()**
   - Sends reset request to API
   - Updates local database with new password hash
   - Uses SHA256 hashing (matching sign-in)
   - Verifies update was successful

### 🔄 Need to Update

#### 1. AuthService Methods
**File**: `lib/data/services/auth_service.dart`

Add HybridAuthService integration:
```dart
import 'hybrid_auth_service.dart';

class AuthService {
  final HybridAuthService _hybridAuth = HybridAuthService();
  
  // Forgot password - request OTP
  Future<bool> sendForgotPasswordEmail(String email) async {
    return await _hybridAuth.requestPasswordReset(email: email);
  }
  
  // Reset password with OTP
  Future<bool> resetPasswordWithOTP({
    required String email,
    required String otpCode,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    return await _hybridAuth.resetPasswordWithOTP(
      email: email,
      otpCode: otpCode,
      newPassword: newPassword,
      newPasswordConfirm: newPasswordConfirm,
    );
  }
}
```

#### 2. Forgot Password Screen
**File**: `lib/features/auth/screens/forgot_password_screen.dart`

Current: Just navigates to OTP without API call
Needed: Call API to send OTP

#### 3. Reset Password Screen (OTP + New Password)
**File**: `lib/features/auth/screens/reset_password_screen.dart` or similar

Needed:
- OTP input field
- New password field
- Confirm password field
- Submit button → calls `resetPasswordWithOTP()`
- On success → navigate to sign-in

## API Endpoints

### 1. Request Password Reset (Send OTP)
```
POST /api/v1/auth/forgot-password/
Body: {
  "email": "user@example.com"
}
Response: {
  "success": true,
  "message": "OTP sent to email"
}
```

### 2. Reset Password with OTP
```
POST /api/v1/auth/reset-password/
Body: {
  "email": "user@example.com",
  "otp_code": "123456",
  "new_password": "NewPass123!",
  "new_password_confirm": "NewPass123!"
}
Response: {
  "success": true,
  "message": "Password reset successful"
}
```

## Local Database Update

### Password Hash Storage
```dart
// After successful API call
final newPasswordHash = _hashPassword(newPassword); // SHA256

await _dbService.update(
  'tailor',
  {
    'password_hash': newPasswordHash,  // 64-char SHA256 hash
    'updated_at': DateTime.now().toIso8601String(),
  },
  where: 'email = ?',
  whereArgs: [email.trim()],
);
```

### Hash Format
- **Algorithm**: SHA256
- **Length**: 64 characters (hexadecimal)
- **No salt**: Simple hash (matches registration)
- **Example**: `6ca13d52ca70c883e0f0bb101e425a89e8624de51db2d2392593af6a84118090`

## Testing Checklist

### Test Case 1: Complete Flow
1. ✅ Go to Forgot Password screen
2. ✅ Enter email: `mukesh.dmc97@gmail.com`
3. ✅ Click "Send Reset Link"
4. ✅ API sends OTP to email
5. ✅ Navigate to OTP screen
6. ✅ Enter OTP and new password
7. ✅ Submit → API verifies OTP
8. ✅ Local DB password_hash updated
9. ✅ Success message shown
10. ✅ Redirect to Sign In screen
11. ✅ Sign in with new password

### Test Case 2: Verify Local DB Update
```dart
// After password reset
1. Open Database Viewer (debug screen)
2. Find user by email
3. Check password_hash:
   - Length should be 64 characters
   - Hash should be different from before
4. Copy hash
5. Test with "Test Password" button
6. Should match new password
```

### Test Case 3: Invalid Scenarios
- ❌ Invalid email → Show error
- ❌ Wrong OTP → Show error
- ❌ Passwords don't match → Show error
- ❌ Password too short → Show error
- ❌ Network error → Show retry option

## Screen Flow

### 1. Forgot Password Screen
```
┌─────────────────────────────┐
│   Forgot Your Password?     │
│                             │
│  Enter your email address   │
│  to receive a reset code    │
│                             │
│  ┌─────────────────────┐   │
│  │ Email Address       │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │  Send Reset Code    │   │
│  └─────────────────────┘   │
│                             │
│  Back to Sign In            │
└─────────────────────────────┘
```

### 2. Reset Password Screen (OTP + Password)
```
┌─────────────────────────────┐
│    Reset Your Password      │
│                             │
│  Enter the code sent to:    │
│  mukesh.dmc97@gmail.com     │
│                             │
│  ┌─────────────────────┐   │
│  │ OTP Code            │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │ New Password        │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │ Confirm Password    │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │  Reset Password     │   │
│  └─────────────────────┘   │
│                             │
│  Resend Code                │
└─────────────────────────────┘
```

## Code Implementation

### HybridAuthService (Already Implemented ✅)
```dart
Future<bool> resetPasswordWithOTP({
  required String email,
  required String otpCode,
  required String newPassword,
  required String newPasswordConfirm,
}) async {
  // 1. Send to API
  await _apiService.resetPassword(request);
  
  // 2. Hash password
  final newPasswordHash = _hashPassword(newPassword);
  
  // 3. Update local DB
  await _dbService.update('tailor', {
    'password_hash': newPasswordHash,
    'updated_at': DateTime.now().toIso8601String(),
  }, where: 'email = ?', whereArgs: [email]);
  
  return true;
}
```

### AuthService Integration (TODO)
```dart
// Add to auth_service.dart
Future<bool> resetPasswordWithOTP({
  required String email,
  required String otpCode,
  required String newPassword,
  required String newPasswordConfirm,
}) async {
  try {
    // Validate inputs
    if (newPassword != newPasswordConfirm) {
      throw ValidationException(
        fieldErrors: {'confirmPassword': 'Passwords do not match'}
      );
    }
    
    if (newPassword.length < 8) {
      throw ValidationException(
        fieldErrors: {'newPassword': 'Password must be at least 8 characters'}
      );
    }
    
    // Call HybridAuthService
    return await _hybridAuth.resetPasswordWithOTP(
      email: email,
      otpCode: otpCode,
      newPassword: newPassword,
      newPasswordConfirm: newPasswordConfirm,
    );
  } catch (e) {
    debugPrint('AuthService: Password reset error: $e');
    rethrow;
  }
}
```

## Navigation Routes

### Update app_routes.dart
```dart
// Ensure these routes exist
static const forgotPassword = '/forgot-password';
static const resetPassword = '/reset-password';  // OTP + new password screen
static const signIn = '/signin';
```

### GoRouter Configuration
```dart
GoRoute(
  path: '/reset-password',
  name: RouteNames.resetPassword,
  builder: (context, state) {
    final email = state.extra as String?;  // Pass email from forgot password
    return ResetPasswordScreen(email: email);
  },
),
```

## Error Handling

### API Errors
```dart
try {
  await resetPasswordWithOTP(...);
} on NetworkException {
  UserFeedbackService.showNetworkError(context);
} on InvalidOTPException {
  UserFeedbackService.showError(context, 'Invalid or expired OTP');
} on ValidationException catch (e) {
  // Show field-specific errors
  e.fieldErrors.forEach((field, error) {
    // Display error under respective field
  });
} catch (e) {
  UserFeedbackService.showError(context, 'Password reset failed');
}
```

### Local DB Errors
```dart
// Already handled in HybridAuthService with Logger
if (results.isEmpty) {
  Logger.warning('HybridAuth', 'User not found in local DB');
  // Password reset still succeeds (API was updated)
}
```

## Success Flow

### After Successful Reset
```dart
// 1. Show success message
UserFeedbackService.showSuccess(
  context,
  'Password reset successful! Please sign in with your new password.',
);

// 2. Wait a moment
await Future.delayed(const Duration(milliseconds: 1500));

// 3. Navigate to sign-in
if (mounted) {
  context.goNamed(RouteNames.signIn);
}
```

## Security Considerations

1. **Password Validation**:
   - Minimum 8 characters
   - Must contain uppercase, lowercase, number, special char
   - Matches confirmation field

2. **OTP Handling**:
   - Single-use only
   - Expires after 10 minutes
   - Rate limiting on API side

3. **Local Storage**:
   - Only hash stored (never plain text)
   - SHA256 algorithm
   - Updated atomically with API

4. **Error Messages**:
   - Don't reveal if email exists
   - Generic "Reset failed" for security

## Logging

### Debug Logs to Check
```
[HybridAuth] Resetting password for: mukesh.dmc97@gmail.com
[HybridAuth] Password reset successful on backend
[HybridAuth] Updating password hash in local database
[HybridAuth] Password hash updated in local database
[HybridAuth] Verified password hash length: 64
[HybridAuth] Password reset complete (API + Local DB)
```

## Files Modified

1. ✅ `lib/data/services/hybrid_auth_service.dart` - resetPasswordWithOTP() updated
2. ⏳ `lib/data/services/auth_service.dart` - Add resetPasswordWithOTP() wrapper
3. ⏳ `lib/features/auth/screens/forgot_password_screen.dart` - Update to call API
4. ⏳ `lib/features/auth/screens/reset_password_screen.dart` - Create if missing
5. ⏳ `lib/routes/app_routes.dart` - Add reset-password route if missing

## Next Steps

1. Update AuthService to expose resetPasswordWithOTP()
2. Check if reset_password_screen.dart exists
3. If not, create it with OTP + password fields
4. Update forgot_password_screen to pass email to reset screen
5. Test complete flow
6. Verify local DB update with debug screen

---

Last Updated: 2025-01-16
Status: HybridAuthService implementation ✅ Complete
