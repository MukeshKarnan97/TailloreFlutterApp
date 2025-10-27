# Google & Facebook Authentication - Complete Setup Guide

## 📋 Overview

This guide covers complete implementation of Google and Facebook authentication for your Tailor App, including:
- Backend API integration
- Flutter implementation
- Platform-specific configuration (Android, iOS)
- Testing steps

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                   SOCIAL AUTH FLOW ARCHITECTURE                      │
└─────────────────────────────────────────────────────────────────────┘

User clicks "Sign in with Google/Facebook"
          │
          ▼
Flutter App initiates OAuth flow
          │
          ▼
Google/Facebook SDK opens browser/app
          │
          ▼
User grants permissions
          │
          ▼
SDK returns tokens (access_token, id_token, user_id)
          │
          ▼
Flutter sends tokens to Django backend
          │
          ▼
Django validates tokens with Google/Facebook
          │
          ▼
Django creates/finds user in database
          │
          ▼
Django returns JWT tokens + user data
          │
          ▼
Flutter stores tokens locally
          │
          ▼
User is signed in!
```

## 🔑 What You Need To Do

### Phase 1: Get API Credentials

#### A. Google OAuth Setup (30 minutes)

**1. Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com/
   - Create new project or select existing: "Tailor App"

**2. Enable Google+ API**
   - Navigation: APIs & Services → Library
   - Search: "Google+ API"
   - Click "Enable"

**3. Create OAuth 2.0 Credentials**
   - Navigation: APIs & Services → Credentials
   - Click "Create Credentials" → "OAuth client ID"

**4. Configure OAuth Consent Screen (FIRST TIME ONLY)**
   - User Type: External
   - App name: Tailor App
   - User support email: your@email.com
   - Developer contact: your@email.com
   - Scopes: email, profile
   - Test users: Add your Gmail accounts
   - Click "Save and Continue"

**5. Create Android OAuth Client**
   ```
   Application type: Android
   Name: Tailor App (Android)
   
   Package name: com.example.tailer_app
   
   SHA-1 certificate fingerprint:
   - Debug: Get from terminal (see below)
   - Release: Get when publishing app
   ```

   **Get Debug SHA-1:**
   ```bash
   # On Windows (in terminal)
   cd android
   ./gradlew signingReport
   
   # Look for: SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX...
   # Copy the SHA1 value
   ```

**6. Create Web OAuth Client (for backend validation)**
   ```
   Application type: Web application
   Name: Tailor App (Web)
   
   Authorized JavaScript origins:
   - http://localhost:8000
   - http://192.168.0.7:8000
   - https://yourdomain.com (production)
   
   Authorized redirect URIs:
   - http://localhost:8000/auth/google/callback
   - http://192.168.0.7:8000/auth/google/callback
   ```

**7. Save Client IDs**
   ```
   Android Client ID: 
   xxx-yyy.apps.googleusercontent.com
   
   Web Client ID (for backend):
   aaa-bbb.apps.googleusercontent.com
   
   Web Client Secret:
   GOCSPX-xxxxxxxxxxxxx
   ```

#### B. Facebook App Setup (20 minutes)

**1. Go to Facebook Developers**
   - Visit: https://developers.facebook.com/
   - Click "My Apps" → "Create App"

**2. Create App**
   - Use case: "Other"
   - App type: "Consumer"
   - App name: "Tailor App"
   - Contact email: your@email.com
   - Click "Create App"

**3. Get App ID and App Secret**
   - Settings → Basic
   - Copy: App ID (12-16 digits)
   - Copy: App Secret (32 characters)
   - Save changes

**4. Add Facebook Login Product**
   - Dashboard → Add Product
   - Find "Facebook Login" → Click "Set Up"
   - Select platform: "Android"

**5. Configure Android Settings**
   ```
   Package Name: com.example.tailer_app
   
   Default Activity Class Name:
   com.example.tailer_app.MainActivity
   
   Key Hashes: (generate from terminal - see below)
   ```

   **Generate Key Hash:**
   ```bash
   # Windows (in terminal)
   keytool -exportcert -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore | openssl sha1 -binary | openssl base64
   
   # Password when asked: android
   # Copy the output hash
   ```

**6. Configure Settings**
   - Settings → Basic
   - Add Platform: Android
     - Package name: com.example.tailer_app
     - Class name: com.example.tailer_app.MainActivity
     - Key hash: (paste from above)
   
   - Privacy Policy URL: https://yourwebsite.com/privacy
   - Terms of Service URL: https://yourwebsite.com/terms
   
**7. Make App Live**
   - App Review → Permissions and Features
   - Request: email, public_profile
   - Switch "In Development" to "Live" (after testing)

**8. Save Credentials**
   ```
   Facebook App ID: 1234567890123456
   Facebook App Secret: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

