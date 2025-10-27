# Social Authentication - Quick Implementation Guide

## 🎯 What You Get

After implementation, your users can:
- ✅ Sign up with Google (one click)
- ✅ Sign up with Facebook (one click)
- ✅ Sign in with Google (automatic)
- ✅ Sign in with Facebook (automatic)
- ✅ No password needed
- ✅ Email verified automatically
- ✅ Profile picture from social account

## 📱 UI Preview

```
┌─────────────────────────────────────┐
│         Tailor App Sign In          │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  Email                        │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  Password                     │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │       Sign In                 │ │
│  └───────────────────────────────┘ │
│                                     │
│        ─────── OR ───────           │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  🔵 Continue with Google      │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  💙 Continue with Facebook    │ │
│  └───────────────────────────────┘ │
│                                     │
│     Don't have an account? Sign Up  │
└─────────────────────────────────────┘
```

## ⚡ Quick Start (30 Minutes)

### Step 1: Get Credentials (15 min)

#### Google:
1. Go to: https://console.cloud.google.com/
2. Create project: "Tailor App"
3. Enable "Google+ API"
4. Create OAuth credentials → Android
5. Get SHA-1: `cd android && ./gradlew signingReport`
6. Copy Android Client ID

#### Facebook:
1. Go to: https://developers.facebook.com/
2. Create App → "Tailor App"
3. Settings → Basic → Copy App ID
4. Add Product → Facebook Login
5. Configure Android platform
6. Get Key Hash:
   ```bash
   keytool -exportcert -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore | openssl sha1 -binary | openssl base64
   ```
   Password: `android`

### Step 2: Configure Android (5 min)

**File: `android/app/src/main/res/values/strings.xml`** (CREATE THIS)
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Tailor App</string>
    <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
    <string name="facebook_client_token">YOUR_FACEBOOK_CLIENT_TOKEN</string>
    <string name="fb_login_protocol_scheme">fbYOUR_FACEBOOK_APP_ID</string>
</resources>
```

**File: `android/app/src/main/AndroidManifest.xml`** (ADD THIS)
```xml
<application>
    <!-- Add inside <application> tag -->
    <meta-data 
        android:name="com.facebook.sdk.ApplicationId" 
        android:value="@string/facebook_app_id"/>
    
    <meta-data 
        android:name="com.facebook.sdk.ClientToken" 
        android:value="@string/facebook_client_token"/>
</application>
```

### Step 3: Configure Django (5 min)

**File: `settings.py`**
```python
# Add these settings
GOOGLE_OAUTH2_CLIENT_ID = 'your-web-client-id.apps.googleusercontent.com'
FACEBOOK_APP_ID = 'your-facebook-app-id'
FACEBOOK_APP_SECRET = 'your-facebook-secret'
```

### Step 4: Test It (5 min)

1. Run your Flutter app
2. Click "Continue with Google"
3. Select Gmail account
4. Should see home screen
5. Check Django admin - user created!

## 🔧 What Happens Behind the Scenes

### Google Sign In (5-10 seconds)

```
User clicks button
    ↓
Google account picker opens
    ↓
User selects account
    ↓
Permission screen (first time only)
    ↓
App receives tokens
    ↓
Send to Django /auth/google/
    ↓
Django verifies token
    ↓
Django creates/finds user
    ↓
Returns JWT tokens
    ↓
User is signed in!
```

### What Django Does

```python
# 1. Receives request
POST /api/v1/auth/google/
{
  "id_token": "eyJhbGciOiJ...",
  "access_token": "ya29.a0AfH6..."
}

# 2. Validates token with Google
idinfo = id_token.verify_oauth2_token(token, ...)

# 3. Extracts user info
email = idinfo['email']        # user@gmail.com
name = idinfo['name']          # John Doe
google_id = idinfo['sub']      # 1234567890

# 4. Creates or finds user
tailor = Tailor.objects.get_or_create(
    email=email,
    defaults={
        'name': name,
        'auth_provider': 'google',
        'email_verified': True,
    }
)

# 5. Returns JWT
return {
    'tailor': {...},
    'tokens': {
        'access': jwt_token,
        'refresh': refresh_token
    }
}
```

### What Flutter Does

```dart
// 1. User clicks button
onPressed: () async {
  await _handleGoogleSignIn();
}

// 2. Open Google Sign In
final GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
);
final account = await googleSignIn.signIn();

// 3. Get tokens
final auth = await account.authentication;
final idToken = auth.idToken;
final accessToken = auth.accessToken;

