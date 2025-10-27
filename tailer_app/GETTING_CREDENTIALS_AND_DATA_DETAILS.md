# 🔐 Getting Google & Facebook Credentials + Data Details

## 🎯 Part 1: Get Google Credentials

### Step 1: Go to Google Cloud Console

1. **Open:** https://console.cloud.google.com/
2. **Sign in** with your Google account
3. **Select or create project:** "exchange-maatrax" (you already have this!)

---

### Step 2: Enable Google+ API

1. **Go to:** https://console.cloud.google.com/apis/library?project=exchange-maatrax
2. **Search for:** "Google+ API" or "People API"
3. **Click:** Enable
4. **Wait:** ~30 seconds for activation

**Why:** This API is required for Google Sign-In to work

---

### Step 3: Get SHA-1 Certificate (Required for Android)

Open PowerShell in your project:

```powershell
cd C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app\android
./gradlew signingReport
```

**Output will look like:**
```
Variant: debug
Config: debug
Store: C:\Users\mukes\.android\debug.keystore
Alias: AndroidDebugKey
MD5: 3F:4A:7B:2C:1D:9E:...
SHA1: A1:B2:C3:D4:E5:F6:11:22:33:44:55:66:77:88:99:00:AA:BB:CC:DD
SHA-256: 5D:6E:7F:...
```

**Copy the entire SHA1 line** (the one with colons, like `A1:B2:C3:...`)

---

### Step 4: Create Android Client ID

1. **Go to:** https://console.cloud.google.com/apis/credentials?project=exchange-maatrax
2. **Click:** "+ CREATE CREDENTIALS" → "OAuth client ID"
3. **Application type:** Select "Android"
4. **Fill in:**
   - **Name:** `Tailor App Android`
   - **Package name:** `com.example.tailer_app`
   - **SHA-1 certificate fingerprint:** Paste the SHA1 from Step 3
5. **Click:** "CREATE"

**You'll see:**
```
Your client ID: 881979011144-xxxxxxxxxxxxxxxxx.apps.googleusercontent.com
```

**Note:** You don't need to manually use this - it's auto-detected by Android!

---

### Step 5: Create Web Client ID (Most Important!)

1. **Still on credentials page**
2. **Click:** "+ CREATE CREDENTIALS" → "OAuth client ID"
3. **Application type:** Select "Web application"
4. **Fill in:**
   - **Name:** `Tailor App Backend`
   - **Authorized JavaScript origins:** (Leave empty for now)
   - **Authorized redirect URIs:** (Leave empty for now)
5. **Click:** "CREATE"

**You'll see a popup with:**
```
Your Client ID
881979011144-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com

Your Client Secret
GOCSPX-abcdefghijklmnopqrstuvwx
```

**⭐ IMPORTANT: Copy the Client ID** (the long one ending in `.apps.googleusercontent.com`)

---

### Step 6: Add Web Client ID to Flutter

Open: `lib/data/services/google_auth_simple.dart`

**Find line 6:**
```dart
const String GOOGLE_WEB_CLIENT_ID = 'YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com';
```

**Replace with your actual Web Client ID:**
```dart
const String GOOGLE_WEB_CLIENT_ID = '881979011144-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com';
```

**Save the file!**

---

## 📱 Part 2: Get Facebook Credentials

### Step 1: Create Facebook App

1. **Go to:** https://developers.facebook.com/apps
2. **Click:** "Create App"
3. **Select:** "Business" (or "Consumer" if you prefer)
4. **Click:** "Next"

---

### Step 2: Fill App Details

1. **App Name:** `Tailor App`
2. **App Contact Email:** Your email (e.g., mukesh@example.com)
3. **Business Account:** (Optional - you can skip)
4. **Click:** "Create App"

---

### Step 3: Add Facebook Login

1. **You'll see dashboard with products**
2. **Find:** "Facebook Login"
3. **Click:** "Set Up"
4. **Select:** "Android"
5. **Click:** "Next"

