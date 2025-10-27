# 🎨 Visual Flow: Social Authentication

## Your Current UI Setup

### Sign-In Screen
```
┌─────────────────────────────────────┐
│         Tailor App Sign In          │
├─────────────────────────────────────┤
│                                     │
│  Email: [________________]          │
│                                     │
│  Password: [________________]       │
│                                     │
│  [        Sign In Button       ]    │
│                                     │
│  ─────────── OR ───────────         │
│                                     │
│  [🔴 Google ] [🔵 Facebook ]       │  ← EXISTING BUTTONS!
│                                     │
│  Don't have account? Sign Up        │
│                                     │
└─────────────────────────────────────┘
```

### Sign-Up Screen
```
┌─────────────────────────────────────┐
│         Tailor App Sign Up          │
├─────────────────────────────────────┤
│                                     │
│  Full Name: [________________]      │
│                                     │
│  Email: [________________]          │
│                                     │
│  Phone: [________________]          │
│                                     │
│  Password: [________________]       │
│                                     │
│  [        Sign Up Button       ]    │
│                                     │
│  ─────────── OR ───────────         │
│                                     │
│  [🔴 Google ] [🔵 Facebook ]       │  ← EXISTING BUTTONS!
│                                     │
│  Already have account? Sign In      │
│                                     │
└─────────────────────────────────────┘
```

---

## 🔄 Complete Authentication Flow

### When User Clicks Google Button:

```
USER ACTION
    │
    ▼
┌──────────────────────────────────────────────┐
│ 1. Click "Google" Button                    │
│    Widget: SignUpGoogleFacebookButton        │
│    File: AuthGoogleButton.dart               │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────┐
│ 2. Flutter Calls Google Sign-In SDK          │
│    Method: _handleGoogleSignIn()             │
│    Service: SocialAuthService                │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────┐
│ 3. Google Native Login Dialog Opens          │
│                                              │
│    ┌────────────────────────────┐           │
│    │  Choose an account         │           │
│    ├────────────────────────────┤           │
│    │  ◉ mukesh@gmail.com        │           │
│    │  ○ another@gmail.com       │           │
│    │  ○ Use another account     │           │
│    └────────────────────────────┘           │
│                                              │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────┐
│ 4. User Selects Account & Grants Permissions │
│                                              │
│    ┌────────────────────────────┐           │
│    │  Tailor App wants to:      │           │
│    │  • View your email         │           │
│    │  • View your profile       │           │
│    │                            │           │
│    │  [Cancel]  [Allow]         │           │
│    └────────────────────────────┘           │
│                                              │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────┐
│ 5. Google Returns User Data                 │
│                                              │
│    {                                         │
│      "id": "117234567890123456789",          │
│      "name": "Mukesh Karnan",                │
│      "email": "mukesh@example.com",          │
│      "photo": "https://...",                 │
│      "idToken": "eyJhbGciOi..."              │
│    }                                         │
│                                              │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────┐
│ 6. Flutter Sends to Django Backend           │
│                                              │
│    POST /api/accounts/auth/google/           │
│    {                                         │
│      "id_token": "eyJhbGciOi...",            │
│      "name": "Mukesh Karnan",                │
│      "email": "mukesh@example.com",          │
│      "photo_url": "https://..."              │
│    }                                         │
│                                              │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────┐
│ 7. Django Processes Request                  │
│                                              │
│    ┌─────────────────────────────┐          │
│    │ Verify ID Token with Google │          │
│    │ ✓ Token is valid            │          │
│    └─────────────────────────────┘          │
│                                              │
│    ┌─────────────────────────────┐          │
│    │ Check if user exists        │          │
│    │ • Email: mukesh@example.com │          │
│    │ • Found: No → Create new    │          │
│    └─────────────────────────────┘          │
│                                              │
│    ┌─────────────────────────────┐          │
│    │ Generate JWT Token          │          │
│    │ • access_token              │          │
│    │ • refresh_token             │          │
│    └─────────────────────────────┘          │
│                                              │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────┐
│ 8. Django Returns Response                   │
│                                              │
│    {                                         │
│      "access": "eyJ0eXAiOiJKV1Q...",         │
│      "refresh": "eyJ0eXAiOiJKV1Q...",        │
│      "user": {                               │
│        "id": 42,                             │
│        "email": "mukesh@example.com",        │
│        "name": "Mukesh Karnan",              │
│        "photo_url": "https://...",           │
│        "auth_provider": "google"             │
│      }                                       │
│    }                                         │
│                                              │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────┐
│ 9. Flutter Saves to Local Database           │
│                                              │
│    SQLite: tailor_app.db                     │
│    Table: tailor                             │
│                                              │
│    INSERT INTO tailor (                      │
│      id, email, password, full_name          │
│    ) VALUES (                                │
│      42,                                     │
│      'mukesh@example.com',                   │
│      '[SHA256_HASH]',  ← Special hash        │
│      'Mukesh Karnan'                         │
│    )                                         │
│                                              │
│    SecureStorage: auth_token                 │
│    Save JWT: "eyJ0eXAiOiJKV1Q..."            │
│                                              │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────┐
│ 10. Show Success & Navigate                  │
│                                              │
│    ┌────────────────────────────┐           │
│    │ ✓ Welcome Mukesh Karnan!   │           │
│    │   Signed in successfully.  │           │
│    └────────────────────────────┘           │
│                                              │
│    Navigate to: Dashboard                    │
│                                              │
└──────────────────────────────────────────────┘
```

