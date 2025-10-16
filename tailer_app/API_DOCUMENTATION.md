# Authentication API Documentation

**Base URL:** `http://192.168.0.3:8000/api/v1`  
**Authentication:** JWT Bearer Token  
**Content-Type:** `application/json`

---

## Table of Contents

1. [Registration](#1-registration)
2. [OTP Verification](#2-otp-verification)
3. [Login](#3-login)
4. [Token Refresh](#4-token-refresh)
5. [Logout](#5-logout)
6. [Resend OTP](#6-resend-otp)
7. [Forgot Password](#7-forgot-password)
8. [Reset Password](#8-reset-password)
9. [Change Password](#9-change-password)
10. [Get Current User](#10-get-current-user)
11. [Update Profile](#11-update-profile)
12. [Check Email](#12-check-email)

---

## 1. Registration

Register a new tailor account.

### Endpoint
```
POST /auth/register/
```

### Headers
```
Content-Type: application/json
```

### Request Body
```json
{
  "email": "john@example.com",
  "password": "SecurePass123",
  "password_confirm": "SecurePass123",
  "name": "John Doe",
  "shop_name": "John Doe's Shop",
  "phone": "",
  "address": "",
  "auth_provider": "email"
}
```

### Response (201 Created)
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "tailor": {
      "id": "MAT2ZWGYPN",
      "unique_id": "MAT2ZWGYPN",
      "name": "John Doe",
      "shop_name": "John Doe's Shop",
      "email": "john@example.com",
      "phone": null,
      "auth_provider": "email",
      "address": "",
      "profile_image_url": "https://ui-avatars.com/api/?name=John+Doe&background=6366f1&color=white",
      "email_verified": false,
      "phone_verified": false,
      "created_at": "2025-10-15T10:30:00.000Z",
      "updated_at": "2025-10-15T10:30:00.000Z"
    },
    "tokens": {
      "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
  }
}
```

### Error Response (400 Bad Request)
```json
{
  "email": ["User with this email already exists."],
  "password": ["Password must be at least 8 characters."]
}
```

### Flutter Implementation
```dart
final response = await _authService.registerWithBackend(
  email: 'john@example.com',
  password: 'SecurePass123',
  passwordConfirm: 'SecurePass123',
  name: 'John Doe',
  shopName: 'John Doe\'s Shop',
  phone: '',
  address: '',
);
```

---

## 2. OTP Verification

Verify OTP code sent to email and activate user account.

### Endpoint
```
POST /auth/verify-otp/
```

### Headers
```
Content-Type: application/json
```

### Request Body
```json
{
  "email": "john@example.com",
  "otp_code": "1234",
  "otp_type": "registration"
}
```

### OTP Types
- `registration` - For email verification after signup
- `password_reset` - For password reset verification

### Response (200 OK)
```json
{
  "success": true,
  "message": "OTP verified successfully",
  "user": {
    "id": "MAT2ZWGYPN",
    "email": "john@example.com",
    "name": "John Doe",
    "is_active": true
  }
}
```

### Error Response (400 Bad Request)
```json
{
  "detail": "Invalid or expired OTP"
}
```

### Flutter Implementation
```dart
final success = await _authService.verifyOTPAndActivate(
  email: 'john@example.com',
  otpCode: '1234',
);
```

---

## 3. Login

Authenticate user with email and password.

### Endpoint
```
POST /auth/login/
```

### Headers
```
Content-Type: application/json
```

### Request Body
```json
{
  "email": "john@example.com",
  "password": "SecurePass123"
}
```

### Response (200 OK)
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "MAT2ZWGYPN",
      "unique_id": "MAT2ZWGYPN",
      "name": "John Doe",
      "shop_name": "John Doe's Shop",
      "email": "john@example.com",
      "phone": "+1234567890",
      "address": "123 Main St",
      "profile_image_url": "https://...",
      "email_verified": true,
      "phone_verified": false
    },
    "tokens": {
      "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
  }
}
```

### Error Response (401 Unauthorized)
```json
{
  "detail": "Invalid email or password"
}
```

### Flutter Implementation
```dart
final user = await _authService.loginWithBackend(
  email: 'john@example.com',
  password: 'SecurePass123',
);
```

---

## 4. Token Refresh

Refresh expired access token using refresh token.

### Endpoint
```
POST /auth/refresh/
```

### Headers
```
Content-Type: application/json
```

### Request Body
```json
{
  "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Response (200 OK)
```json
{
  "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Error Response (401 Unauthorized)
```json
{
  "detail": "Token is invalid or expired"
}
```

### Flutter Implementation
```dart
// Automatically handled by ApiClient interceptor
final response = await _apiService.refreshToken();
```

---

## 5. Logout

Clear user session (frontend only, no backend call needed).

### Implementation
```dart
await _authService.logout();
// Clears: tokens, user data, session info
// Keeps: local DB data for offline access
```

---

## 6. Resend OTP

Resend OTP code to user's email.

### Endpoint
```
POST /auth/resend-otp/
```

### Headers
```
Content-Type: application/json
```

### Request Body
```json
{
  "email": "john@example.com",
  "otp_type": "registration"
}
```

### Response (200 OK)
```json
{
  "success": true,
  "message": "OTP sent successfully to your email"
}
```

### Error Response (429 Too Many Requests)
```json
{
  "detail": "Please wait 60 seconds before requesting another OTP"
}
```

### Flutter Implementation
```dart
await _authService.resendOTP(email: 'john@example.com');
```

---

## 7. Forgot Password

Request password reset OTP.

### Endpoint
```
POST /auth/forgot-password/
```

### Headers
```
Content-Type: application/json
```

### Request Body
```json
{
  "email": "john@example.com"
}
```

### Response (200 OK)
```json
{
  "success": true,
  "message": "Password reset OTP sent to your email"
}
```

### Error Response (404 Not Found)
```json
{
  "detail": "No user found with this email"
}
```

### Flutter Implementation
```dart
await _apiService.requestPasswordReset('john@example.com');
```

---

## 8. Reset Password

Reset password using OTP code.

### Endpoint
```
POST /auth/reset-password/
```

### Headers
```
Content-Type: application/json
```

### Request Body
```json
{
  "email": "john@example.com",
  "otp_code": "1234",
  "new_password": "NewSecurePass123",
  "new_password_confirm": "NewSecurePass123"
}
```

### Response (200 OK)
```json
{
  "success": true,
  "message": "Password reset successfully"
}
```

### Error Response (400 Bad Request)
```json
{
  "detail": "Invalid or expired OTP"
}
```

### Flutter Implementation
```dart
await _apiService.resetPassword(
  ResetPasswordRequest(
    email: 'john@example.com',
    otpCode: '1234',
    newPassword: 'NewSecurePass123',
    newPasswordConfirm: 'NewSecurePass123',
  ),
);
```

---

## 9. Change Password

Change password for authenticated user.

### Endpoint
```
POST /auth/change-password/
```

### Headers
```
Content-Type: application/json
Authorization: Bearer {access_token}
```

### Request Body
```json
{
  "old_password": "OldPass123",
  "new_password": "NewSecurePass123",
  "new_password_confirm": "NewSecurePass123"
}
```

### Response (200 OK)
```json
{
  "detail": "Password updated successfully"
}
```

### Error Response (400 Bad Request)
```json
{
  "old_password": ["Current password is incorrect"]
}
```

### Flutter Implementation
```dart
await _apiService.changePassword(
  ChangePasswordRequest(
    oldPassword: 'OldPass123',
    newPassword: 'NewSecurePass123',
    newPasswordConfirm: 'NewSecurePass123',
  ),
);
```

---

## 10. Get Current User

Get authenticated user's profile.

### Endpoint
```
GET /auth/users/me/
```

### Headers
```
Authorization: Bearer {access_token}
```

### Response (200 OK)
```json
{
  "id": "MAT2ZWGYPN",
  "unique_id": "MAT2ZWGYPN",
  "name": "John Doe",
  "shop_name": "John Doe's Shop",
  "email": "john@example.com",
  "phone": "+1234567890",
  "address": "123 Main St",
  "profile_image_url": "https://...",
  "email_verified": true,
  "phone_verified": false,
  "created_at": "2025-10-15T10:30:00.000Z",
  "updated_at": "2025-10-15T11:00:00.000Z"
}
```

### Error Response (401 Unauthorized)
```json
{
  "detail": "Authentication credentials were not provided"
}
```

### Flutter Implementation
```dart
final user = await _apiService.getCurrentUser();
```

---

## 11. Update Profile

Update authenticated user's profile.

### Endpoint
```
PATCH /auth/users/me/
```

### Headers
```
Content-Type: application/json
Authorization: Bearer {access_token}
```

### Request Body (All fields optional)
```json
{
  "name": "John Smith",
  "shop_name": "John's Tailoring",
  "phone": "+1234567890",
  "address": "456 New Street"
}
```

### Response (200 OK)
```json
{
  "id": "MAT2ZWGYPN",
  "name": "John Smith",
  "shop_name": "John's Tailoring",
  "email": "john@example.com",
  "phone": "+1234567890",
  "address": "456 New Street",
  ...
}
```

### Flutter Implementation
```dart
final updatedUser = await _apiService.updateCurrentUser(
  UpdateUserRequest(
    name: 'John Smith',
    shopName: 'John\'s Tailoring',
    phone: '+1234567890',
    address: '456 New Street',
  ),
);
```

---

## 12. Check Email

Check if email already exists in the system.

### Endpoint
```
POST /auth/check-email/
```

### Headers
```
Content-Type: application/json
```

### Request Body
```json
{
  "email": "john@example.com"
}
```

### Response (200 OK)
```json
{
  "exists": true
}
```

### Flutter Implementation
```dart
final exists = await _apiService.checkEmailExists('john@example.com');
if (exists) {
  // Show error: "Email already exists"
}
```

---

## Common Error Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created (Registration success) |
| 400 | Bad Request (Validation error) |
| 401 | Unauthorized (Invalid token/credentials) |
| 403 | Forbidden (Permission denied) |
| 404 | Not Found (Resource doesn't exist) |
| 429 | Too Many Requests (Rate limit exceeded) |
| 500 | Internal Server Error |

---

## Authentication Flow

```
┌─────────────┐
│   Signup    │
└──────┬──────┘
       │
       ▼
┌─────────────┐      ┌──────────────┐
│ POST /auth/ │ OTP  │ POST /auth/  │
│  register/  │─────▶│ verify-otp/  │
└─────────────┘      └──────┬───────┘
                            │
                            ▼
                     ┌──────────────┐
                     │ POST /auth/  │
                     │   login/     │
                     └──────┬───────┘
                            │
                            ▼
                     ┌──────────────┐
                     │  Dashboard   │
                     │ (Authorized) │
                     └──────────────┘
```

---

## Security Notes

1. **Always use HTTPS in production**
2. **Store tokens securely** (FlutterSecureStorage)
3. **Never log sensitive data** (passwords, tokens)
4. **Validate all inputs** on both client and server
5. **Implement rate limiting** for OTP endpoints
6. **Use strong passwords** (enforced by validation)

---

**Last Updated:** October 15, 2025  
**API Version:** v1  
**Status:** Registration Working ✅ | Others Ready for Testing 🔄
