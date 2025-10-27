# Credentials Configuration Guide
## Adding Google and Facebook OAuth Credentials

This guide walks you through adding your actual Google and Facebook credentials to the Tailor App after you've obtained them from the respective developer consoles.

---

## 📋 Prerequisites

Before starting, make sure you have:
- ✅ Google Web Client ID (from Google Cloud Console)
- ✅ Facebook App ID (from Facebook Developers)
- ✅ Facebook Client Token (from Facebook Developers)
- ✅ SHA-1 certificate fingerprint (for Google Android)
- ✅ Facebook key hash (for Facebook Android)

If you don't have these yet, see **SOCIAL_AUTH_SETUP_GUIDE.md** for detailed instructions.

---

## 1️⃣ Configure Android for Facebook

### Step 1: Update strings.xml

**File:** `android/app/src/main/res/values/strings.xml`

Replace the placeholder values:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Tailor App</string>
    
    <!-- REPLACE THESE VALUES -->
    <string name="facebook_app_id">1234567890123456</string>  <!-- Your Facebook App ID -->
    <string name="facebook_client_token">abcdef1234567890abcdef1234567890</string>  <!-- Your Facebook Client Token -->
    <string name="fb_login_protocol_scheme">fb1234567890123456</string>  <!-- fb + Your App ID -->
</resources>
```

**Where to find these values:**
1. Go to https://developers.facebook.com/apps
2. Select your app
3. Settings → Basic:
   - **App ID**: Copy the "App ID" value
   - **Client Token**: Click "Show" next to "App Secret", then copy the Client Token
4. For `fb_login_protocol_scheme`: Add "fb" prefix to your App ID
   - Example: If App ID is `1234567890123456`, use `fb1234567890123456`

### Step 2: Verify AndroidManifest.xml

**File:** `android/app/src/main/AndroidManifest.xml`

The Facebook configuration should already be present (added by us). Verify it looks like this:

```xml
<application>
    <!-- Facebook Configuration -->
    <meta-data 
        android:name="com.facebook.sdk.ApplicationId" 
        android:value="@string/facebook_app_id"/>
    
    <meta-data 
        android:name="com.facebook.sdk.ClientToken" 
        android:value="@string/facebook_client_token"/>
    
    <activity 
        android:name="com.facebook.FacebookActivity"
        android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
        android:label="@string/app_name" />
    
    <activity
        android:name="com.facebook.CustomTabActivity"
        android:exported="true">
        <intent-filter>
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.DEFAULT" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data android:scheme="@string/fb_login_protocol_scheme" />
        </intent-filter>
    </activity>
    
    <!-- Rest of your application configuration -->
</application>
```

✅ **No changes needed** - it automatically reads from strings.xml

---

## 2️⃣ Configure Django Backend

### Step 1: Update Django settings.py

**File:** `backend/config/settings.py` (or wherever your Django settings are)

Add these settings:

```python
# Social Authentication Settings

# Google OAuth2
GOOGLE_OAUTH2_CLIENT_ID = 'YOUR-WEB-CLIENT-ID.apps.googleusercontent.com'

# Facebook OAuth
FACEBOOK_APP_ID = '1234567890123456'  # Your Facebook App ID
FACEBOOK_APP_SECRET = 'your-facebook-app-secret-here'  # Your Facebook App Secret

# Optional: For development, you can use environment variables
import os
GOOGLE_OAUTH2_CLIENT_ID = os.getenv('GOOGLE_CLIENT_ID', 'YOUR-WEB-CLIENT-ID.apps.googleusercontent.com')
FACEBOOK_APP_ID = os.getenv('FACEBOOK_APP_ID', '1234567890123456')
FACEBOOK_APP_SECRET = os.getenv('FACEBOOK_APP_SECRET', 'your-secret-here')
```

**Where to find these values:**

**Google:**
1. Go to https://console.cloud.google.com/
2. Select your project
3. APIs & Services → Credentials
4. Find the **Web Client** (NOT Android client)
5. Copy the Client ID (ends with `.apps.googleusercontent.com`)

**Facebook:**
1. Go to https://developers.facebook.com/apps
2. Select your app
3. Settings → Basic:
   - Copy **App ID**
   - Copy **App Secret** (click "Show")

### Step 2: Update .env file (if using environment variables)

**File:** `backend/.env`

```env
# Google OAuth
GOOGLE_CLIENT_ID=YOUR-WEB-CLIENT-ID.apps.googleusercontent.com