---

### Step 4: Get App ID and Client Token

1. **On left sidebar, click:** "Settings" → "Basic"
2. **You'll see:**

```
App ID: 1234567890123456
App Secret: [Click "Show" to see]
```

3. **Click "Show"** on App Secret (you'll need to enter your Facebook password)
4. **Copy both:**
   - App ID: `1234567890123456`
   - App Secret: `abc123def456ghi789jkl012mno345pq`

---

### Step 5: Generate Key Hash

Open PowerShell and run:

```powershell
# For Windows with OpenSSL installed
$env:Path = "C:\Program Files\Git\usr\bin;$env:Path"
keytool -exportcert -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" | openssl sha1 -binary | openssl base64
```

**Password:** `android` (when prompted)

**You'll get output like:**
```
lWgFPq3YhbTGPVXhBLbL2bQbD0k=
```

**Copy this** - this is your Key Hash!

**Alternative if above doesn't work:**
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

---

### Step 6: Configure Facebook Android Platform

1. **In Facebook Dashboard, click:** "Settings" → "Basic"
2. **Scroll down to:** "Add Platform"
3. **Click:** "Android"
4. **Fill in:**
   - **Package Name:** `com.example.tailer_app`
   - **Default Activity Class Name:** `com.example.tailer_app.MainActivity`
   - **Key Hashes:** Paste the hash from Step 5
5. **Enable:** "Single Sign On" (toggle ON)
6. **Click:** "Save Changes"

---

### Step 7: Add Facebook Credentials to Flutter

**File:** `android/app/src/main/res/values/strings.xml`

**Replace the template with actual values:**

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Facebook Configuration -->
    <string name="facebook_app_id">1234567890123456</string>
    <string name="facebook_client_token">abc123def456ghi789jkl012mno345pq</string>
    <string name="fb_login_protocol_scheme">fb1234567890123456</string>
</resources>
```

**Note:** 
- `facebook_app_id` = Your App ID
- `facebook_client_token` = Your App Secret
- `fb_login_protocol_scheme` = "fb" + Your App ID

**Save the file!**

---

## 📊 Part 3: What Data Google & Facebook Return

### 🔴 Google Sign-In Returns:

When user signs in with Google, you get this data:

```json
{
  // User Identification
  "id": "117234567890123456789",
  
  // Basic Profile Info
  "email": "mukesh.karnan@gmail.com",
  "name": "Mukesh Karnan",
  "givenName": "Mukesh",
  "familyName": "Karnan",
  
  // Profile Picture
  "photoUrl": "https://lh3.googleusercontent.com/a/ACg8ocKxyz123...",
  
  // Authentication Tokens
  "idToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjU5Nz...",  // JWT Token for backend
  "accessToken": "ya29.a0AfH6SMBCxyz123...",          // For Google API calls
  "serverAuthCode": "4/0AY0e-g7Rxyz123...",           // For server-side auth
  
  // Token Details
  "expirationTime": 1729354800000,  // Unix timestamp
  
  // Verification Status
  "isVerifiedEmail": true
}
```

**Decoded ID Token contains:**
```json
{
  "iss": "https://accounts.google.com",
  "sub": "117234567890123456789",
  "email": "mukesh.karnan@gmail.com",
  "email_verified": true,
  "name": "Mukesh Karnan",
  "picture": "https://lh3.googleusercontent.com/...",
  "given_name": "Mukesh",
  "family_name": "Karnan",
  "locale": "en",
  "iat": 1729351200,
  "exp": 1729354800
}
```

**What you use:**
- ✅ `email` - User's email address
- ✅ `name` - Full name
- ✅ `photoUrl` - Profile picture URL
- ✅ `idToken` - Send this to Django backend for verification
- ⚠️ `accessToken` - Only if you need to access Google APIs
- ⚠️ `serverAuthCode` - For offline access (rarely needed)

---

### 🔵 Facebook Login Returns:

When user logs in with Facebook, you get this data:

```json
{
  // User Identification
  "id": "123456789012345",
  
  // Basic Profile Info
  "email": "mukesh.karnan@gmail.com",
  "name": "Mukesh Karnan",
  "first_name": "Mukesh",
  "last_name": "Karnan",
  
  // Profile Picture
  "picture": {
    "data": {
      "height": 200,
      "width": 200,
      "url": "https://platform-lookaside.fbsbx.com/platform/profilepic/?asid=123456789012345&height=200&width=200"
    }
  },
  
  // Authentication Token
  "accessToken": "EAABwzLixnjYBO1234567890abcdefghijklmnop...",
  
  // Token Details
  "userId": "123456789012345",
  "expiresIn": 5183944,  // Seconds until expiration
  "dataAccessExpirationTime": 1736547600,  // Unix timestamp
  "isExpired": false,
  
  // Permissions Granted
  "grantedPermissions": ["email", "public_profile"],
  "declinedPermissions": [],
  
  // Account Type
  "graphDomain": "facebook"
}
```

**What you use:**
- ✅ `id` - Facebook user ID
- ✅ `email` - User's email address
- ✅ `name` - Full name
- ✅ `picture.data.url` - Profile picture URL
- ✅ `accessToken` - Send this to Django backend for verification

---

## 🔍 Part 4: Real-World Examples

### Example 1: Google Response (Real Data)

```dart
GoogleAuthResult(
  id: "117234567890123456789",
  name: "Mukesh Karnan",
  email: "mukesh@example.com",
  photoUrl: "https://lh3.googleusercontent.com/a/ACg8ocKxyz...",
  idToken: "eyJhbGciOiJSUzI1NiIsImtpZCI6IjU5NzYwMjgzMDQ4YTkyN...",
  accessToken: null,  // May be null if not requested
  serverAuthCode: null,  // May be null if not configured
  error: null,
)
```

### Example 2: Facebook Response (Real Data)

```dart
FacebookAuthResult(
  id: "123456789012345",
  name: "Mukesh Karnan",
  email: "mukesh@example.com",
  photoUrl: "https://platform-lookaside.fbsbx.com/platform/profilepic/?asid=123456789012345",
  accessToken: "EAABwzLixnjYBO1234567890...",
  error: null,
)
```

---

## 📤 Part 5: What Gets Sent to Django

### Google Auth Request:

```json
POST /api/accounts/auth/google/
Content-Type: application/json

{
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjU5NzYwMjgzMDQ4YTkyN...",
  "name": "Mukesh Karnan",
  "email": "mukesh@example.com",
  "photo_url": "https://lh3.googleusercontent.com/a/ACg8ocKxyz..."
}
```

### Facebook Auth Request:

```json
POST /api/accounts/auth/facebook/
Content-Type: application/json

{
  "access_token": "EAABwzLixnjYBO1234567890...",
  "user_id": "123456789012345",
  "name": "Mukesh Karnan",
  "email": "mukesh@example.com",
  "photo_url": "https://platform-lookaside.fbsbx.com/platform/profilepic/?asid=123456789012345"
}
```

---

## 📥 Part 6: What Django Returns

### Success Response (Both Google & Facebook):

```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",  // JWT for your app
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",  // Refresh token
  "user": {
    "id": 42,
    "email": "mukesh@example.com",
    "name": "Mukesh Karnan",
    "username": "mukesh",
    "first_name": "Mukesh",
    "last_name": "Karnan",
    "phone_number": null,
    "photo_url": "https://lh3.googleusercontent.com/...",
    "auth_provider": "google",  // or "facebook"
    "is_social_auth": true,
    "date_joined": "2025-10-19T10:30:00Z",
    "last_login": "2025-10-19T10:30:00Z"
  }
}
```

---

## 🗄️ Part 7: What Gets Saved in Local Database

### SQLite (tailor table):

```sql
INSERT INTO tailor (
  id, 
  email, 
  password, 
  full_name, 
  phone_number
) VALUES (
  42,
  'mukesh@example.com',
  'e5f3a2b8c9d1...',  -- SHA256 hash of 'SOCIAL_AUTH_GOOGLE_mukesh@example.com'
  'Mukesh Karnan',
  NULL
);
```

### Secure Storage (auth_token):

```
Key: auth_token
Value: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

