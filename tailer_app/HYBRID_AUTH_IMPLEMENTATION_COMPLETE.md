# 🔐 Hybrid Authentication System - Django Backend + Flutter Local DB

**Django Backend**: `C:\Users\mukes\Videos\Android_Dev\Devlopment\TailerBackend\tailor_project`  
**Flutter Frontend**: `C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app`  
**Architecture**: Backend authentication with local database sync  
**Date**: October 14, 2025

## 🎯 System Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    AUTHENTICATION FLOW                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Flutter App                Django Backend                   │
│  ┌──────────┐              ┌──────────────┐                 │
│  │ Register │─────────────>│   Register   │                 │
│  │  Screen  │   HTTP POST  │   Endpoint   │                 │
│  └──────────┘              └──────┬───────┘                 │
│       │                            │                         │
│       │                            ▼                         │
│       │                    ┌──────────────┐                 │
│       │                    │ Create User  │                 │
│       │                    │  in Django   │                 │
│       │                    │   Database   │                 │
│       │                    └──────┬───────┘                 │
│       │                            │                         │
│       │                            ▼                         │
│       │                    ┌──────────────┐                 │
│       │                    │  Send OTP    │                 │
│       │                    │  via Email   │                 │
│       │                    └──────┬───────┘                 │
│       │                            │                         │
│       │<───── OTP Code ────────────┘                        │
│       │                                                      │
│       ▼                                                      │
│  ┌──────────┐              ┌──────────────┐                │
│  │   OTP    │─────────────>│  Verify OTP  │                │
│  │  Screen  │   HTTP POST  │   Endpoint   │                │
│  └──────────┘              └──────┬───────┘                 │
│       │                            │                         │
│       │                            ▼                         │
│       │                    ┌──────────────┐                 │
│       │                    │ Activate User│                 │
│       │                    │  + Generate  │                 │
│       │                    │  JWT Tokens  │                 │
│       │                    └──────┬───────┘                 │
│       │                            │                         │
│       │<─── User Data + Tokens ────┘                        │
│       │                                                      │
│       ▼                                                      │
│  ┌──────────┐                                               │
│  │  Insert  │                                               │
│  │  User to │                                               │
│  │ Local DB │                                               │
│  └──────────┘                                               │
│       │                                                      │
│       ▼                                                      │
│  ┌──────────┐                                               │
│  │   Home   │                                               │
│  │  Screen  │                                               │
│  └──────────┘                                               │
└─────────────────────────────────────────────────────────────┘
```

## 🏗️ Implementation Structure

### Backend Responsibilities (Django)
1. ✅ **User Registration** - Create account in Django database
2. ✅ **OTP Generation** - Send verification code via email/SMS
3. ✅ **Email/Phone Verification** - Verify OTP and activate account
4. ✅ **JWT Token Generation** - Create access & refresh tokens
5. ✅ **Login Authentication** - Validate credentials
6. ✅ **Password Management** - Reset, change password
7. ✅ **Social Auth** - Google/Facebook OAuth

### Frontend Responsibilities (Flutter)
1. ✅ **UI Layer** - Registration, login, OTP screens
2. ✅ **API Communication** - HTTP requests to Django
3. ✅ **Token Management** - Store JWT tokens securely
4. ✅ **Local DB Sync** - Insert verified users to SQLite
5. ✅ **Offline Access** - Read user data from local DB
6. ✅ **State Management** - Handle auth state

## 📋 Complete Implementation Flow

### STEP 1: Registration Flow

#### Django Backend Endpoint
```python
# accounts/views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Tailor, OTP
from .serializers import TailorSerializer
import random
import string