### Phase 2: Configure Flutter App

#### A. Update Android Configuration

**1. Update `android/app/src/main/AndroidManifest.xml`:**
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <!-- Existing MainActivity -->
        <activity
            android:name=".MainActivity"
            ...>
        </activity>

        <!-- Add Facebook Configuration -->
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
    </application>

    <!-- Add Internet Permission -->
    <uses-permission android:name="android.permission.INTERNET"/>
</manifest>
```

**2. Create `android/app/src/main/res/values/strings.xml`:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Tailor App</string>
    <string name="facebook_app_id">1234567890123456</string>
    <string name="facebook_client_token">xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx</string>
    <string name="fb_login_protocol_scheme">fb1234567890123456</string>
</resources>
```
**Replace with your actual Facebook App ID and Client Token!**

**3. Update `android/app/build.gradle`:**
```gradle
android {
    defaultConfig {
        // Add this
        minSdkVersion 21  // Facebook requires min SDK 21
    }
}

dependencies {
    // These should already be added by the packages
    implementation 'com.facebook.android:facebook-android-sdk:latest.release'
}
```

#### B. Update iOS Configuration (if supporting iOS)

**1. Update `ios/Runner/Info.plist`:**
```xml
<dict>
    <!-- Existing keys -->
    
    <!-- Google Sign In -->
    <key>GIDClientID</key>
    <string>YOUR_WEB_CLIENT_ID.apps.googleusercontent.com</string>
    
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <!-- Reverse of client ID -->
                <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
            </array>
        </dict>
        
        <!-- Facebook -->
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>fb1234567890123456</string>
            </array>
        </dict>
    </array>
    
    <!-- Facebook Configuration -->
    <key>FacebookAppID</key>
    <string>1234567890123456</string>
    <key>FacebookClientToken</key>
    <string>xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx</string>
    <key>FacebookDisplayName</key>
    <string>Tailor App</string>
    
    <key>LSApplicationQueriesSchemes</key>
    <array>
        <string>fbapi</string>
        <string>fb-messenger-share-api</string>
        <string>fbauth2</string>
        <string>fbshareextension</string>
    </array>
</dict>
```

### Phase 3: Configure Django Backend

**1. Install Required Packages:**
```bash
pip install google-auth google-auth-oauthlib google-auth-httplib2
pip install facebook-sdk
```

**2. Add to `settings.py`:**
```python
# Social Auth Configuration
GOOGLE_OAUTH2_CLIENT_ID = 'your-web-client-id.apps.googleusercontent.com'
GOOGLE_OAUTH2_CLIENT_SECRET = 'GOCSPX-xxxxxxxxxxxxx'

FACEBOOK_APP_ID = '1234567890123456'
FACEBOOK_APP_SECRET = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
```

**3. Create Django API Endpoints:**
See `DJANGO_AUTH_COMPLETE_STRUCTURE copy.md` for complete backend implementation.

### Phase 4: Implement Flutter Services

The services are already created but need to be updated with real implementation. I'll create updated versions next.