---

## 🔐 Part 8: Privacy & Security

### What Google CAN Access:
- ✅ Basic profile (name, email, photo)
- ✅ Email verification status
- ❌ Cannot access your app data
- ❌ Cannot access other user data
- ❌ Cannot modify anything

### What Facebook CAN Access:
- ✅ Basic profile (name, email, photo)
- ✅ Public profile information
- ❌ Cannot access your app data
- ❌ Cannot post on behalf of user
- ❌ Cannot access friends list (unless requested)

### What Gets Stored:
- ✅ Email address
- ✅ Name
- ✅ Photo URL (link, not actual image)
- ✅ Provider (google/facebook)
- ✅ JWT token (encrypted in SecureStorage)
- ❌ NO password stored for social users
- ❌ NO access tokens stored permanently

---

## 🧪 Part 9: Testing the Data

### Test Google Sign-In:

1. **Add Web Client ID** to `google_auth_simple.dart`
2. **Run:**
   ```bash
   flutter run
   ```
3. **Click Google button**
4. **Check console output:**
   ```
   🔵 Starting Google sign in flow...
   ✅ Google sign in successful
   📤 Sending Google auth to backend...
   {
     "id": "117234567890123456789",
     "name": "Mukesh Karnan",
     "email": "mukesh@example.com",
     "photoUrl": "https://...",
     "idToken": "eyJhbGci..."
   }
   ```

