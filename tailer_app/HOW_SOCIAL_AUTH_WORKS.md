# 🔐 Social Authentication Flow - Complete Guide

## 📋 Overview

You **already have Google and Facebook buttons** in your Sign-In and Sign-Up screens. This guide explains exactly how they work, step by step, with request/response details.

---

## 🎯 Your Existing Implementation

### **Sign-In Screen**
- **Location:** `lib/features/auth/screens/signin_screen.dart`
- **Buttons:** Already integrated in UI
- **Handlers:** `_handleGoogleSignIn()` and `_handleFacebookSignIn()`

### **Sign-Up Screen**
- **Location:** `lib/features/auth/screens/signup_screen.dart`
- **Widget:** `SignUpGoogleFacebookButton` (reusable component)
- **File:** `lib/features/auth/widgets/AuthGoogleButton.dart`

---

## 🔄 How Social Authentication Works (Complete Flow)

### **Architecture Overview**

```
┌─────────────────┐
│  User Clicks    │
│  Google/FB Btn  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│  1. Flutter App             │
│     SignUpGoogleFacebookBtn │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│  2. Social Auth Service     │
│     (Google/Facebook SDK)   │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│  3. Google/Facebook Servers │
│     (User Login Dialog)     │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│  4. Return: ID Token        │
│     + User Info             │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│  5. Send to Django Backend  │
│     POST /auth/google/      │
│     POST /auth/facebook/    │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│  6. Django Validates Token  │
│     Creates/Gets User       │
│     Returns JWT Token       │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│  7. Save to Local Database  │
│     Store JWT Token         │
│     Navigate to Dashboard   │
└─────────────────────────────┘
```

---

## 📱 Step-by-Step: Google Sign-In

### **Step 1: User Clicks Google Button**

**Location:** `AuthGoogleButton.dart` line 28-32

```dart
socialButton(
  size,
  'assets/google-2.svg',
  'Google',
  onTap: () => _handleGoogleSignIn(context),
),
```

**What happens:** Button click triggers `_handleGoogleSignIn()`

---

### **Step 2: Call Google Auth Service**

**Location:** `AuthGoogleButton.dart` line 48-52

```dart
Future<void> _handleGoogleSignIn(BuildContext context) async {
  try {
    final socialAuth = SocialAuthService();
    final result = await socialAuth.signInWithGoogle();
```

**What happens:** 
- Creates `SocialAuthService` instance
- Calls `signInWithGoogle()` method

---

### **Step 3: Google SDK Authentication**

**Location:** `social_auth_service.dart`

```dart
Future<SocialAuthResult> signInWithGoogle() async {
  try {
    // Call Google auth service
    final result = await _googleAuth.signInWithGoogle();
    
    if (!result.isSuccess) {
      return SocialAuthResult(
        success: false,
        error: result.error ?? 'Google sign in failed',
      );
    }
```

**What happens:**
- Calls `google_auth_simple.dart` → `signInWithGoogle()`
- Opens Google login dialog (native Android UI)
- User selects Google account and grants permissions

**Request to Google Servers:**
```
Platform: Android Native Dialog
User Action: Select account → Grant permissions
Google Response: ID Token + Access Token
```

---

### **Step 4: Get User Info from Google**

**Location:** `google_auth_simple.dart` (when properly implemented)

```dart
final GoogleSignInAccount? account = await _googleSignIn.signIn();
final GoogleSignInAuthentication auth = await account!.authentication;

return GoogleAuthResult(
  id: account.id,
  name: account.displayName,
  email: account.email,
  photoUrl: account.photoUrl,
  idToken: auth.idToken,        // ⭐ This is what we send to Django
  accessToken: auth.accessToken,
  serverAuthCode: auth.serverAuthCode,
);
```

**Response from Google:**
```json
{
  "id": "117234567890123456789",
  "name": "Mukesh Karnan",
  "email": "mukesh@example.com",
  "photoUrl": "https://lh3.googleusercontent.com/...",
  "idToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjU5N...",  // ⭐ JWT Token
  "accessToken": "ya29.a0AfH6SMB...",
  "serverAuthCode": "4/0AY0e-g7..."
}
```

---

### **Step 5: Send to Django Backend**

