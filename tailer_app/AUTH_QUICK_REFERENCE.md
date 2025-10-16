# 🚀 Authentication Quick Reference Guide

## Quick Navigation
- [Sign Up](#sign-up-flow) | [Sign In](#sign-in-flow) | [Screens](#screens) | [Services](#services) | [Database](#database)

---

## Sign Up Flow

### User Journey
```
1. SignUp Screen → Enter details
2. Click "Sign Up" → Backend registration
3. OTP Screen → Enter 4-digit code
4. Click "Verify" → Account activated
5. Dashboard → User authenticated ✅
```

### Screen: SignUp Screen
**File:** `lib/features/auth/screens/signup_screen.dart`

**Fields:**
- Name (required)
- Shop Name (required)
- Email (required, validated)
- Password (required, min 8 chars, uppercase, lowercase, number)

**Key Service Call:**
```dart
await HybridAuthService().registerWithBackend(
  name: name,
  shopName: shopName,
  email: email,
  phone: phone,
  password: password,
  passwordConfirm: password,
);
```

**What Happens:**
1. ✅ Django creates user (is_active = false)
2. ✅ Django sends OTP email
3. ✅ User inserted into local SQLite (is_active = 0)
4. ✅ Navigate to OTP screen

---

## OTP Verification Flow

### Screen: OTP Screen
**File:** `lib/features/auth/screens/otp_screen.dart`

**Features:**
- 4 PIN input fields
- Auto-focus on next field
- Resend OTP (3-minute cooldown)
- Error display

**Key Service Call:**
```dart
await HybridAuthService().verifyOTPAndActivate(
  email: email,
  otpCode: otp,
);
```

**What Happens:**
1. ✅ Django verifies OTP
2. ✅ Update local DB: is_active = 1
3. ✅ Generate local tokens (access + refresh)
4. ✅ Save to TokenStorageService (secure storage)
5. ✅ Navigate to dashboard

**After Verification (Local DB):**
```dart
TokenStorage contains:
- Access Token ✅
- Refresh Token ✅
- User ID ✅
- User Email ✅
- User Type: 'tailor' ✅
- Login State: true ✅
- Last Login Date ✅
```

---

## Sign In Flow

### User Journey
```
1. SignIn Screen → Enter email & password
2. Check "Keep me signed in" (optional)
3. Click "Sign In" → Local authentication
4. Dashboard → User authenticated ✅
```

### Screen: SignIn Screen
**File:** `lib/features/auth/screens/signin_screen.dart`

**Fields:**
- Email (required, validated)
- Password (required)
- Keep me signed in (checkbox)

**Key Service Call:**
```dart
await AuthService().signIn(
  email: email,
  password: password,
  keepSignedIn: keepSignedIn,
);
```

**What Happens:**
1. ✅ Query local DB: `SELECT * FROM tailor WHERE email = ?`
2. ✅ Check user exists
3. ✅ Check `is_active == 1` (must be verified)
4. ✅ Verify password (hash comparison)
5. ✅ Generate tokens
6. ✅ Save to TokenStorageService
7. ✅ Navigate to dashboard

**Authentication Check:**
```dart
// This will now return TRUE after fix
final isLoggedIn = await TailorAuthRepository().isLoggedIn();
// Checks:
// - Has access token? ✅
// - Has user email? ✅
```

---

## Screens

### 1. SignUp Screen
**Path:** `lib/features/auth/screens/signup_screen.dart`

**UI Components:**
```
┌─────────────────────────────┐
│         App Logo            │
│      Sign Up Title          │
│                             │
│  [Name Field]              │
│  [Shop Name Field]         │
│  [Email Field]             │
│  [Password Field]          │
│                             │
│  [Sign Up Button]          │
│                             │
│  [Google Sign Up]          │
│  [Facebook Sign Up]        │
│                             │
│  Already have account?      │
│  [Sign In Link]            │
│                             │
│         [🌐 Language]       │
└─────────────────────────────┘
```

**Validation:**
- Name: Required
- Shop Name: Required
- Email: Required + format + async existence check
- Password: Min 8 chars + uppercase + lowercase + number

### 2. OTP Screen
**Path:** `lib/features/auth/screens/otp_screen.dart`

**UI Components:**
```
┌─────────────────────────────┐
│         App Logo            │
│   Verification Code         │
│ We sent OTP to your email   │
│                             │
│   your@email.com           │
│                             │
│  [_] [_] [_] [_]           │  ← 4 PIN fields
│                             │
│  [Error Message]           │  ← If verification fails
│                             │
│  [Verify Button]           │
│                             │
│  Resend OTP in 2:35        │  ← Countdown
│  [Resend OTP]              │  ← Enabled after countdown
└─────────────────────────────┘
```

**Features:**
- Auto-focus on next field when digit entered
- Backspace returns to previous field
- 3-minute resend cooldown
- Error display with retry

### 3. SignIn Screen
**Path:** `lib/features/auth/screens/signin_screen.dart`

**UI Components:**
```
┌─────────────────────────────┐
│         App Logo            │
│      Sign In Title          │
│                             │
│  [Email Field]             │
│  [Password Field]          │
│                             │
│  ☐ Keep me signed in       │
│                             │
│  [Sign In Button]          │
│                             │
│  [Forgot Password?]        │
│                             │
│  [Google Sign In]          │
│  [Facebook Sign In]        │
│                             │
│  Don't have an account?     │
│  [Sign Up Link]            │
│                             │
│         [🌐 Language]       │
└─────────────────────────────┘
```

**Validation:**
- Email: Required + format
- Password: Required + min 8 chars

---

## Services

### HybridAuthService
**File:** `lib/data/services/hybrid_auth_service.dart`

**Purpose:** Registration + OTP verification (Backend + Local sync)

**Key Methods:**
| Method | Purpose | Returns |
|--------|---------|---------|
| `initialize()` | Restore session | `Future<void>` |
| `registerWithBackend()` | Sign up new user | `Future<RegisterResponse>` |
| `verifyOTPAndActivate()` | Verify OTP & activate | `Future<bool>` |
| `checkEmailExists()` | Check if email exists | `Future<bool>` |
| `logout()` | Clear session | `Future<void>` |

**Properties:**
| Property | Type | Description |
|----------|------|-------------|
| `currentTailor` | `Tailor?` | Currently authenticated user |
| `isAuthenticated` | `bool` | Authentication status |
| `currentUserEmail` | `String?` | Current user's email |

### AuthService
**File:** `lib/data/services/auth_service.dart`

**Purpose:** Local authentication & session management

**Key Methods:**
| Method | Purpose | Returns |
|--------|---------|---------|
| `initialize()` | Restore session | `Future<void>` |
| `signIn()` | Login with credentials | `Future<bool>` |
| `signOut()` | Logout | `Future<void>` |
| `checkEmailExists()` | Check if email exists | `Future<bool>` |
| `setKeepLoggedIn()` | Set session persistence | `Future<void>` |

**Properties:**
| Property | Type | Description |
|----------|------|-------------|
| `currentTailor` | `Tailor?` | Currently authenticated user |
| `currentUser` | `Tailor?` | Alias for currentTailor |
| `isAuthenticated` | `bool` | Authentication status |
| `isLoggedIn` | `bool` | Alias for isAuthenticated |
| `currentUserEmail` | `String?` | Current user's email |
| `keepSignedIn` | `bool` | Session persistence setting |

### TailorAuthRepository
**File:** `lib/data/repositories/tailor_auth_repository.dart`

**Purpose:** Database operations for authentication

**Key Methods:**
| Method | Purpose | Returns |
|--------|---------|---------|
| `signUp()` | Create new user in DB | `Future<Tailor>` |
| `signIn()` | Authenticate user | `Future<Tailor>` |
| `getCurrentTailor()` | Get current user | `Future<Tailor?>` |
| `isLoggedIn()` | Check login status | `Future<bool>` |
| `signOut()` | Clear session | `Future<void>` |
| `checkEmailExists()` | Check email in DB | `Future<bool>` |

### TokenStorageService
**File:** `lib/core/services/token_storage_service.dart`

**Purpose:** Secure token & session management

**Storage:** `flutter_secure_storage` (encrypted)

**Key Methods:**
| Method | Purpose | Returns |
|--------|---------|---------|
| `saveTokens()` | Save access & refresh tokens | `Future<void>` |
| `getAccessToken()` | Get access token | `Future<String?>` |
| `getRefreshToken()` | Get refresh token | `Future<String?>` |
| `saveUserId()` | Save user ID | `Future<void>` |
| `getUserId()` | Get user ID | `Future<String?>` |
| `saveUserEmail()` | Save email | `Future<void>` |
| `getUserEmail()` | Get email | `Future<String?>` |
| `saveLoginState()` | Save login state | `Future<void>` |
| `getLoginState()` | Get login state | `Future<bool>` |
| `isAuthenticated()` | Check if tokens exist | `Future<bool>` |
| `clearAll()` | Clear all data | `Future<void>` |

---

## Database

### Tailor Table Schema

**File:** `lib/data/services/local_db_service.dart`

**Table:** `tailor`

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `id` | TEXT | Primary key (MAT + 7 chars) | MAT2TZ5PRO |
| `unique_id` | TEXT | Same as id | MAT2TZ5PRO |
| `name` | TEXT | User's full name | Mukesh K |
| `shop_name` | TEXT | Business name | Mukesh K's Shop |
| `email` | TEXT | Email address (unique) | mukesh.dmc97@gmail.com |
| `phone` | TEXT | Phone number | +1234567890 |
| `password_hash` | TEXT | Format: "salt:hash" | kX9p...==:5f4dcc... |
| `auth_provider` | TEXT | Auth method | email / google / facebook |
| `address` | TEXT | Business address | 123 Main St |
| `profile_image_url` | TEXT | Profile picture | https://... |
| **`is_active`** | INTEGER | **⚠️ OTP verification status** | **0 or 1** |
| `is_deleted` | INTEGER | Soft delete flag | 0 or 1 |
| `created_at` | TEXT | Creation timestamp | 2025-10-16T08:27:00Z |
| `updated_at` | TEXT | Last update timestamp | 2025-10-16T08:30:00Z |

### Critical Field: is_active

**Purpose:** OTP verification status

**Values:**
- `0` = User registered but NOT verified → **CANNOT LOGIN**
- `1` = User verified via OTP → **CAN LOGIN**

**Set By:**
```dart
// During registration
is_active = 0  // Not verified yet

// After OTP verification
UPDATE tailor SET is_active = 1 WHERE email = ?
```

**Checked By:**
```dart
// During sign in
final isActive = tailorData['is_active'] == 1;
if (!isActive) {
  throw Exception('Account not activated. Please verify your OTP first.');
}
```

### Password Storage

**Format:** `"salt:hash"`

**Example:** `"kX9p2L8vM3...==:5f4dcc3b5aa765d61d8327deb882cf99"`

**Hashing Process:**
```dart
// Registration
final salt = base64Encode(Random.secure().bytes(32));
final bytes = utf8.encode(password + salt);
final hash = sha256.convert(bytes).toString();
final passwordHash = "$salt:$hash";

// Verification
final parts = passwordHash.split(':');
final salt = parts[0];
final storedHash = parts[1];
final inputBytes = utf8.encode(inputPassword + salt);
final inputHash = sha256.convert(inputBytes).toString();
return inputHash == storedHash;
```

---

## Testing

### Quick Tests

**1. Check Database:**
```powershell
flutter run lib/check_database.dart
```

**Expected Output:**
```
✅ Database opened successfully
Total tailors: 1

Tailor #1:
  • ID: MAT2TZ5PRO
  • Email: mukesh.dmc97@gmail.com
  • is_active: 1  ← Must be 1 after OTP!
```

**2. Test Sign Up:**
```
1. Open app → SignUp screen
2. Enter: name, shop, email, password
3. Click "Sign Up" → Check email for OTP
4. Enter OTP → Click "Verify"
5. Should navigate to dashboard ✅
```

**3. Test Sign In:**
```
1. Open app → SignIn screen
2. Enter: mukesh.dmc97@gmail.com / Admin#234
3. Click "Sign In"
4. Should navigate to dashboard ✅
```

**4. Check Logs:**
```
Expected after login:
TailorAuthRepository: Checking login status
  - Has access token: true  ✅
  - Has user email: true    ✅
```

---

## Common Errors

### ❌ "Account not activated"
**Cause:** `is_active = 0` in database  
**Fix:** Complete OTP verification

### ❌ "User not found"
**Cause:** Email not in database  
**Fix:** Sign up first

### ❌ "Invalid password"
**Cause:** Wrong password  
**Fix:** Enter correct password

### ❌ "Has access token: false"
**Cause:** Token storage issue (FIXED)  
**Fix:** Already fixed - now using TokenStorageService consistently

---

## File Locations

### Screens
- `lib/features/auth/screens/signup_screen.dart`
- `lib/features/auth/screens/signin_screen.dart`
- `lib/features/auth/screens/otp_screen.dart`

### Services
- `lib/data/services/hybrid_auth_service.dart`
- `lib/data/services/auth_service.dart`
- `lib/core/services/token_storage_service.dart`
- `lib/data/services/local_db_service.dart`

### Repositories
- `lib/data/repositories/tailor_auth_repository.dart`

### Models
- `lib/data/models/tailor_model.dart`

---

## Quick Commands

**Pull Database:**
```powershell
adb shell "run-as com.example.tailer_app cat databases/tailor_app.db" > database/tailor_app.db
```

**Check Database:**
```powershell
flutter run lib/check_database.dart
```

**Run App:**
```powershell
flutter run
```

**Clean Build:**
```powershell
flutter clean
flutter pub get
flutter run
```

---

**Last Updated:** October 16, 2025  
**Version:** 1.0  
**Status:** ✅ Ready to Use

For detailed documentation, see: [AUTHENTICATION_COMPLETE_GUIDE.md](./AUTHENTICATION_COMPLETE_GUIDE.md)