### Test Facebook Login:

1. **Add credentials** to `strings.xml`
2. **Run:**
   ```bash
   flutter run
   ```
3. **Click Facebook button**
4. **Check console output:**
   ```
   🔵 Starting Facebook authentication...
   ✅ Facebook login successful, getting user data...
   {
     "id": "123456789012345",
     "name": "Mukesh Karnan",
     "email": "mukesh@example.com",
     "picture": {...},
     "accessToken": "EAABwzLi..."
   }
   ```

---

## 📋 Quick Checklist

### Google Setup:
- [ ] Enable Google+ API in Cloud Console
- [ ] Get SHA-1 from `./gradlew signingReport`
- [ ] Create Android Client ID
- [ ] Create Web Client ID
- [ ] Add Web Client ID to `google_auth_simple.dart` line 6

### Facebook Setup:
- [ ] Create Facebook App
- [ ] Add Facebook Login product
- [ ] Get App ID and App Secret
- [ ] Generate Key Hash
- [ ] Add Android platform with package name
- [ ] Update `strings.xml` with credentials

### Testing:
- [ ] Run `flutter clean && flutter pub get`
- [ ] Run `flutter run`
- [ ] Test Google button
- [ ] Test Facebook button
- [ ] Check console for returned data
- [ ] Verify navigation to dashboard

---

## 🎯 Summary

### What You Get from Google:
- Email ✅
- Name ✅
- Photo URL ✅
- ID Token (for verification) ✅
- Google User ID ✅

### What You Get from Facebook:
- Email ✅
- Name ✅
- Photo URL ✅
- Access Token (for verification) ✅
- Facebook User ID ✅

### What Django Does:
- Verifies token with Google/Facebook API ✅
- Creates or gets existing user ✅
- Generates JWT token for your app ✅
- Returns user data + JWT ✅

### What Flutter Does:
- Saves JWT to SecureStorage ✅
- Saves user to local SQLite database ✅
- Navigates to dashboard ✅

---

**Ready to get started?** Follow the steps above and you'll have social authentication working in ~30 minutes! 🚀