**Location:** `hybrid_auth_service.dart` → `signInWithGoogle()`

```dart
Future<AuthResult> signInWithGoogle() async {
  try {
    print('🔵 [HybridAuth] Starting Google sign-in...');
    
    // Step 1: Get Google auth result from service
    final googleResult = await _socialAuthService.signInWithGoogle();
    
    if (!googleResult.isSuccess) {
      return AuthResult(success: false, message: googleResult.error);
    }

    // Step 2: Prepare request for Django
    final googleAuthRequest = GoogleAuthRequest(
      idToken: googleResult.idToken!,
      name: googleResult.name,
      email: googleResult.email,
      photoUrl: googleResult.photoUrl,
    );

    print('📤 [HybridAuth] Sending Google auth to backend...');
    
    // Step 3: Send to Django API
    final response = await _accountsApi.googleAuth(googleAuthRequest);
```

**HTTP Request to Django:**
```
POST http://your-django-server.com/api/accounts/auth/google/
Content-Type: application/json

{
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjU5N...",
  "name": "Mukesh Karnan",
  "email": "mukesh@example.com",
  "photo_url": "https://lh3.googleusercontent.com/..."
}
```

---

### **Step 6: Django Backend Processing**

**Django View:** `accounts/views.py`

```python
@api_view(['POST'])
def google_auth(request):
    """
    Handle Google OAuth authentication
    """
    id_token = request.data.get('id_token')
    
    # Step 1: Verify ID Token with Google
    try:
        idinfo = id_token.verify_oauth2_token(
            id_token,
            google.auth.transport.requests.Request(),
            settings.GOOGLE_OAUTH2_CLIENT_ID
        )
        
        # Step 2: Extract user info
        google_user_id = idinfo['sub']
        email = idinfo['email']
        name = idinfo.get('name', '')
        
    except ValueError:
        return Response(
            {'error': 'Invalid Google token'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Step 3: Get or create user
    user, created = User.objects.get_or_create(
        email=email,
        defaults={
            'username': email.split('@')[0],
            'first_name': name.split()[0] if name else '',
            'auth_provider': 'google',
            'is_social_auth': True,
        }
    )
    
    # Step 4: Generate JWT token
    refresh = RefreshToken.for_user(user)
    
    # Step 5: Return response
    return Response({
        'access': str(refresh.access_token),
        'refresh': str(refresh),
        'user': {
            'id': user.id,
            'email': user.email,
            'name': user.get_full_name(),
            'photo_url': request.data.get('photo_url'),
            'auth_provider': 'google',
        }
    })
```

