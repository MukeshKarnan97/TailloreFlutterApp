# Google Client ID Setup Guide

## 🎯 What You Need

You need **TWO** different Client IDs from Google Cloud Console:

1. **Web Client ID** - For backend verification (Django)
2. **Android Client ID** - For mobile app authentication

---

## 📋 Current Status

✅ You have Google Cloud Project: **exchange-maatrax**  
✅ Project ID: **881979011144**  
❌ You have wrong type (Desktop app credentials)  
❌ Need to create Android + Web credentials

---

## 🚀 Step-by-Step Setup

### Step 1: Get Your SHA-1 Certificate

Open PowerShell in your project and run:

```powershell
cd android
./gradlew signingReport
```

**Look for this section:**
```
Variant: debug
Config: debug
Store: C:\Users\mukes\.android\debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX:...
SHA1: AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:00:AA:BB:CC:DD
SHA-256: ...
```

**Copy the SHA1 value** (the long one with colons)

---

### Step 2: Create Android Client ID

1. **Go to:** https://console.cloud.google.com/apis/credentials?project=exchange-maatrax

2. **Click:** "+ CREATE CREDENTIALS" → "OAuth client ID"

3. **Fill in:**
   - Application type: **Android**
   - Name: **Tailor App Android**
   - Package name: `com.example.tailer_app`
   - SHA-1 certificate fingerprint: **[Paste the SHA1 you copied]**

4. **Click:** "CREATE"

5. **Save the Client ID** (looks like: `881979011144-xxxxxx.apps.googleusercontent.com`)

---

### Step 3: Create Web Client ID

1. **Still on:** https://console.cloud.google.com/apis/credentials?project=exchange-maatrax

2. **Click:** "+ CREATE CREDENTIALS" → "OAuth client ID"

3. **Fill in:**
   - Application type: **Web application**
   - Name: **Tailor App Backend**
   - Authorized JavaScript origins: (optional for now)
   - Authorized redirect URIs: (optional for now)

4. **Click:** "CREATE"

5. **IMPORTANT: Copy this Web Client ID** - You'll use it in multiple places!

---

### Step 4: Enable Google+ API (Required!)

1. **Go to:** https://console.cloud.google.com/apis/library/plus.googleapis.com?project=exchange-maatrax

2. **Click:** "ENABLE"

(Or search for "Google+ API" in API Library and enable it)

---

## 📝 Where to Add Client IDs in Flutter

### Location 1: `google_auth_simple.dart` ✅ (Already marked)

**File:** `lib/data/services/google_auth_simple.dart`

```dart
/// ⚠️ IMPORTANT: ADD YOUR GOOGLE WEB CLIENT ID HERE
/// Get it from: https://console.cloud.google.com/apis/credentials
/// Create: OAuth 2.0 Client ID → Web application
const String GOOGLE_WEB_CLIENT_ID = 'YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com';
```

**Replace:** `YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com`  
**With:** Your Web Client ID from Step 3

---

### Location 2: Django Backend (If you have one)

**File:** `settings.py` (on your Django server)

```python
# Google OAuth2 Settings
GOOGLE_OAUTH2_CLIENT_ID = 'YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com'
```

**Use the same Web Client ID** from Step 3

---

## 🔧 Android Configuration (Automatic)

The Android Client ID you created in Step 2 works **automatically** when:
- Package name matches: `com.example.tailer_app`
- SHA-1 matches your debug keystore
- Google+ API is enabled

No need to manually add it to any file! 🎉

---

## ✅ Verification Checklist

Before testing, make sure:

- [ ] SHA-1 obtained from `./gradlew signingReport`
- [ ] Android Client ID created with correct package name
- [ ] Web Client ID created
- [ ] Google+ API enabled
- [ ] Web Client ID added to `google_auth_simple.dart`
- [ ] Web Client ID added to Django `settings.py`

---

## 🧪 Testing

After setup:

```powershell
cd c:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app
flutter clean
flutter pub get
flutter run
```

Click the "Continue with Google" button and test!

---

## ⚠️ Common Issues

### Issue 1: "Sign in failed" or "Developer Error"
**Solution:** Check SHA-1 matches exactly

### Issue 2: "API not enabled"
**Solution:** Enable Google+ API in Cloud Console

### Issue 3: "Invalid client"
**Solution:** Check package name is `com.example.tailer_app`

### Issue 4: Still using placeholder implementation
**Solution:** We need to downgrade google_sign_in to v6.1.5 first!

---

## 📌 Quick Reference

| What | Value |
|------|-------|
| **Package Name** | `com.example.tailer_app` |
| **Project** | exchange-maatrax |
| **Project ID** | 881979011144 |
| **SHA-1** | Get from `./gradlew signingReport` |
| **Android Client ID** | Create in Step 2 |
| **Web Client ID** | Create in Step 3 (use in code) |

---

## 🎯 Next Steps

1. **Run SHA-1 command** (Step 1)
2. **Create both Client IDs** (Steps 2 & 3)
3. **Enable Google+ API** (Step 4)
4. **Update `google_auth_simple.dart`** with Web Client ID
5. **Decide:** Downgrade to google_sign_in v6.1.5 OR wait for v7.x fix
6. **Test** the app!

---

**Created:** October 17, 2025  
**Status:** Ready for credential setup