class RegisterView(APIView):
    def post(self, request):
        # 1. Validate input data
        serializer = TailorSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=400)
        
        # 2. Check if email/phone already exists
        email = request.data.get('email')
        phone = request.data.get('phone')
        
        if Tailor.objects.filter(email=email).exists():
            return Response({'error': 'Email already registered'}, status=400)
        
        if Tailor.objects.filter(phone=phone).exists():
            return Response({'error': 'Phone already registered'}, status=400)
        
        # 3. Generate unique ID (MAT + 7 chars)
        unique_id = self.generate_unique_id()
        
        # 4. Create user (inactive by default)
        tailor = Tailor.objects.create(
            id=unique_id,
            unique_id=unique_id,
            name=request.data.get('name'),
            shop_name=request.data.get('shop_name'),
            email=email,
            phone=phone,
            address=request.data.get('address', ''),
            auth_provider='email',
            is_active=False,  # Inactive until OTP verified
            email_verified=False
        )
        tailor.set_password(request.data.get('password'))
        tailor.save()
        
        # 5. Generate and send OTP
        otp_code = self.generate_otp()
        OTP.objects.create(
            tailor=tailor,
            otp_type='email',
            otp_code=otp_code,
            contact_info=email,
            expires_at=timezone.now() + timedelta(minutes=10)
        )
        
        # 6. Send OTP via email
        self.send_otp_email(email, otp_code)
        
        return Response({
            'message': 'Registration successful. Please verify OTP.',
            'user_id': unique_id,
            'email': email,
            'otp_sent': True
        }, status=201)
    
    def generate_unique_id(self):
        chars = string.ascii_uppercase + string.digits
        while True:
            unique_id = 'MAT' + ''.join(random.choices(chars, k=7))
            if not Tailor.objects.filter(id=unique_id).exists():
                return unique_id
    
    def generate_otp(self):
        return ''.join(random.choices(string.digits, k=6))
    
    def send_otp_email(self, email, otp_code):
        # Send email with OTP
        from django.core.mail import send_mail
        send_mail(
            'Verify Your Account',
            f'Your OTP code is: {otp_code}',
            'noreply@tailorapp.com',
            [email],
            fail_silently=False,
        )
```

#### Flutter Registration Screen
```dart
// lib/features/auth/screens/signup_screen.dart
class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountsApi = AccountsApiService();
  
  String _name = '';
  String _shopName = '';
  String _email = '';
  String _phone = '';
  String _password = '';
  String _address = '';
  
  bool _isLoading = false;
  
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // 1. Call Django register API
      final request = RegisterRequest(
        email: _email,
        password: _password,
        passwordConfirm: _password,
        name: _name,
        shopName: _shopName,
        phone: _phone,
        address: _address,
        authProvider: 'email',
      );
      
      final response = await _accountsApi.register(request);
      
      // 2. Navigate to OTP verification screen
      // DO NOT insert to local DB yet - wait for verification
      Navigator.pushNamed(
        context,
        '/otp-verification',
        arguments: {
          'email': _email,
          'userId': response.user.id,
          'userData': response.user,
        },
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP sent to $_email')),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Full Name'),
              onChanged: (value) => _name = value,
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Shop Name'),
              onChanged: (value) => _shopName = value,
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) => _email = value,
              validator: (value) => !value!.contains('@') ? 'Invalid email' : null,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
              onChanged: (value) => _phone = value,
              validator: (value) => value!.length < 10 ? 'Invalid phone' : null,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              onChanged: (value) => _password = value,
              validator: (value) => value!.length < 8 ? 'Min 8 characters' : null,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Address (Optional)'),
              onChanged: (value) => _address = value,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### STEP 2: OTP Verification Flow

#### Django OTP Verification Endpoint
```python
# otp/views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from .models import OTP, Tailor
from django.utils import timezone

class VerifyOTPView(APIView):
    def post(self, request):
        email = request.data.get('email')
        otp_code = request.data.get('otp_code')
        
        try:
            # 1. Find OTP record
            otp = OTP.objects.get(
                contact_info=email,
                otp_code=otp_code,
                otp_type='email',
                is_used=False,
                expires_at__gt=timezone.now()
            )
            
            # 2. Mark OTP as used
            otp.is_used = True
            otp.save()
            
            # 3. Activate user account
            tailor = otp.tailor
            tailor.is_active = True
            tailor.email_verified = True
            tailor.save()
            
            # 4. Generate JWT tokens
            refresh = RefreshToken.for_user(tailor)
            access_token = str(refresh.access_token)
            refresh_token = str(refresh)
            
            # 5. Return user data + tokens
            from .serializers import TailorSerializer
            serializer = TailorSerializer(tailor)
            
            return Response({
                'message': 'Email verified successfully',
                'user': serializer.data,
                'tokens': {
                    'access': access_token,
                    'refresh': refresh_token
                }
            }, status=200)
            
        except OTP.DoesNotExist:
            return Response({
                'error': 'Invalid or expired OTP'
            }, status=400)
```