**Response from Django:**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 42,
    "email": "mukesh@example.com",
    "name": "Mukesh Karnan",
    "photo_url": "https://lh3.googleusercontent.com/...",
    "auth_provider": "google"
  }
}
```

---

### **Step 7: Save to Local Database**

**Location:** `hybrid_auth_service.dart` → `_syncSocialAuthUserToLocalDB()`

```dart
Future<void> _syncSocialAuthUserToLocalDB({
  required int userId,
  required String email,
  String? fullName,
  String? phoneNumber,
  String? photoUrl,
  required String provider, // 'google' or 'facebook'
}) async {
  print('💾 [HybridAuth] Syncing social auth user to local DB...');
  
  // Create special password for social auth users
  final specialPassword = 'SOCIAL_AUTH_${provider.toUpperCase()}_$email';
  final hashedPassword = _hashPassword(specialPassword);

  await _tailorRepo.insertOrUpdateTailor(
    id: userId,
    email: email,
    password: hashedPassword,  // Special hash for social users
    fullName: fullName,
    phoneNumber: phoneNumber,
  );

  print('✅ [HybridAuth] Social user synced to local DB');
  print('   Provider: $provider');
  print('   Email: $email');
}
```

**Local SQLite Database:**
```sql
INSERT OR REPLACE INTO tailor (
  id, 
  email, 
  password, 
  full_name, 
  phone_number
) VALUES (
  42,
  'mukesh@example.com',
  '5d41402abc4b2a76b9719d911017c592',  -- SHA256 hash
  'Mukesh Karnan',
  NULL
);
```

**Note:** Password is `SOCIAL_AUTH_GOOGLE_mukesh@example.com` hashed with SHA256

---

### **Step 8: Navigate to Dashboard**

**Location:** `AuthGoogleButton.dart` → `_defaultSuccessHandler()`

```dart
void _defaultSuccessHandler(BuildContext context, SocialAuthResult result) {
  UserFeedbackService.showSuccess(
    context, 
    'Welcome ${result.name}! Signed in successfully.'
  );
  
  // Navigate to dashboard
  Future.delayed(const Duration(milliseconds: 500), () {
    context.goNamed(RouteNames.dashboard);
  });
}
```

**What happens:**
- Shows success message
- Waits 500ms
- Navigates to dashboard screen

---

## 📱 Step-by-Step: Facebook Sign-In

### **Step 1: User Clicks Facebook Button**

Same as Google, but calls `_handleFacebookSignIn()`

---

### **Step 2: Call Facebook Auth Service**

**Location:** `AuthGoogleButton.dart` line 65-69

```dart
Future<void> _handleFacebookSignIn(BuildContext context) async {
  try {
    final socialAuth = SocialAuthService();
    final result = await socialAuth.signInWithFacebook();
```

---

### **Step 3: Facebook SDK Authentication**

**Location:** `facebook_auth_service.dart`

```dart
Future<FacebookAuthResult> signInWithFacebook() async {
  try {
    print('🔵 Starting Facebook authentication...');
    
    // Request Facebook login with permissions
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    if (result.status != LoginStatus.success) {
      print('❌ Facebook login failed: ${result.status}');
      return FacebookAuthResult(
        error: 'Facebook login was cancelled or failed',
      );
    }

    // Get access token
    final AccessToken? accessToken = result.accessToken;
    if (accessToken == null) {
      return FacebookAuthResult(error: 'No access token received');
    }

    print('✅ Facebook login successful, getting user data...');

    // Get user data from Facebook
    final userData = await FacebookAuth.instance.getUserData(
      fields: 'id,name,email,picture.width(200)',
    );
```

**Request to Facebook Servers:**
```
Platform: Android Native Facebook SDK
User Action: Login → Grant permissions (email, profile)
Facebook Response: Access Token + User Data
```

**Response from Facebook:**
```json
{
  "id": "123456789012345",
  "name": "Mukesh Karnan",
  "email": "mukesh@example.com",
  "picture": {
    "data": {
      "url": "https://platform-lookaside.fbsbx.com/..."
    }
  },
  "accessToken": "EAABwzLixnjYBO..."
}
```

---

### **Step 4: Send to Django Backend**

**Location:** `hybrid_auth_service.dart` → `signInWithFacebook()`

```dart
// Prepare request
final facebookAuthRequest = FacebookAuthRequest(
  accessToken: facebookResult.accessToken!,
  userId: facebookResult.id,
  name: facebookResult.name,
  email: facebookResult.email,
  photoUrl: facebookResult.photoUrl,
);

// Send to Django
final response = await _accountsApi.facebookAuth(facebookAuthRequest);
```

**HTTP Request to Django:**
```
POST http://your-django-server.com/api/accounts/auth/facebook/
Content-Type: application/json

{
  "access_token": "EAABwzLixnjYBO...",
  "user_id": "123456789012345",
  "name": "Mukesh Karnan",
  "email": "mukesh@example.com",
  "photo_url": "https://platform-lookaside.fbsbx.com/..."
}
```

---

### **Step 5: Django Backend Processing**

**Django View:** `accounts/views.py`

```python
@api_view(['POST'])
def facebook_auth(request):
    """
    Handle Facebook OAuth authentication
    """
    access_token = request.data.get('access_token')
    
    # Step 1: Verify access token with Facebook
    fb_url = f'https://graph.facebook.com/me?access_token={access_token}&fields=id,name,email'
    fb_response = requests.get(fb_url)
    
    if fb_response.status_code != 200:
        return Response(
            {'error': 'Invalid Facebook token'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    fb_data = fb_response.json()
    
    # Step 2: Extract user info
    facebook_user_id = fb_data.get('id')
    email = fb_data.get('email')
    name = fb_data.get('name', '')
    
    # Step 3: Get or create user
    user, created = User.objects.get_or_create(
        email=email,
        defaults={
            'username': email.split('@')[0],
            'first_name': name.split()[0] if name else '',
            'auth_provider': 'facebook',
            'is_social_auth': True,
        }
    )
    
    # Step 4: Generate JWT token
    refresh = RefreshToken.for_user(user)
    
    # Step 5: Return response
    return Response({
        'access': str(refresh.access_token),
        'refresh': str(refresh),
        'user': {
            'id': user.id,
            'email': user.email,
            'name': user.get_full_name(),
            'photo_url': request.data.get('photo_url'),
            'auth_provider': 'facebook',
        }
    })
```

**Response from Django:** (Same format as Google)

---

## 🔍 Request/Response Summary

### **Google Authentication**

| Step | From → To | Data |
|------|-----------|------|
| 1 | Flutter → Google SDK | Request sign-in |
| 2 | Google SDK → Google Servers | User credentials |
| 3 | Google Servers → Flutter | ID Token + User Info |
| 4 | Flutter → Django | `{id_token, name, email, photo}` |
| 5 | Django → Google API | Verify ID Token |
| 6 | Django → Flutter | `{access_token, refresh_token, user}` |
| 7 | Flutter → SQLite | Save user + JWT token |

### **Facebook Authentication**

| Step | From → To | Data |
|------|-----------|------|
| 1 | Flutter → FB SDK | Request login |
| 2 | FB SDK → Facebook Servers | User credentials |
| 3 | Facebook Servers → Flutter | Access Token + User Data |
| 4 | Flutter → Django | `{access_token, user_id, name, email, photo}` |
| 5 | Django → Facebook API | Verify Access Token |
| 6 | Django → Flutter | `{access_token, refresh_token, user}` |
| 7 | Flutter → SQLite | Save user + JWT token |

---

## 📦 Data Models

### **Google Auth Request (Flutter → Django)**

```dart
class GoogleAuthRequest {
  final String idToken;      // JWT from Google
  final String? name;
  final String? email;
  final String? photoUrl;
}
```

### **Facebook Auth Request (Flutter → Django)**

```dart
class FacebookAuthRequest {
  final String accessToken;  // Token from Facebook
  final String? userId;
  final String? name;
  final String? email;
  final String? photoUrl;
}
```

### **Social Auth Response (Django → Flutter)**

```dart
class SocialAuthResponse {
  final String accessToken;   // JWT for your app
  final String refreshToken;
  final UserData user;
}
```

---

## 🔐 Security Features

### **1. Token Verification**
- **Google:** Django verifies ID Token with Google servers
- **Facebook:** Django verifies Access Token with Facebook Graph API

### **2. Unique Password Hash**
- Social users get special password: `SOCIAL_AUTH_GOOGLE_email@example.com`
- Hashed with SHA256 before storing in SQLite
- Prevents conflicts with regular email/password users

### **3. Provider Tracking**
- Each user has `auth_provider` field: "google" or "facebook"
- Prevents duplicate accounts
- Enables provider-specific logic

---

## ⚙️ Configuration Required

### **Google**
1. Web Client ID in `google_auth_simple.dart`
2. Android Client ID in Google Console (auto-detected)
3. SHA-1 certificate from `./gradlew signingReport`
4. Web Client ID in Django `settings.py`

### **Facebook**
1. App ID in `strings.xml`
2. Client Token in `strings.xml`
3. Key Hash from keytool command
4. App ID + Secret in Django `settings.py`

---

## ✅ Current Status

**Your Code:**
- ✅ Buttons already exist in Sign-In screen
- ✅ Buttons already exist in Sign-Up screen
- ✅ Widget component created (`AuthGoogleButton.dart`)
- ✅ All services implemented
- ✅ All API calls ready
- ✅ Django integration ready

**What's Missing:**
- ⏳ Google Web Client ID (need to create in console)
- ⏳ Facebook App ID + Client Token (need to create app)
- ⏳ Update configuration files with credentials

---

## 🎯 Next Steps

1. **Get Google Credentials** (follow `GOOGLE_CLIENT_ID_SETUP.md`)
2. **Get Facebook Credentials** (follow `CREDENTIALS_CONFIG.md`)
3. **Update Configuration Files**
4. **Test the existing buttons** - They're already wired up!

---

**Your buttons are ready to use!** Just need the credentials to make them work. 🚀