---

## 📱 Facebook Flow (Similar Process)

```
USER CLICKS FACEBOOK
    │
    ▼
Facebook SDK Opens Login Dialog
    │
    ▼
User Logs In with Facebook Credentials
    │
    ▼
Facebook Returns Access Token + User Data
    │
    ▼
Flutter Sends to Django:
POST /api/accounts/auth/facebook/
{
  "access_token": "EAABwzLixnjY...",
  "user_id": "123456789012345",
  "name": "Mukesh Karnan",
  "email": "mukesh@example.com",
  "photo_url": "https://..."
}
    │
    ▼
Django Verifies Token with Facebook API
    │
    ▼
Django Creates/Gets User + Returns JWT
    │
    ▼
Flutter Saves to Local DB + SecureStorage
    │
    ▼
Navigate to Dashboard
```

---

## 🔑 Key Differences: Google vs Facebook

| Aspect | Google | Facebook |
|--------|--------|----------|
| **SDK** | google_sign_in | flutter_facebook_auth |
| **Token Type** | ID Token (JWT) | Access Token |
| **Verification** | Google API verifies ID Token | Facebook Graph API verifies Access Token |
| **User Dialog** | Native Android Google dialog | Facebook WebView/App login |
| **Permissions** | email, profile | email, public_profile |
| **Token Format** | JWT: `eyJhbGci...` | String: `EAABwzLi...` |

---

## 📂 File Structure Reference

```
lib/
├── features/
│   └── auth/
│       ├── screens/
│       │   ├── signin_screen.dart       ← Google/FB buttons here
│       │   └── signup_screen.dart       ← Google/FB buttons here
│       └── widgets/
│           └── AuthGoogleButton.dart    ← MAIN BUTTON WIDGET
│
├── data/
│   └── services/
│       ├── social_auth_service.dart     ← Unified interface
│       ├── google_auth_simple.dart      ← Google SDK calls
│       ├── facebook_auth_service.dart   ← Facebook SDK calls
│       └── accounts_api_service.dart    ← Django API calls
│
└── core/
    └── services/
        └── hybrid_auth_service.dart     ← Orchestrates everything
```

---

## 🎯 What You Need to Do

### Nothing in UI! Buttons are already there!

Just add credentials:

1. **Google:**
   - Get Web Client ID
   - Add to `google_auth_simple.dart` line 6

2. **Facebook:**
   - Get App ID + Client Token
   - Add to `android/app/src/main/res/values/strings.xml`

3. **Test:**
   - Run the app
   - Click existing buttons
   - Everything works! 🎉

---

## 📋 Quick Checklist

- [x] Google button exists in Sign-In screen
- [x] Google button exists in Sign-Up screen
- [x] Facebook button exists in Sign-In screen
- [x] Facebook button exists in Sign-Up screen
- [x] All services implemented
- [x] All API calls ready
- [ ] Add Google Web Client ID ← **ONLY THIS**
- [ ] Add Facebook credentials ← **AND THIS**
- [ ] Test the buttons ← **THEN TEST**

---

**Your buttons are already perfectly wired up!** 🚀

Just add the credentials and they'll work immediately!