// 4. Send to backend
final response = await api.post('/auth/google/', {
  'id_token': idToken,
  'access_token': accessToken,
});

// 5. Save JWT tokens locally
await secureStorage.write('access_token', response.tokens.access);
await secureStorage.write('refresh_token', response.tokens.refresh);

// 6. Navigate to home
context.goNamed(RouteNames.home);
```

## 📊 Database Changes

### New User from Google

```sql
INSERT INTO tailor (
    id,              -- 'MAT' + random
    unique_id,       -- Same as id
    name,            -- From Google profile
    email,           -- From Google account
    auth_provider,   -- 'google'
    email_verified,  -- true (Google already verified)
    profile_image_path, -- From Google avatar
    is_active,       -- true
    created_at,      -- NOW()
) VALUES (...);
```

### Existing User Sign In

```sql
-- Just finds existing user by email
SELECT * FROM tailor 
WHERE email = 'user@gmail.com' 
AND auth_provider = 'google';
```

## ⚠️ Common Issues & Solutions

### Issue 1: "Developer Error" (Google)
**Problem:** Wrong SHA-1 certificate
**Solution:**
```bash
cd android
./gradlew signingReport
# Copy SHA1 from Variant: debug
# Add to Google Console OAuth client
```

### Issue 2: "App Not Setup" (Facebook)
**Problem:** Missing strings.xml or wrong App ID
**Solution:**
```xml
<!-- Check android/app/src/main/res/values/strings.xml -->
<string name="facebook_app_id">1234567890123456</string>
<!-- Must match Facebook Developer Console -->
```

### Issue 3: "Invalid Client" (Google)
**Problem:** Using wrong Client ID
**Solution:**
- Android app needs: Android Client ID
- Django backend needs: Web Client ID
- Don't mix them up!

### Issue 4: "Token Validation Failed" (Django)
**Problem:** Django can't verify token
**Solution:**
```python
# In settings.py, use WEB client ID (not Android)
GOOGLE_OAUTH2_CLIENT_ID = 'xxx-yyy.apps.googleusercontent.com'
```

### Issue 5: Missing Email (Facebook)
**Problem:** User didn't grant email permission
**Solution:**
```dart
// Request email explicitly
final result = await FacebookAuth.instance.login(
  permissions: ['email', 'public_profile'],
);

// Check if email was granted
if (userData['email'] == null) {
  // Show error: "Email permission required"
}
```

## 🧪 Testing Checklist

### Before Testing
- [ ] Google Client ID configured
- [ ] Facebook App ID configured
- [ ] SHA-1 added to Google Console
- [ ] Key Hash added to Facebook Console
- [ ] strings.xml created with credentials
- [ ] AndroidManifest.xml updated
- [ ] Django settings.py updated

### Test Cases
- [ ] Google sign in (new user)
- [ ] Google sign in (existing user)
- [ ] Facebook sign in (new user)
- [ ] Facebook sign in (existing user)
- [ ] User cancels Google sign in
- [ ] User cancels Facebook sign in
- [ ] Network error during sign in
- [ ] Sign out
- [ ] Sign in again after sign out

### Verify
- [ ] User created in Django database
- [ ] Email matches Google/Facebook email
- [ ] Profile image downloaded
- [ ] JWT tokens stored locally
- [ ] Navigation to home screen works
- [ ] User can access protected routes

## 🎨 UI Customization

### Button Colors

**Google Blue:** `#4285F4`
**Facebook Blue:** `#1877F2`

### Button Text

**Options:**
- "Continue with Google" (recommended)
- "Sign in with Google"
- "Sign up with Google"
- "Login with Google"

### Icons

Use official brand assets:
- Google: https://developers.google.com/identity/branding-guidelines
- Facebook: https://developers.facebook.com/docs/facebook-login/userexperience

## 📈 Success Metrics

After implementation, you should see:
- ✅ 50-70% of users choose social sign in
- ✅ 90% faster sign up (no form filling)
- ✅ Higher email verification rate
- ✅ Better user experience
- ✅ Fewer password reset requests

## 🚀 Ready to Implement?

I have:
1. ✅ Complete setup guide (SOCIAL_AUTH_SETUP_GUIDE.md)
2. ✅ This quick start guide
3. ⏳ Need to create Flutter UI implementation
4. ⏳ Need to update services with real code

**Next: Give me your credentials and I'll complete the Flutter implementation!**

What you need:
- Google Web Client ID (for Django)
- Facebook App ID
- Facebook App Secret

Then I'll create the complete working implementation! 🎉