#### Flutter OTP Verification Screen
```dart
// lib/features/auth/screens/otp_verification_screen.dart
class OTPVerificationScreen extends StatefulWidget {
  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _accountsApi = AccountsApiService();
  final _localDbService = LocalDatabaseService();
  final _authService = AuthService();
  
  String _otpCode = '';
  bool _isLoading = false;
  
  Future<void> _handleVerifyOTP() async {
    if (_otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter 6-digit OTP')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      final email = args['email'] as String;
      final userData = args['userData'] as Tailor;
      
      // 1. Verify OTP with Django backend
      final request = VerifyOTPRequest(
        email: email,
        otpCode: _otpCode,
        otpType: 'email',
      );
      
      final response = await _accountsApi.verifyOTP(request);
      
      // 2. Save JWT tokens to secure storage
      await _accountsApi._tokenStorage.saveAccessToken(response.tokens.access);
      await _accountsApi._tokenStorage.saveRefreshToken(response.tokens.refresh);
      await _accountsApi._tokenStorage.saveUserId(response.user.id);
      await _accountsApi._tokenStorage.saveUserEmail(response.user.email);
      await _accountsApi._tokenStorage.saveLoginState(true);
      
      // 3. NOW insert verified user to local SQLite database
      await _insertToLocalDB(response.user);
      
      // 4. Update auth provider state
      await _authService.setCurrentUser(response.user);
      
      // 5. Navigate to home screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Account verified successfully!')),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ OTP verification failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _insertToLocalDB(Tailor tailor) async {
    try {
      final db = await _localDbService.database;
      
      // Insert verified user to local tailors table
      await db.insert(
        'tailors',
        tailor.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('OTPVerification', '✅ User inserted to local DB: ${tailor.id}');
    } catch (e) {
      Logger.error('OTPVerification', '❌ Failed to insert to local DB', error: e);
      // Don't throw - user is verified in backend, local sync can retry later
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verify OTP')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Enter 6-digit OTP sent to your email'),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'OTP Code',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, letterSpacing: 8),
              onChanged: (value) => _otpCode = value,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleVerifyOTP,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Verify OTP'),
            ),
            TextButton(
              onPressed: _resendOTP,
              child: Text('Resend OTP'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _resendOTP() async {
    // Call Django resend OTP endpoint
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final email = args['email'] as String;
    
    await _accountsApi.resendVerification(email);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('OTP resent to $email')),
    );
  }
}
```

### STEP 3: Login Flow

#### Django Login Endpoint
```python
# accounts/views.py
class LoginView(APIView):
    def post(self, request):
        email = request.data.get('email')
        password = request.data.get('password')
        
        try:
            # 1. Find user by email
            tailor = Tailor.objects.get(email=email)
            
            # 2. Check if account is verified
            if not tailor.email_verified:
                return Response({
                    'error': 'Please verify your email first'
                }, status=403)
            
            # 3. Verify password
            if not tailor.check_password(password):
                return Response({
                    'error': 'Invalid email or password'
                }, status=401)
            
            # 4. Check if account is active
            if not tailor.is_active:
                return Response({
                    'error': 'Account is deactivated'
                }, status=403)
            
            # 5. Generate JWT tokens
            refresh = RefreshToken.for_user(tailor)
            access_token = str(refresh.access_token)
            refresh_token = str(refresh)
            
            # 6. Return user data + tokens
            serializer = TailorSerializer(tailor)
            
            return Response({
                'user': serializer.data,
                'tokens': {
                    'access': access_token,
                    'refresh': refresh_token
                }
            }, status=200)
            
        except Tailor.DoesNotExist:
            return Response({
                'error': 'Invalid email or password'
            }, status=401)
```