# Facebook OAuth
FACEBOOK_APP_ID=1234567890123456
FACEBOOK_APP_SECRET=your-facebook-app-secret-here
```

---

## 3️⃣ Verify Google Configuration

### Android SHA-1 Certificate

The Google Android Client ID you created should have your debug SHA-1 certificate added. Verify:

1. **Get your SHA-1:**
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Look for "Variant: debug" → "SHA1" → Copy the value

2. **Add to Google Console:**
   - Go to https://console.cloud.google.com/
   - APIs & Services → Credentials
   - Click on your **Android** OAuth 2.0 Client ID
   - Under "SHA-1 certificate fingerprints", verify your SHA-1 is listed
   - If not, click "Add fingerprint" and paste it

---

## 4️⃣ Test Your Configuration

### Test Checklist:

Run your Flutter app and try:

1. **Google Sign In:**
   ```
   - Click "Continue with Google"
   - Select your Google account
   - Should show "Welcome [Name]!" and navigate to dashboard
   ```

2. **Facebook Sign In:**
   ```
   - Click "Continue with Facebook"
   - Authorize the app
   - Should show "Welcome [Name]!" and navigate to dashboard
   ```

3. **Check Django Admin:**
   ```
   - Open Django admin
   - Verify new user was created
   - Check auth_provider field is "google" or "facebook"
   ```

---

## 🐛 Troubleshooting

### Google Sign In Issues:

**"Developer Error" / "Error 10"**
- ❌ Wrong SHA-1 or not added to Google Console
- ✅ Run `./gradlew signingReport` and add the SHA-1

**"Invalid Client"**
- ❌ Using Android Client ID instead of Web Client ID in Django
- ✅ Django needs the **Web Client ID**, not Android Client ID

**"Sign in failed"**
- ❌ Google+ API not enabled
- ✅ Enable "Google+ API" in Google Console

### Facebook Sign In Issues:

**"App Not Setup"**
- ❌ Wrong Facebook App ID in strings.xml
- ✅ Double-check App ID matches Facebook Developer Console

**"Invalid Key Hash"**
- ❌ Wrong key hash or not added to Facebook Console
- ✅ Generate key hash again:
  ```bash
  keytool -exportcert -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore | openssl sha1 -binary | openssl base64
  ```
  Password: `android`

**"Email not returned"**
- ❌ User didn't grant email permission
- ✅ Make sure email permission is requested (already done in code)

### Django Backend Issues:

**"Token validation failed"**
- ❌ Wrong Google Client ID in Django settings
- ✅ Use **Web Client ID**, not Android Client ID

**"Facebook authentication failed"**
- ❌ Wrong App Secret
- ✅ Copy App Secret again from Facebook Developer Console

---

## 📝 Configuration Summary

### Files You Need to Update:

1. **Android:**
   - ✅ `android/app/src/main/res/values/strings.xml` (Facebook credentials)

2. **Django:**
   - ✅ `settings.py` or `.env` (Google Web Client ID, Facebook App ID/Secret)

3. **Google Cloud Console:**
   - ✅ Android Client ID with SHA-1 fingerprint
   - ✅ Web Client ID for Django

4. **Facebook Developer Console:**
   - ✅ Android platform with key hash
   - ✅ App ID and Client Token

---

## ✅ Validation Checklist

Before testing, verify:

- [ ] Facebook App ID in strings.xml matches Facebook Developer Console
- [ ] Facebook Client Token in strings.xml is correct
- [ ] fb_login_protocol_scheme is "fb" + your App ID
- [ ] Google Web Client ID in Django settings (NOT Android Client ID)
- [ ] Facebook App Secret in Django settings
- [ ] SHA-1 added to Google Console Android Client
- [ ] Key hash added to Facebook Console Android platform
- [ ] Google+ API enabled in Google Console
- [ ] Facebook Login product added to Facebook app

---

## 🎉 Success!

Once configured, your users can:
- ✅ Sign in with Google (one click)
- ✅ Sign in with Facebook (one click)
- ✅ No password needed
- ✅ Email automatically verified
- ✅ Profile picture imported

Users created via social auth will have:
- `auth_provider`: "google" or "facebook"
- `email_verified`: `true`
- `profile_image_path`: URL from social profile

---

## 📚 Additional Resources

- **Full Setup Guide:** `SOCIAL_AUTH_SETUP_GUIDE.md`
- **Quick Start:** `SOCIAL_AUTH_QUICKSTART.md`
- **Google OAuth Docs:** https://developers.google.com/identity/sign-in/android
- **Facebook Login Docs:** https://developers.facebook.com/docs/facebook-login/android

---

## 🆘 Need Help?

If you encounter issues not covered here:

1. Check the console logs in VS Code terminal (search for 🔵 or 💙)
2. Check Django server logs for API errors
3. Verify all credentials are copied correctly (no extra spaces)
4. Try clearing app data and reinstalling
5. Refer to SOCIAL_AUTH_SETUP_GUIDE.md for detailed setup steps

---

**Last Updated:** October 17, 2025
**Version:** 1.0
