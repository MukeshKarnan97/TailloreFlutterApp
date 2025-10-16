# Updated Authentication Flow - API-Driven OTP

## 🎯 Overview

This document describes the updated authentication flow where:
- ✅ **OTP is generated and sent by Django backend** (not Flutter)
- ✅ **User data inserted into local DB immediately after registration**
- ✅ **OTP verification only updates activation status**
- ✅ **No local OTP generation or display in UI**

---

## 🔄 Complete Flow

### Step 1: User Fills Signup Form

```dart
// User Input
Name: "John Doe"
Shop Name: "John's Tailoring"
Email: "john@example.com"
Phone: "+1234567890"
Password: "Password123"
Confirm Password: "Password123"
```

---

### Step 2: Flutter Calls Registration API

```dart
await _hybridAuthService.registerWithBackend(
  name: "John Doe",
  shopName: "John's Tailoring",
  email: "john@example.com",
  phone: "+1234567890",
  password: "Password123",
  passwordConfirm: "Password123",
);
```

**HTTP Request:**
```http
POST http://192.168.0.11:8000/api/v1/auth/register/
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "Password123",
  "password_confirm": "Password123",
  "name": "John Doe",
  "shop_name": "John's Tailoring",
  "phone": "+1234567890",
  "address": "",
  "auth_provider": "email"
}
```

---

### Step 3: Django Backend Processing

```python
# Django Backend (Your existing code)
1. Creates user in database (is_active = False)
2. Generates 6-digit OTP
3. Sends OTP via email to john@example.com
4. Stores OTP in database with expiry time
5. Generates JWT tokens
6. Returns response
```

**Django Response:**
```json
{
  "user": {
    "id": "MAT1234567",
    "unique_id": "MAT1234567",
    "email": "john@example.com",
    "name": "John Doe",
    "shop_name": "John's Tailoring",
    "phone": "+1234567890",
    "address": "",
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

---

### Step 4: Flutter Processes Response

```dart
// HybridAuthService.registerWithBackend()

// 1. Save JWT tokens to FlutterSecureStorage
await _tokenStorage.saveTokens(
  accessToken: response.accessToken,
  refreshToken: response.refreshToken,
);

// 2. Insert user data into local SQLite database
await _syncTailorToLocalDB(response.user);

// 3. Log success
Logger.info('User data synced to local DB, ready for OTP verification');
```

**Local SQLite Database:**
```sql
INSERT INTO tailor (
  id, unique_id, name, shop_name, email, phone,
  password_hash, auth_provider, address, is_active,
  created_at, updated_at, is_deleted
) VALUES (
  'MAT1234567', 'MAT1234567', 'John Doe', 'John''s Tailoring',
  'john@example.com', '+1234567890', '', 'email', '',
  0,  -- is_active = false (not verified yet)
  '2025-10-14T10:30:00Z', '2025-10-14T10:30:00Z', 0
);
```

---

### Step 5: Navigate to OTP Screen

```dart
// signup_screen.dart
Navigator.pushNamed(
  context,
  '/otp-verification',
  arguments: {
    'email': 'john@example.com',
  },
);
```

**OTP Screen UI:**
- ❌ **NO local OTP generation**
- ❌ **NO displayed OTP code**
- ✅ **Only input fields for user to enter OTP from email**

```dart
// otp_screen.dart
TextField(
  decoration: InputDecoration(
    labelText: 'Enter OTP from your email',
    hintText: '123456',
  ),
  keyboardType: TextInputType.number,
  maxLength: 6,
)
```

---

### Step 6: User Checks Email

```
User receives email from Django backend:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📧 Your OTP Code

Your verification code is: 123456

This code will expire in 10 minutes.

Do not share this code with anyone.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### Step 7: User Enters OTP

```dart
// User types in OTP screen
OTP Input: "123456"
```

---

### Step 8: Flutter Calls OTP Verification API

```dart
await _hybridAuthService.verifyOTPAndActivate(
  email: "john@example.com",
  otpCode: "123456",
);
```

**HTTP Request:**
```http
POST http://192.168.0.11:8000/api/v1/auth/verify-otp/
Content-Type: application/json

{
  "email": "john@example.com",
  "otp_code": "123456",
  "otp_type": "registration"
}
```

---

### Step 9: Django Backend Verifies OTP

```python
# Django Backend
1. Check OTP matches and not expired
2. If valid:
   - Update user.is_active = True
   - Delete OTP record
   - Return success response
3. If invalid:
   - Return error response
```

**Django Response (Success):**
```json
{
  "success": true,
  "message": "OTP verified successfully. Account activated.",
  "user": {
    "id": "MAT1234567",
    "unique_id": "MAT1234567",
    "email": "john@example.com",
    "name": "John Doe",
    "shop_name": "John's Tailoring",
    "phone": "+1234567890",
    "address": "",
    "auth_provider": "email",
    "is_active": true,  // ✅ NOW ACTIVE
    "created_at": "2025-10-14T10:30:00Z",
    "updated_at": "2025-10-14T10:35:00Z"
  }
}
```

**Django Response (Failure):**
```json
{
  "success": false,
  "message": "Invalid OTP code or OTP expired"
}
```

---

### Step 10: Flutter Updates Local DB

```dart
// HybridAuthService.verifyOTPAndActivate()

if (response.success) {
  // Update user activation status in local DB
  await _syncTailorToLocalDB(response.user);
  
  // Set as current user
  _currentTailor = response.user;
  
  return true;
}
```

**Local SQLite Database Update:**
```sql
UPDATE tailor
SET is_active = 1,
    updated_at = '2025-10-14T10:35:00Z'
WHERE email = 'john@example.com';
```

