# API Quick Reference Guide

**Base URL:** `http://192.168.0.3:8000/api/v1`

---

## Authentication Endpoints

| Method | Endpoint | Auth Required | Status | Description |
|--------|----------|---------------|--------|-------------|
| POST | `/auth/register/` | ❌ | ✅ Working | Register new user |
| POST | `/auth/verify-otp/` | ❌ | 🔄 Ready | Verify OTP code |
| POST | `/auth/login/` | ❌ | 🔄 Ready | User login |
| POST | `/auth/refresh/` | ❌ | 🔄 Ready | Refresh access token |
| POST | `/auth/resend-otp/` | ❌ | 🔄 Ready | Resend OTP email |
| POST | `/auth/forgot-password/` | ❌ | 🔄 Ready | Request password reset |
| POST | `/auth/reset-password/` | ❌ | 🔄 Ready | Reset password with OTP |
| POST | `/auth/change-password/` | ✅ | 🔄 Ready | Change password |
| GET | `/auth/users/me/` | ✅ | 🔄 Ready | Get current user |
| PATCH | `/auth/users/me/` | ✅ | 🔄 Ready | Update user profile |
| POST | `/auth/check-email/` | ❌ | 🔄 Ready | Check email exists |
| N/A | Logout | ❌ | 🔄 Ready | Clear local session |

**Legend:**
- ✅ **Working** - Tested and confirmed working
- 🔄 **Ready** - Implemented, not yet tested
- ❌ **No Auth Required** - Public endpoint
- ✅ **Auth Required** - Requires JWT token

---

## Quick Code Examples

### 1. Registration ✅
```dart
final response = await HybridAuthService().registerWithBackend(
  email: 'user@example.com',
  password: 'SecurePass123',
  passwordConfirm: 'SecurePass123',
  name: 'John Doe',
  shopName: 'John\'s Shop',
  phone: '',
  address: '',
);
```

**Request:**
```json
POST /auth/register/
{
  "email": "user@example.com",
  "password": "SecurePass123",
  "password_confirm": "SecurePass123",
  "name": "John Doe",
  "shop_name": "John's Shop"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "tailor": {...},
    "tokens": {"access": "...", "refresh": "..."}
  }
}
```

---

### 2. OTP Verification 🔄
```dart
final success = await HybridAuthService().verifyOTPAndActivate(
  email: 'user@example.com',
  otpCode: '1234',
);
```

**Request:**
```json
POST /auth/verify-otp/
{
  "email": "user@example.com",
  "otp_code": "1234",
  "otp_type": "registration"
}
```

**Response:**
```json
{
  "success": true,
  "message": "OTP verified successfully",
  "user": {"id": "...", "is_active": true}
}
```

---

### 3. Login 🔄
```dart
final user = await HybridAuthService().loginWithBackend(
  email: 'user@example.com',
  password: 'SecurePass123',
);
```

**Request:**
```json
POST /auth/login/
{
  "email": "user@example.com",
  "password": "SecurePass123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {...},
    "tokens": {"access": "...", "refresh": "..."}
  }
}
```

---

### 4. Resend OTP 🔄
```dart
await AccountsApiService().resendOTP(
  'user@example.com',
  otpType: 'registration',
);
```

**Request:**
```json
POST /auth/resend-otp/
{
  "email": "user@example.com",
  "otp_type": "registration"
}
```

**Response:**
```json
{
  "success": true,
  "message": "OTP sent successfully"
}
```

---

### 5. Forgot Password 🔄
```dart
await AccountsApiService().requestPasswordReset('user@example.com');
```

**Request:**
```json
POST /auth/forgot-password/
{
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Password reset OTP sent to your email"
}
```

---

### 6. Reset Password 🔄
```dart
await AccountsApiService().resetPassword(
  ResetPasswordRequest(
    email: 'user@example.com',
    otpCode: '1234',
    newPassword: 'NewPass123',
    newPasswordConfirm: 'NewPass123',
  ),
);
```

**Request:**
```json
POST /auth/reset-password/
{
  "email": "user@example.com",
  "otp_code": "1234",
  "new_password": "NewPass123",
  "new_password_confirm": "NewPass123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Password reset successfully"
}
```

---

### 7. Change Password 🔄
```dart
await AccountsApiService().changePassword(
  ChangePasswordRequest(
    oldPassword: 'OldPass123',
    newPassword: 'NewPass123',
    newPasswordConfirm: 'NewPass123',
  ),
);
```

**Request:**
```json
POST /auth/change-password/
Headers: Authorization: Bearer {token}
{
  "old_password": "OldPass123",
  "new_password": "NewPass123",
  "new_password_confirm": "NewPass123"
}
```

**Response:**
```json
{
  "detail": "Password updated successfully"
}
```

---

### 8. Get Current User 🔄
```dart
final user = await AccountsApiService().getCurrentUser();
```

