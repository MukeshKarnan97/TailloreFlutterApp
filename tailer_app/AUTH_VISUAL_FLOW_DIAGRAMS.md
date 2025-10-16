# 🎨 Authentication Visual Flow Diagrams

## Table of Contents
1. [Sign Up Flow](#sign-up-flow)
2. [OTP Verification Flow](#otp-verification-flow)
3. [Sign In Flow](#sign-in-flow)
4. [Token Storage Architecture](#token-storage-architecture)
5. [Database Flow](#database-flow)

---

## Sign Up Flow

### User Interface Flow
```
┌──────────────────────────────────────────────────────────────────────────┐
│                         SIGN UP JOURNEY                                   │
└──────────────────────────────────────────────────────────────────────────┘

Step 1: SignUp Screen
┌─────────────────────────────┐
│         App Logo            │
│    Create Your Account      │
│                             │
│  Name: [Mukesh K         ]  │
│  Shop: [Mukesh K's Shop  ]  │
│  Email:[mukesh@gmail.com ]  │
│  Pass: [••••••••••••••••]   │
│                             │
│    [Create Account] ←────── User clicks
│                             │
│  [Sign in with Google]      │
│  [Sign in with Facebook]    │
│                             │
│  Already have account?      │
│  Sign In                    │
└─────────────────────────────┘
         │
         │ Validates & Submits
         ▼
┌─────────────────────────────┐
│   HybridAuthService         │
│  registerWithBackend()      │
└─────────────────────────────┘
         │
         ├──────────────► Django Backend
         │                 - Creates user (is_active=0)
         │                 - Sends OTP email
         │                 ◄─── Returns user data
         │
         ├──────────────► Local SQLite
         │                 - INSERT INTO tailor
         │                 - is_active = 0
         │                 ◄─── User inserted
         │
         ▼
Step 2: OTP Screen
┌─────────────────────────────┐
│         App Logo            │
│   Verification Code         │
│ We sent OTP to your email   │
│                             │
│ mukesh.dmc97@gmail.com     │
│                             │
│     [5] [0] [9] [6]        │ ←── User enters OTP
│                             │
│      [Verify OTP]          │ ←── User clicks
│                             │
│  Resend OTP in 2:45        │
└─────────────────────────────┘
```

### Backend Flow
```
┌──────────────────────────────────────────────────────────────────────────┐
│                     BACKEND PROCESSING                                    │
└──────────────────────────────────────────────────────────────────────────┘

┌─────────────┐      ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│  SignUp     │      │   Hybrid    │      │  Accounts   │      │   Django    │
│  Screen     │─────►│   Auth      │─────►│  API        │─────►│  Backend    │
│             │      │  Service    │      │  Service    │      │             │
└─────────────┘      └─────────────┘      └─────────────┘      └─────────────┘
                            │                                          │
                            │                                          │
                            ▼                                          ▼
                     ┌─────────────┐                          ┌──────────────┐
                     │   Local     │                          │ • Create User│
                     │  Database   │                          │ • is_active=0│
                     │  Service    │                          │ • Send OTP   │
                     └─────────────┘                          └──────────────┘
                            │
                            ▼
                    ┌────────────────┐
                    │ INSERT INTO    │
                    │ tailor (       │
                    │   id,          │
                    │   email,       │
                    │   password_hash│
                    │   is_active=0  │ ← Not verified yet
                    │ )              │
                    └────────────────┘
```

---

## OTP Verification Flow

### UI Interaction
```
┌──────────────────────────────────────────────────────────────────────────┐
│                     OTP SCREEN INTERACTION                                │
└──────────────────────────────────────────────────────────────────────────┘

User enters: 5 → 0 → 9 → 6

PIN Field 1  PIN Field 2  PIN Field 3  PIN Field 4
   [5]   ────►   [0]   ────►   [9]   ────►   [6]
   │             │             │             │
   │             │             │             │
   ▼             ▼             ▼             ▼
Auto-focus    Auto-focus    Auto-focus    Complete!
  next          next          next

Concatenated: "5096"

        ▼
   [Verify OTP] ←── User clicks
        │
        ▼
  Validation:
  - Length == 4? ✅
  - All digits? ✅
        │
        ▼
  Call Backend
```

### Verification Process
```
┌──────────────────────────────────────────────────────────────────────────┐
│                  OTP VERIFICATION PROCESS                                 │
└──────────────────────────────────────────────────────────────────────────┘

Step 1: Backend Verification
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│ OTP Screen  │─────►│   Hybrid    │─────►│   Django    │
│             │ OTP: │   Auth      │ POST │   Backend   │
│   "5096"    │ 5096 │  Service    │ /api │             │
└─────────────┘      └─────────────┘ /v1/ └─────────────┘
                                      auth/       │
                                      verify-     │
                                      email/      │
                                                  ▼
                                          ┌──────────────┐
                                          │ • Verify OTP │
                                          │ • Match code │
                                          │ • Not expired│
                                          └──────────────┘
                                                  │
                                                  │ ✅ Valid
                                                  ▼
Step 2: Local Activation
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Hybrid    │─────►│   Local     │      │   Update    │
│   Auth      │ GET  │  Database   │─────►│ is_active=1 │
│  Service    │ user │  Service    │ SQL  │             │
└─────────────┘      └─────────────┘      └─────────────┘

Step 3: Token Generation
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Hybrid    │─────►│   Local     │      │  Generate   │
│   Auth      │ Gen  │   Token     │─────►│ • Access    │
│  Service    │ token│  Service    │      │ • Refresh   │
└─────────────┘      └─────────────┘      └─────────────┘

Step 4: Secure Storage
┌─────────────┐      ┌─────────────────────────────────┐
│   Token     │─────►│   TokenStorageService           │
│  Generation │ Save │ ┌─────────────────────────────┐ │
└─────────────┘      │ │ flutter_secure_storage      │ │
                     │ │ (Encrypted)                 │ │
                     │ │                             │ │
                     │ │ • access_token ✅           │ │
                     │ │ • refresh_token ✅          │ │
                     │ │ • user_id ✅                │ │
                     │ │ • user_email ✅             │ │
                     │ │ • user_type: 'tailor' ✅    │ │
                     │ │ • is_logged_in: true ✅     │ │
                     │ │ • last_login_date ✅        │ │
                     │ └─────────────────────────────┘ │
                     └─────────────────────────────────┘

Step 5: Navigation
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│ OTP Screen  │─────►│  Dashboard  │      │ Authenticated│
│             │ nav  │   Screen    │─────►│    User ✅   │
│ Success! ✅  │      │             │      │             │
└─────────────┘      └─────────────┘      └─────────────┘
```

---

## Sign In Flow

### UI to Authentication
```
┌──────────────────────────────────────────────────────────────────────────┐
│                        SIGN IN JOURNEY                                    │
└──────────────────────────────────────────────────────────────────────────┘

Step 1: SignIn Screen
┌─────────────────────────────┐
│         App Logo            │
│    Welcome Back             │
│                             │
│  Email:[mukesh@gmail.com ]  │
│  Pass: [••••••••••••••••]   │
│                             │
│  ☑ Keep me signed in        │
│                             │
│      [Sign In] ←────────── User clicks
│                             │
│  [Forgot Password?]         │
│                             │
│  [Sign in with Google]      │
│  [Sign in with Facebook]    │
│                             │
│  Don't have an account?     │
│  Sign Up                    │
└─────────────────────────────┘
         │
         │ Validates & Submits
         ▼
┌─────────────────────────────┐
│      AuthService            │
│       signIn()              │
└─────────────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│  TailorAuthRepository       │
│       signIn()              │
└─────────────────────────────┘
```

### Database Authentication
```
┌──────────────────────────────────────────────────────────────────────────┐
│                  DATABASE AUTHENTICATION FLOW                             │
└──────────────────────────────────────────────────────────────────────────┘

Step 1: Query User
┌─────────────────┐
│ SELECT * FROM   │
│ tailor WHERE    │
│ email = ? AND   │
│ is_deleted = 0  │
└─────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│ Found: {                                                     │
│   id: "MAT2TZ5PRO",                                         │
│   email: "mukesh.dmc97@gmail.com",                          │
│   password_hash: "kX9p2L...==:5f4dcc3b5aa765...",          │
│   is_active: 1,          ← CHECK THIS!                     │
│   ...                                                        │
│ }                                                            │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
Step 2: Verify is_active
┌─────────────────────────────┐
│ is_active == 1?             │
└─────────────────────────────┘
         │
         ├─── NO (0) ──►  Error: "Account not activated"
         │
         └─── YES (1) ──► Continue ✅
                              │
                              ▼
Step 3: Password Verification
┌──────────────────────────────────────────┐
│ Password Hash: "salt:hash"               │
│                                          │
│ 1. Split by ":"                          │
│    salt = "kX9p2L...=="                  │
│    storedHash = "5f4dcc3b5aa765..."      │
│                                          │
│ 2. Hash input password with salt:        │
│    inputHash = sha256(password + salt)   │
│                                          │
│ 3. Compare:                              │
│    inputHash == storedHash?              │
└──────────────────────────────────────────┘
         │
         ├─── NO ──►  Error: "Invalid password"
         │
         └─── YES ──► Password correct ✅
                          │
                          ▼
Step 4: Generate Tokens
┌────────────────────────────────────────┐
│ Generate Random Tokens:                │
│                                        │
│ accessToken = Random(64 bytes)         │
│ refreshToken = Random(64 bytes)        │
│                                        │
│ Base64 encode both                     │
└────────────────────────────────────────┘
                          │
                          ▼
Step 5: Save to Secure Storage
┌────────────────────────────────────────┐
│ TokenStorageService.saveTokens()       │
│ TokenStorageService.saveUserId()       │
│ TokenStorageService.saveUserEmail()    │
│ TokenStorageService.saveUserType()     │
│ TokenStorageService.saveLoginState()   │
│ TokenStorageService.saveLastLoginDate()│
└────────────────────────────────────────┘
                          │
                          ▼
Step 6: Navigate to Dashboard
┌─────────────┐      ┌─────────────┐
│ SignIn      │─────►│  Dashboard  │
│ Screen      │ nav  │   Screen    │
│ Success! ✅  │      │             │
└─────────────┘      └─────────────┘
```

---

## Token Storage Architecture

### Storage Layers
```
┌──────────────────────────────────────────────────────────────────────────┐
│                    TOKEN STORAGE ARCHITECTURE                             │
└──────────────────────────────────────────────────────────────────────────┘

Application Layer
┌─────────────────────────────────────────────────────────────────┐
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   SignUp     │  │   SignIn     │  │  Dashboard   │         │
│  │   Screen     │  │   Screen     │  │   Screen     │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│         │                  │                  │                 │
│         └──────────────────┼──────────────────┘                 │
│                            ▼                                    │
└─────────────────────────────────────────────────────────────────┘

Service Layer
┌─────────────────────────────────────────────────────────────────┐
│  ┌────────────────────┐         ┌────────────────────┐         │
│  │ HybridAuthService  │         │   AuthService      │         │
│  │                    │         │                    │         │
│  │ • registerWithBE() │         │ • signIn()         │         │
│  │ • verifyOTP()      │         │ • signOut()        │         │
│  └────────────────────┘         └────────────────────┘         │
│            │                              │                     │
│            └──────────────────────────────┘                     │
│                            ▼                                    │
│                   ┌────────────────────┐                        │
│                   │TailorAuthRepository│                        │
│                   │                    │                        │
│                   │ • signIn()         │                        │
│                   │ • isLoggedIn()     │                        │
│                   └────────────────────┘                        │
│                            │                                    │
│                            ▼                                    │
└─────────────────────────────────────────────────────────────────┘

Storage Layer (THE FIX!)
┌──────────────────────────────────────────────────────────────────┐
│                  TokenStorageService (UNIFIED)                    │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │           flutter_secure_storage (Encrypted)               │  │
│  │                                                            │  │
│  │  Storage Keys:                                            │  │
│  │  ┌──────────────────────────────────────────────────────┐ │  │
│  │  │ 'access_token'     → "eyJhbGc..." (encrypted)        │ │  │
│  │  │ 'refresh_token'    → "eyJhbGc..." (encrypted)        │ │  │
│  │  │ 'user_id'          → "MAT2TZ5PRO" (encrypted)        │ │  │
│  │  │ 'user_email'       → "mukesh@..." (encrypted)        │ │  │
│  │  │ 'user_type'        → "tailor" (encrypted)            │ │  │
│  │  │ 'is_logged_in'     → "true" (encrypted)              │ │  │
│  │  │ 'last_login_date'  → "2025-10-16..." (encrypted)     │ │  │
│  │  └──────────────────────────────────────────────────────┘ │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘

⚠️ PREVIOUS ISSUE (NOW FIXED):
❌ HybridAuthService saved to: TokenStorageService
❌ TailorAuthRepository read from: AuthStorageService (different!)
✅ NOW: Everything uses TokenStorageService (same storage!)
```

### Before vs After Fix
```
┌──────────────────────────────────────────────────────────────────────────┐
│                    BEFORE THE FIX (BROKEN)                                │
└──────────────────────────────────────────────────────────────────────────┘

OTP Verification:
┌─────────────────────┐      ┌───────────────────────┐
│ HybridAuthService   │─────►│ TokenStorageService   │
│                     │ Save │ (Secure Storage)      │
│ verifyOTPAndActivate│ here │                       │
└─────────────────────┘      └───────────────────────┘
                              • access_token ✅
                              • user_email ✅

Sign In Check:
┌─────────────────────┐      ┌───────────────────────┐
│TailorAuthRepository │─────►│ AuthStorageService    │
│                     │ Read │ (SharedPreferences)   │
│ isLoggedIn()        │ here │                       │
└─────────────────────┘      └───────────────────────┘
                              • EMPTY! ❌
                              
Result: "Has access token: false" ❌

┌──────────────────────────────────────────────────────────────────────────┐
│                     AFTER THE FIX (WORKING)                               │
└──────────────────────────────────────────────────────────────────────────┘

OTP Verification:
┌─────────────────────┐      ┌───────────────────────┐
│ HybridAuthService   │─────►│ TokenStorageService   │
│                     │ Save │ (Secure Storage)      │
│ verifyOTPAndActivate│ here │                       │
└─────────────────────┘      └───────────────────────┘
                              • access_token ✅
                              • user_email ✅

Sign In Check:
┌─────────────────────┐      ┌───────────────────────┐
│TailorAuthRepository │─────►│ TokenStorageService   │
│                     │ Read │ (Secure Storage)      │
│ isLoggedIn()        │ SAME!│                       │
└─────────────────────┘      └───────────────────────┘
                              • access_token ✅
                              • user_email ✅
                              
Result: "Has access token: true" ✅
```

---

## Database Flow

### Complete Data Flow
```
┌──────────────────────────────────────────────────────────────────────────┐
│                       DATABASE DATA FLOW                                  │
└──────────────────────────────────────────────────────────────────────────┘

Registration:
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Django    │      │   Hybrid    │      │   Local     │
│  Backend    │─────►│   Auth      │─────►│  SQLite     │
│             │ User │  Service    │ Save │             │
└─────────────┘ Data └─────────────┘      └─────────────┘
                                                  │
                                                  ▼
                            ┌───────────────────────────────┐
                            │ INSERT INTO tailor (          │
                            │   id = 'MAT2TZ5PRO',         │
                            │   email = 'mukesh@...',      │
                            │   password_hash = 'salt:hash'│
                            │   is_active = 0,      ← NOTE │
                            │   ...                         │
                            │ )                             │
                            └───────────────────────────────┘

OTP Verification:
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Django    │      │   Hybrid    │      │   Local     │
│  Backend    │─────►│   Auth      │─────►│  SQLite     │
│             │ OTP  │  Service    │Update│             │
│  Verified ✅ │      │             │      │             │
└─────────────┘      └─────────────┘      └─────────────┘
                                                  │
                                                  ▼
                            ┌───────────────────────────────┐
                            │ UPDATE tailor SET             │
                            │   is_active = 1,      ← CHANGE│
                            │   updated_at = NOW()          │
                            │ WHERE id = 'MAT2TZ5PRO'       │
                            └───────────────────────────────┘

Sign In:
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Tailor    │      │   Local     │      │   Token     │
│    Auth     │─────►│  SQLite     │─────►│  Storage    │
│ Repository  │Query │             │ Save │  Service    │
└─────────────┘      └─────────────┘ Token└─────────────┘
       │                    │
       │                    ▼
       │         ┌───────────────────────┐
       │         │ SELECT * FROM tailor  │
       │         │ WHERE email = ?       │
       │         │ AND is_deleted = 0    │
       │         └───────────────────────┘
       │                    │
       │                    ▼
       │         ┌───────────────────────┐
       │         │ Check is_active = 1   │
       │         └───────────────────────┘
       │                    │
       │                    ▼
       │         ┌───────────────────────┐
       │         │ Verify password       │
       │         └───────────────────────┘
       │                    │
       │                    ▼ Success ✅
       └─────────────────────┘
                              │
                              ▼
                   ┌─────────────────────┐
                   │ Generate & Save     │
                   │ Tokens to Secure    │
                   │ Storage             │
                   └─────────────────────┘
```

### Table State Changes
```
┌──────────────────────────────────────────────────────────────────────────┐
│                    TAILOR TABLE STATE CHANGES                             │
└──────────────────────────────────────────────────────────────────────────┘

After Registration (before OTP):
┌────────────────────────────────────────────────────────────────┐
│ tailor table                                                   │
├────────────┬────────────────────────┬───────────────┬─────────┤
│ id         │ email                  │ is_active     │ status  │
├────────────┼────────────────────────┼───────────────┼─────────┤
│ MAT2TZ5PRO │ mukesh.dmc97@gmail.com │ 0 ← NOT YET   │ ❌ LOCKED│
└────────────┴────────────────────────┴───────────────┴─────────┘
         ↓
         │ User completes OTP verification
         ↓

After OTP Verification:
┌────────────────────────────────────────────────────────────────┐
│ tailor table                                                   │
├────────────┬────────────────────────┬───────────────┬─────────┤
│ id         │ email                  │ is_active     │ status  │
├────────────┼────────────────────────┼───────────────┼─────────┤
│ MAT2TZ5PRO │ mukesh.dmc97@gmail.com │ 1 ← VERIFIED  │ ✅ ACTIVE│
└────────────┴────────────────────────┴───────────────┴─────────┘

         ↓
         │ User can now sign in
         ↓

Sign In Check:
┌────────────────────────────────────────────────────────────────┐
│ SELECT * FROM tailor WHERE email = ? AND is_deleted = 0        │
│                                                                │
│ IF is_active == 0:                                            │
│   ❌ REJECT: "Account not activated"                          │
│                                                                │
│ IF is_active == 1:                                            │
│   ✅ ALLOW: Proceed to password verification                  │
└────────────────────────────────────────────────────────────────┘
```

---

**Last Updated:** October 16, 2025  
**Version:** 1.0  

For detailed text documentation, see:
- [AUTHENTICATION_COMPLETE_GUIDE.md](./AUTHENTICATION_COMPLETE_GUIDE.md)
- [AUTH_QUICK_REFERENCE.md](./AUTH_QUICK_REFERENCE.md)