---

### Step 11: Navigate to Dashboard

```dart
// otp_screen.dart
if (verified) {
  Navigator.pushNamedAndRemoveUntil(
    context,
    '/dashboard',
    (route) => false,
  );
}
```

---

## 📊 Data State at Each Step

| Step | Django DB | Local SQLite DB | OTP Status | User Status |
|------|-----------|-----------------|------------|-------------|
| 1. Form filled | - | - | - | Not registered |
| 2. API called | - | - | - | Sending... |
| 3. Backend processes | ✅ User created (inactive) | - | ✅ Generated & emailed | Awaiting OTP |
| 4. Flutter processes | ✅ User exists | ✅ **User inserted** | OTP sent | Awaiting OTP |
| 5. Navigate to OTP | ✅ User exists | ✅ User exists | OTP sent | Awaiting OTP |
| 6. User checks email | ✅ User exists | ✅ User exists | 📧 OTP received | Awaiting input |
| 7. User enters OTP | ✅ User exists | ✅ User exists | Entered | Verifying... |
| 8. OTP API called | ✅ User exists | ✅ User exists | Verifying | Verifying... |
| 9. Backend verifies | ✅ **User activated** | ✅ User exists | ✅ Verified | Active |
| 10. Local DB updated | ✅ User active | ✅ **User activated** | Verified | Active |
| 11. Dashboard | ✅ User active | ✅ User active | Verified | ✅ **Logged in** |

---

## 🔍 Key Points

### ✅ What Happens

1. **Registration:**
   - ✅ Django creates user (inactive)
   - ✅ Django generates and sends OTP via email
   - ✅ Flutter inserts user into local DB immediately
   - ✅ User navigates to OTP screen

2. **OTP Screen:**
   - ✅ User sees only input fields
   - ✅ User enters OTP received via email
   - ✅ No local OTP generation
   - ✅ No displayed OTP in UI

3. **OTP Verification:**
   - ✅ Django verifies OTP from database
   - ✅ Django activates user
   - ✅ Flutter updates activation status in local DB

### ❌ What Does NOT Happen

1. **No Local OTP Generation:**
   - ❌ No `generateTestOTP()` in Flutter
   - ❌ No random OTP generation client-side
   - ❌ No OTP display in console/UI

2. **No Delayed Local DB Insertion:**
   - ❌ User is inserted immediately after registration
   - ❌ Not waiting for OTP verification to insert

3. **No Mock OTP:**
   - ❌ No hardcoded "1234" fallback
   - ❌ Only real OTP from email works

---

## 🧪 Testing Guide

### Test 1: Registration Flow

```bash
# 1. Fill signup form in app
# 2. Click "Sign Up"
# 3. Check Django logs for OTP generation
# 4. Check email inbox for OTP
# 5. Check local DB - should have user (inactive)

sqlite3 app_database.db
SELECT * FROM tailor WHERE email = 'john@example.com';
# Should show: is_active = 0
```

### Test 2: OTP Verification

```bash
# 1. Enter OTP from email (e.g., "123456")
# 2. Click "Verify"
# 3. Check Django logs for verification
# 4. Check local DB - should be activated

sqlite3 app_database.db
SELECT * FROM tailor WHERE email = 'john@example.com';
# Should show: is_active = 1
```

### Test 3: Invalid OTP

```bash
# 1. Enter wrong OTP (e.g., "999999")
# 2. Click "Verify"
# 3. Should show error message
# 4. User stays on OTP screen
# 5. Local DB unchanged (still inactive)
```

---

## 🔧 Code Implementation

### HybridAuthService Implementation

```dart
// ✅ Registration - Inserts to local DB immediately
Future<RegisterResponse> registerWithBackend(...) async {
  final response = await _apiService.register(request);
  await _syncTailorToLocalDB(response.user);  // ✅ Insert now
  return response;
}

// ✅ OTP Verification - Only updates activation status
Future<bool> verifyOTPAndActivate({...}) async {
  final response = await _apiService.verifyOTP(...);
  if (response.success) {
    await _syncTailorToLocalDB(response.user);  // ✅ Update activation
    _currentTailor = response.user;
    return true;
  }
  return false;
}
```

### OTP Screen Implementation

```dart
// ❌ NO local OTP generation
// ❌ NO displayed OTP
// ✅ ONLY user input

Future<void> _verifyOTP() async {
  final otp = _otpController.text.trim();
  
  if (otp.length != 6) {
    _showError('Please enter 6-digit OTP');
    return;
  }
  
  try {
    final success = await _hybridAuthService.verifyOTPAndActivate(
      email: widget.email,
      otpCode: otp,  // ✅ User-entered OTP only
    );
    
    if (success) {
      // Navigate to dashboard
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
        (route) => false,
      );
    } else {
      _showError('Invalid OTP. Please try again.');
    }
  } catch (e) {
    _showError('Verification failed: ${e.toString()}');
  }
}
```

---

## 📝 Summary

| Aspect | Implementation |
|--------|----------------|
| **OTP Generation** | ✅ Django backend only |
| **OTP Delivery** | ✅ Email only |
| **OTP Display in App** | ❌ Never shown |
| **OTP Input** | ✅ User enters from email |
| **Local DB Insert** | ✅ Immediately after registration |
| **OTP Verification** | ✅ Django backend validates |
| **Activation** | ✅ Django updates, Flutter syncs |

---

**This flow ensures:**
- ✅ All OTP logic is server-side
- ✅ Secure OTP delivery via email
- ✅ Local DB has user data for quick access
- ✅ User activation controlled by backend
- ✅ No OTP shown in Flutter app UI
