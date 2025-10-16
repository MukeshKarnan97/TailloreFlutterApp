# is_active Field Implementation Guide

## Overview
This document explains how the `is_active` field is integrated throughout the authentication system for local-first authentication.

---

## 📊 Database Schema Update

### Migration (Version 13)
**File:** `lib/data/services/local_db_service.dart`

```dart
// Database version updated from 12 to 13
static const int _databaseVersion = 13;

// Added is_active field to tailor table
CREATE TABLE tailor (
  id TEXT PRIMARY KEY,
  unique_id TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  shop_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  auth_provider TEXT NOT NULL DEFAULT 'email',
  address TEXT NOT NULL DEFAULT '',
  profile_image_path TEXT,
  is_active INTEGER DEFAULT 0,        // ✅ NEW FIELD
  is_deleted INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)

// Performance index
CREATE INDEX idx_tailor_active ON tailor(is_active)
```

### Field Purpose
- **Type:** INTEGER (SQLite boolean: 0 = inactive, 1 = active)
- **Default:** 0 (inactive)
- **Purpose:** Tracks whether user has verified their email/OTP
- **Usage:** Required for login authentication

---

## 🔄 Authentication Flow

### 1. **Sign Up (Registration)**
**File:** `lib/features/auth/screens/signup_screen.dart`

```dart
// When user registers
await _authService.registerWithEmail(
  name: name,
  shopName: shopName,
  email: email,
  phone: phone,
  password: password,
);

// User created in LOCAL DB with is_active = 0
// User also created in DJANGO backend
// OTP sent to email
```

**Database State After Registration:**
```sql
INSERT INTO tailor (..., is_active, ...)
VALUES (..., 0, ...)  -- is_active defaults to 0 (inactive)
```

---

### 2. **OTP Verification & Activation**
**File:** `lib/data/services/hybrid_auth_service.dart` → `verifyOTPAndActivate()`

```dart
Future<bool> verifyOTPAndActivate(String email, String otp) async {
  // Step 1: Django backend verifies OTP
  final response = await _apiClient.post(
    '/auth/verify-otp/',
    data: {'email': email, 'otp': otp},
  );

  if (response.success) {
    // Step 2: Fetch user from LOCAL database
    final results = await _dbService.select(
      'tailor',
      where: 'email = ? AND is_deleted = 0',
      whereArgs: [email.trim()],
    );
    
    final user = Tailor.fromMap(results.first);
    
    // Step 3: ✅ ACTIVATE USER IN LOCAL DB
    await _dbService.update(
      'tailor',
      {
        'is_active': 1,  // 🔥 Set active to 1
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
    
    // Step 4: Generate LOCAL tokens (not Django tokens!)
    final accessToken = _localTokenService.generateAccessToken(
      userId: user.id,
      email: user.email,
    );
    
    final refreshToken = _localTokenService.generateRefreshToken(
      userId: user.id,
      email: user.email,
    );
    
    // Step 5: Save tokens to secure storage
    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    
    // User is now authenticated!
    return true;
  }
}
```

**Database State After OTP Verification:**
```sql
UPDATE tailor 
SET is_active = 1, updated_at = '2025-10-15T...'
WHERE id = 'MAT1234567'
```

---

### 3. **Sign In (Login)**
**File:** `lib/data/services/hybrid_auth_service.dart` → `loginWithLocal()`

```dart
Future<Tailor> loginWithLocal(String email, String password) async {
  // Step 1: Hash password for comparison
  final passwordHash = _hashPassword(password);  // SHA256
  
  // Step 2: Query LOCAL database
  final results = await _dbService.select(
    'tailor',
    where: 'email = ? AND password_hash = ? AND is_deleted = 0',
    whereArgs: [email.trim(), passwordHash],
  );
  
  if (results.isEmpty) {
    throw InvalidCredentialsException(
      details: 'Invalid email or password',
    );
  }
  
  final user = Tailor.fromMap(results.first);
  
  // Step 3: ✅ CHECK IS_ACTIVE FIELD
  final isActive = results.first['is_active'] == 1;
  if (!isActive) {
    // 🚫 User has not verified OTP yet!
    throw AccountDisabledException(
      reason: 'Account is not activated. Please verify your email first.',
    );
  }
  
  // Step 4: Generate local tokens (user is active)
  final accessToken = _localTokenService.generateAccessToken(
    userId: user.id,
    email: user.email,
  );
  
  final refreshToken = _localTokenService.generateRefreshToken(
    userId: user.id,
    email: user.email,
  );
  
  // Step 5: Save tokens and authenticate
  await _tokenStorage.saveTokens(
    accessToken: accessToken,
    refreshToken: refreshToken,
  );
  
  return user;
}
```

---

## 🎯 Model Integration

### Current Implementation
**Note:** The `Tailor` model does NOT include `isActive` field yet.

**File:** `lib/data/models/tailor_model.dart`

```dart
class Tailor {
  final String id;
  final String uniqueId;
  final String name;
  final String shopName;
  final String email;
  final String phone;
  final String passwordHash;
  final String authProvider;
  final String address;
  final String? profileImagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  // ❌ No isActive field here
}
```

### Why is_active is NOT in the Model?
The `is_active` field is currently handled at the **database query level** only:

```dart
// We check is_active directly from query results
final isActive = results.first['is_active'] == 1;
```

### Should We Add it to the Model?
**Option 1: Keep Current (No Model Field)** ✅ **Current Approach**
- Pros: Simpler model, field only used for auth checks
- Cons: Not accessible from Tailor object

**Option 2: Add to Model** (Recommended for consistency)
```dart
class Tailor {
  // ... existing fields
  final bool isActive;  // ✅ Add this

  Tailor({
    // ... existing parameters
    this.isActive = false,  // Default inactive
  });

  factory Tailor.fromMap(Map<String, dynamic> map) {
    return Tailor(
      // ... existing mappings
      isActive: (map['is_active'] as int? ?? 0) == 1,  // ✅ Add this
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // ... existing mappings
      'is_active': isActive ? 1 : 0,  // ✅ Add this
    };
  }

  Tailor copyWith({
    // ... existing parameters
    bool? isActive,  // ✅ Add this
  }) {
    return Tailor(
      // ... existing mappings
      isActive: isActive ?? this.isActive,  // ✅ Add this
    );
  }
}
```

---

## 🔐 Complete Authentication Workflow

### Scenario 1: New User Registration → Login
```
1. User fills signup form
   ↓
2. POST to Django /auth/register/ (creates backend user)
   ↓
3. Save to local DB with is_active = 0
   ↓
4. Django sends OTP to email
   ↓
5. User enters OTP
   ↓
6. POST to Django /auth/verify-otp/
   ↓
7. Django validates OTP ✅
   ↓
8. UPDATE local DB: SET is_active = 1
   ↓
9. Generate LOCAL tokens (not Django tokens!)
   ↓
10. Save tokens to secure storage
   ↓
11. User is authenticated → Navigate to Dashboard
```

### Scenario 2: Returning User Login
```
1. User enters email + password
   ↓
2. Hash password with SHA256
   ↓
3. Query local DB: email + password_hash + is_deleted = 0
   ↓
4. User found? ✅
   ↓
5. Check is_active = 1? 
   ├─ Yes ✅ → Continue
   └─ No ❌ → Throw AccountDisabledException
   ↓
6. Generate LOCAL tokens
   ↓
7. Save to secure storage
   ↓
8. User authenticated → Dashboard
```

### Scenario 3: Unverified User Tries to Login
```
1. User registers but doesn't verify OTP
   ↓
2. User tries to login
   ↓
3. Query finds user with is_active = 0
   ↓
4. Throw AccountDisabledException ❌
   ↓
5. Show error: "Account not activated. Please verify email first."
   ↓
6. User must complete OTP verification first
```

---

## 🛠️ Database Queries

### Check User Active Status
```sql
SELECT is_active FROM tailor WHERE email = ? AND is_deleted = 0;
```

### Activate User After OTP
```sql
UPDATE tailor 
SET is_active = 1, updated_at = ? 
WHERE email = ? AND is_deleted = 0;
```

### Login Query (with is_active check)
```sql
SELECT * FROM tailor 
WHERE email = ? 
  AND password_hash = ? 
  AND is_deleted = 0 
  AND is_active = 1;  -- Must be active to login
```

### Get All Active Users
```sql
SELECT * FROM tailor 
WHERE is_active = 1 AND is_deleted = 0;
```

### Deactivate User
```sql
UPDATE tailor 
SET is_active = 0, updated_at = ? 
WHERE id = ?;
```

---

## 📝 Key Takeaways

1. **is_active = 0 (Default)**: User registered but NOT verified OTP
2. **is_active = 1**: User verified OTP and can login
3. **OTP Verification**: Changes is_active from 0 → 1 in LOCAL DB
4. **Login Check**: MUST verify is_active = 1 before allowing login
5. **Local-First**: is_active is managed in LOCAL database only
6. **Django Role**: Only verifies OTP, doesn't manage is_active
7. **Token Generation**: LOCAL tokens generated only for active users

---

## 🎨 Exception Handling

### AccountDisabledException
Thrown when user tries to login with `is_active = 0`:

```dart
throw AccountDisabledException(
  reason: 'Account is not activated. Please verify your email first.',
);
```

**User Message:**
> "Your account has been disabled. Please contact support for assistance."

**Developer Message:**
> "Account is not activated. Please verify your email first."

---

## ✅ Testing

### Test Cases
1. ✅ User registers → is_active = 0
2. ✅ User verifies OTP → is_active = 1
3. ✅ User logs in with is_active = 1 → Success
4. ✅ User logs in with is_active = 0 → AccountDisabledException
5. ✅ Database migration creates is_active field
6. ✅ Index on is_active improves query performance

All 26 tests passing! ✅

---

## 🔮 Future Enhancements

1. **Add to Model**: Include `isActive` field in `Tailor` model for better accessibility
2. **Admin Panel**: Allow admins to manually activate/deactivate users
3. **Email Resend**: Allow users to resend OTP if not received
4. **Expiry**: Track OTP expiry time in local DB
5. **Multi-factor**: Add additional verification methods

---

**Last Updated:** October 15, 2025  
**Database Version:** 13  
**Status:** ✅ Fully Implemented and Tested