## 🔄 How It Works

### Google Sign In Flow

1. **User clicks "Sign in with Google"**
2. **Flutter calls `GoogleSignIn().signIn()`**
   - Opens Google account picker
   - Shows permission consent screen
   - Returns `GoogleSignInAccount`

3. **Extract tokens:**
   ```dart
   final authentication = await googleAccount.authentication;
   final idToken = authentication.idToken;  // JWT with user info
   final accessToken = authentication.accessToken;  // API access
   ```

4. **Send to Django backend:**
   ```json
   POST /api/v1/auth/google/
   {
     "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjE...",
     "access_token": "ya29.a0AfH6SMBx..."
   }
   ```

5. **Django validates token:**
   ```python
   from google.oauth2 import id_token
   from google.auth.transport import requests
   
   # Verify the token
   idinfo = id_token.verify_oauth2_token(
       token, 
       requests.Request(), 
       GOOGLE_CLIENT_ID
   )
   
   # Extract user info
   email = idinfo['email']
   name = idinfo['name']
   google_id = idinfo['sub']
   ```

6. **Django creates/finds user:**
   ```python
   tailor, created = Tailor.objects.get_or_create(
       email=email,
       defaults={
           'name': name,
           'auth_provider': 'google',
           'email_verified': True,
       }
   )
   ```

7. **Return JWT tokens:**
   ```json
   {
     "success": true,
     "data": {
       "tailor": {...},
       "tokens": {
         "access": "jwt_access_token",
         "refresh": "jwt_refresh_token"
       },
       "is_new_user": true
     }
   }
   ```

8. **Flutter stores tokens and navigates to home**

### Facebook Sign In Flow

1. **User clicks "Sign in with Facebook"**
2. **Flutter calls `FacebookAuth.instance.login()`**
   - Opens Facebook app or browser
   - Shows permission dialog
   - Returns access token

3. **Get user data:**
   ```dart
   final userData = await FacebookAuth.instance.getUserData();
   // Contains: id, name, email, picture
   ```

4. **Send to Django:**
   ```json
   POST /api/v1/auth/facebook/
   {
     "access_token": "EAABwzLixnjYBOZC...",
     "user_id": "1234567890"
   }
   ```

5. **Django validates token:**
   ```python
   import facebook
   
   graph = facebook.GraphAPI(access_token=access_token)
   profile = graph.get_object('me', fields='id,name,email')
   
   # Verify user_id matches
   if profile['id'] != user_id:
       raise ValidationError('Invalid token')
   ```

6. **Same user creation and JWT return as Google**

## 🎨 UI Implementation

You need to add Google and Facebook buttons to your sign-in screen. I'll show you how next.

## 🧪 Testing Checklist

### Google Sign In
- [ ] Get SHA-1 certificate
- [ ] Configure OAuth consent screen
- [ ] Create Android OAuth client
- [ ] Add SHA-1 to Google Console
- [ ] Update AndroidManifest.xml
- [ ] Test sign-in flow
- [ ] Verify user created in Django
- [ ] Test sign-out
- [ ] Test token refresh

### Facebook Sign In  
- [ ] Create Facebook app
- [ ] Get App ID and Secret
- [ ] Generate key hash
- [ ] Add key hash to Facebook app
- [ ] Update AndroidManifest.xml
- [ ] Create strings.xml with credentials
- [ ] Test sign-in flow
- [ ] Verify user created in Django
- [ ] Test sign-out
- [ ] Request app review for production

## 🚀 Next Steps

1. Get your Google and Facebook credentials (follow Phase 1)
2. Configure Android files (Phase 2)
3. Update Django settings (Phase 3)
4. I'll create the Flutter UI and service implementations (Phase 4)

**Ready to start? Let me know when you have:**
- ✅ Google Web Client ID
- ✅ Facebook App ID  
- ✅ Facebook App Secret

Then I'll create the complete Flutter implementation with UI! 🎉