**Request:**
```json
GET /auth/users/me/
Headers: Authorization: Bearer {token}
```

**Response:**
```json
{
  "id": "MAT2ZWGYPN",
  "name": "John Doe",
  "shop_name": "John's Shop",
  "email": "user@example.com",
  "phone": "+1234567890",
  "address": "123 Main St",
  ...
}
```

---

### 9. Update Profile 🔄
```dart
final updatedUser = await AccountsApiService().updateCurrentUser(
  UpdateUserRequest(
    name: 'John Smith',
    shopName: 'John\'s Tailoring',
    phone: '+9876543210',
    address: '456 New St',
  ),
);
```

**Request:**
```json
PATCH /auth/users/me/
Headers: Authorization: Bearer {token}
{
  "name": "John Smith",
  "shop_name": "John's Tailoring",
  "phone": "+9876543210",
  "address": "456 New St"
}
```

**Response:**
```json
{
  "id": "MAT2ZWGYPN",
  "name": "John Smith",
  "shop_name": "John's Tailoring",
  ...
}
```

---

### 10. Check Email 🔄
```dart
final exists = await AccountsApiService().checkEmailExists('user@example.com');
```

**Request:**
```json
POST /auth/check-email/
{
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "exists": true
}
```

---

### 11. Token Refresh 🔄
```dart
// Automatically handled by ApiClient
final response = await AccountsApiService().refreshToken();
```

**Request:**
```json
POST /auth/refresh/
{
  "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:**
```json
{
  "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

### 12. Logout 🔄
```dart
await HybridAuthService().logout();
// Clears tokens, user data, but keeps local DB
```

---

## Common Error Responses

### Validation Error (400)
```json
{
  "email": ["User with this email already exists."],
  "password": ["Password must be at least 8 characters."]
}
```

### Authentication Error (401)
```json
{
  "detail": "Invalid email or password"
}
```

### Rate Limit Error (429)
```json
{
  "detail": "Please wait 60 seconds before requesting another OTP"
}
```

### Server Error (500)
```json
{
  "detail": "Internal server error"
}
```

---

## Testing URLs

### Registration
```bash
curl -X POST http://192.168.0.3:8000/api/v1/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!@#",
    "password_confirm": "Test123!@#",
    "name": "Test User",
    "shop_name": "Test Shop"
  }'
```

### Login
```bash
curl -X POST http://192.168.0.3:8000/api/v1/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!@#"
  }'
```

### Get Current User
```bash
curl -X GET http://192.168.0.3:8000/api/v1/auth/users/me/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## Password Requirements

- ✅ Minimum 8 characters
- ✅ At least 1 uppercase letter
- ✅ At least 1 lowercase letter
- ✅ At least 1 number
- ✅ Special characters allowed but not required

**Valid Examples:**
- `Password123`
- `SecurePass1`
- `MyPass2024!`

**Invalid Examples:**
- `pass123` (no uppercase)
- `PASSWORD123` (no lowercase)
- `Password` (no number)
- `Pass12` (too short)

---

## OTP Types

| Type | Description | Expiry | Used For |
|------|-------------|--------|----------|
| `registration` | Email verification | 10 min | After signup |
| `password_reset` | Password reset | 10 min | Forgot password |

---

## Token Lifetimes

| Token Type | Lifetime | Purpose |
|------------|----------|---------|
| Access Token | 1 hour | API authentication |
| Refresh Token | 7 days | Get new access token |
| OTP Code | 10 minutes | Email verification |

---

## Quick Checks

### Check if user is authenticated
```dart
final isAuth = await HybridAuthService().isAuthenticated;
```

### Get stored user email
```dart
final email = await TokenStorageService().getUserEmail();
```

### Get stored user ID
```dart
final userId = await TokenStorageService().getUserId();
```

### Check database content
```dart
import 'package:tailer_app/utils/check_local_db.dart';
await checkLocalDatabase(); // Prints to console
```

---

## File Locations

```
lib/
├── data/
│   ├── models/
│   │   ├── tailor_model.dart          # User model
│   │   └── account/
│   │       └── auth_models.dart       # Request/Response models
│   ├── services/
│   │   ├── hybrid_auth_service.dart   # Main auth service
│   │   ├── accounts_api_service.dart  # API calls
│   │   └── local_db_service.dart      # SQLite operations
│   └── repositories/
│       └── tailor_auth_repository.dart # Local auth
├── core/
│   ├── config/
│   │   └── api_config.dart            # API configuration
│   └── services/
│       ├── api_client.dart            # HTTP client
│       └── token_storage_service.dart # Secure storage
└── features/
    └── auth/
        └── screens/
            ├── signup_screen.dart     # Registration UI
            ├── signin_screen.dart     # Login UI
            └── otp_screen.dart        # OTP verification UI
```

---

**Last Updated:** October 15, 2025  
**Version:** 1.0.0  
**Status:** Registration ✅ | Others 🔄