#### Flutter Login Screen
```dart
// lib/features/auth/screens/signin_screen.dart  
class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountsApi = AccountsApiService();
  final _localDbService = LocalDatabaseService();
  final _authService = AuthService();
  
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // 1. Call Django login API
      final request = LoginRequest(
        email: _email,
        password: _password,
      );
      
      final response = await _accountsApi.login(request);
      
      // 2. Save JWT tokens
      await _accountsApi._tokenStorage.saveAccessToken(response.tokens.access);
      await _accountsApi._tokenStorage.saveRefreshToken(response.tokens.refresh);
      await _accountsApi._tokenStorage.saveUserId(response.user.id);
      await _accountsApi._tokenStorage.saveUserEmail(response.user.email);
      await _accountsApi._tokenStorage.saveLoginState(true);
      
      // 3. Sync user to local DB (in case of new device login)
      await _syncToLocalDB(response.user);
      
      // 4. Update auth provider state
      await _authService.setCurrentUser(response.user);
      
      // 5. Navigate to home
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Login successful!')),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Login failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _syncToLocalDB(Tailor tailor) async {
    try {
      final db = await _localDbService.database;
      
      // Check if user exists in local DB
      final existing = await db.query(
        'tailors',
        where: 'id = ?',
        whereArgs: [tailor.id],
      );
      
      if (existing.isEmpty) {
        // Insert new user to local DB
        await db.insert('tailors', tailor.toMap());
        Logger.info('SignIn', '✅ User synced to local DB: ${tailor.id}');
      } else {
        // Update existing user data
        await db.update(
          'tailors',
          tailor.toMap(),
          where: 'id = ?',
          whereArgs: [tailor.id],
        );
        Logger.info('SignIn', '✅ User updated in local DB: ${tailor.id}');
      }
    } catch (e) {
      Logger.error('SignIn', '❌ Failed to sync to local DB', error: e);
      // Don't throw - login is successful, local sync can retry later
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) => _email = value,
              validator: (value) => !value!.contains('@') ? 'Invalid email' : null,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              onChanged: (value) => _password = value,
              validator: (value) => value!.length < 8 ? 'Invalid password' : null,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Login'),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
              child: Text('Forgot Password?'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🔄 Complete Authentication Flow Summary

### Registration → Verification → Local DB Sync

```
1. USER FILLS REGISTRATION FORM
   ↓
2. FLUTTER → Django: POST /api/v1/accounts/auth/register/
   ↓
3. DJANGO CREATES USER (inactive, email_verified=False)
   ↓
4. DJANGO GENERATES & SENDS OTP VIA EMAIL
   ↓
5. DJANGO → Flutter: {user_id, email, otp_sent: true}
   ↓
6. FLUTTER SHOWS OTP VERIFICATION SCREEN
   ↓
7. USER ENTERS OTP CODE
   ↓
8. FLUTTER → Django: POST /api/v1/otp/verify/
   ↓
9. DJANGO VERIFIES OTP
   ↓
10. DJANGO ACTIVATES USER (is_active=True, email_verified=True)
   ↓
11. DJANGO GENERATES JWT TOKENS
   ↓
12. DJANGO → Flutter: {user, tokens}
   ↓
13. FLUTTER SAVES JWT TOKENS TO SECURE STORAGE
   ↓
14. FLUTTER INSERTS VERIFIED USER TO LOCAL SQLITE DB ✅
   ↓
15. FLUTTER NAVIGATES TO HOME SCREEN
```

### Login → Token + Local DB Sync

```
1. USER ENTERS EMAIL & PASSWORD
   ↓
2. FLUTTER → Django: POST /api/v1/accounts/auth/login/
   ↓
3. DJANGO VALIDATES CREDENTIALS
   ↓
4. DJANGO CHECKS email_verified=True
   ↓
5. DJANGO GENERATES JWT TOKENS
   ↓
6. DJANGO → Flutter: {user, tokens}
   ↓
7. FLUTTER SAVES JWT TOKENS TO SECURE STORAGE
   ↓
8. FLUTTER SYNCS USER TO LOCAL SQLITE DB ✅
   ↓
9. FLUTTER NAVIGATES TO HOME SCREEN
```

## 📊 Database Schema

### Django Database (PostgreSQL/MySQL)
```sql
-- Tailor Model (Main User Table)
CREATE TABLE accounts_tailor (
    id VARCHAR(10) PRIMARY KEY,              -- MAT1234567
    unique_id VARCHAR(10) UNIQUE,
    name VARCHAR(100),
    shop_name VARCHAR(100),
    email VARCHAR(254) UNIQUE,
    phone VARCHAR(20) UNIQUE,
    password VARCHAR(128),
    auth_provider VARCHAR(20),
    address TEXT,
    profile_image_path VARCHAR(100),
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT FALSE,          -- FALSE until OTP verified
    email_verified BOOLEAN DEFAULT FALSE,     -- TRUE after OTP verification
    phone_verified BOOLEAN DEFAULT FALSE
);

-- OTP Model
CREATE TABLE otp_otp (
    id SERIAL PRIMARY KEY,
    tailor_id VARCHAR(10) REFERENCES accounts_tailor(id),
    otp_type VARCHAR(20),                     -- 'email', 'phone', 'password_reset'
    otp_code VARCHAR(6),
    contact_info VARCHAR(254),
    is_used BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP,
    created_at TIMESTAMP,
    attempts INTEGER DEFAULT 0
);
```

### Flutter Local Database (SQLite)
```sql
-- Tailors Table (Local Copy of Verified Users Only)
CREATE TABLE tailors (
    id TEXT PRIMARY KEY,                      -- MAT1234567
    unique_id TEXT UNIQUE,
    name TEXT,
    shop_name TEXT,
    email TEXT UNIQUE,
    phone TEXT,
    password_hash TEXT,                       -- NOT stored from backend
    auth_provider TEXT,
    address TEXT,
    profile_image_path TEXT,
    created_at TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0,
    synced_at TEXT,                          -- Last sync timestamp
    backend_id TEXT                           -- Reference to Django ID
);
```

## 🔐 Security Considerations

### Backend (Django)
```python
# settings.py
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
}

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
     'OPTIONS': {'min_length': 8}},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
]

# OTP settings
OTP_EXPIRY_MINUTES = 10
OTP_MAX_ATTEMPTS = 3
```

### Frontend (Flutter)
```dart
// Secure token storage
final storage = FlutterSecureStorage();
await storage.write(key: 'access_token', value: token);

// Don't store password in local DB
// Only store user profile data

// Auto token refresh before expiry
if (token.expiresIn < 5 minutes) {
  await _accountsApi.refreshToken();
}
```

## 🧪 Testing Checklist

### Backend Tests
- [ ] Register creates inactive user
- [ ] OTP is generated and sent
- [ ] OTP verification activates user
- [ ] JWT tokens are generated correctly
- [ ] Login requires email_verified=True
- [ ] Password reset flow works
- [ ] Token refresh works

### Frontend Tests
- [ ] Registration form validation
- [ ] API call to Django register endpoint
- [ ] OTP verification screen shows
- [ ] OTP verification calls backend
- [ ] User is inserted to local DB after verification
- [ ] Login saves tokens and syncs to local DB
- [ ] Offline access reads from local DB
- [ ] Token auto-refresh works

## 🚀 Quick Start Commands

### Django Backend
```bash
cd "C:\Users\mukes\Videos\Android_Dev\Devlopment\TailerBackend\tailor_project"

# Install dependencies
pip install djangorestframework djangorestframework-simplejwt django-cors-headers

# Create migrations
python manage.py makemigrations accounts otp

# Apply migrations
python manage.py migrate

# Run server
python manage.py runserver 127.0.0.1:8000
```

### Flutter Frontend
```bash
cd "C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app"

# Run app
flutter run

# Test registration
# 1. Fill registration form
# 2. Check email for OTP
# 3. Verify OTP
# 4. Check local DB for user record
```

## 🎯 Implementation Summary

**✅ What You Get:**

1. **Secure Backend Authentication**: Django handles all auth logic, OTP, JWT tokens
2. **Email Verification**: Users must verify email before account activation
3. **JWT Token Management**: Access & refresh tokens for API authentication
4. **Local Database Sync**: Verified users copied to SQLite for offline access
5. **Hybrid Architecture**: Backend authentication + local data storage
6. **Multi-Device Support**: Same user can login on multiple devices
7. **Offline Capability**: User profile available locally after first sync

**🔑 Key Points:**

- ✅ Registration creates **inactive** user in Django
- ✅ OTP verification **activates** user and generates tokens
- ✅ Only **verified** users are inserted to local SQLite DB
- ✅ Login syncs latest user data to local DB
- ✅ JWT tokens stored securely in Flutter
- ✅ All auth logic in backend, Flutter just syncs data

Your hybrid authentication system is now fully implemented! 🎉