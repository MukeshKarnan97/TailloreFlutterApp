# 🔐 Django Backend + Flutter Local DB Integration Strategy

**Django Backend**: `C:\Users\mukes\Videos\Android_Dev\Devlopment\TailerBackend\tailor_project`  
**Authentication**: Backend-controlled (Django)  
**Data Storage**: Hybrid (Backend + Local SQLite)  
**Date**: October 14, 2025

## 🎯 Authentication & Data Flow Strategy

### Architecture Overview
```
┌─────────────────────────────────────────────────────────────┐
│                    AUTHENTICATION FLOW                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Flutter App                Django Backend                  │
│  ┌──────────┐              ┌──────────────┐               │
│  │ Register │─────────────>│ 1. Validate  │               │
│  │  Screen  │              │ 2. Create    │               │
│  └──────────┘              │    Tailor    │               │
│       │                    │ 3. Generate  │               │
│       │                    │    OTP       │               │
│       │                    │ 4. Send Email│               │
│       │                    └──────────────┘               │
│       │                           │                        │
│       v                           v                        │
│  ┌──────────┐              ┌──────────────┐               │
│  │   OTP    │<─────────────│  OTP Sent    │               │
│  │ Verify   │              │              │               │
│  │  Screen  │─────────────>│ 5. Verify    │               │
│  └──────────┘              │    OTP       │               │
│       │                    │ 6. Activate  │               │
│       │                    │    Account   │               │
│       │                    │ 7. Generate  │               │
│       │                    │    JWT       │               │
│       │                    └──────────────┘               │
│       │                           │                        │
│       v                           v                        │
│  ┌──────────┐              ┌──────────────┐               │
│  │ Success  │<─────────────│ Return User  │               │
│  │   +      │              │  + Tokens    │               │
│  │ Insert   │              └──────────────┘               │
│  │ Local DB │                                              │
│  └──────────┘                                              │
│       │                                                    │
│       v                                                    │
│  ┌──────────────────────────┐                            │
│  │  Local SQLite Database   │                            │
│  │  (Tailor data cached)    │                            │
│  └──────────────────────────┘                            │
└─────────────────────────────────────────────────────────────┘
```

## 🔑 Key Responsibilities

### Django Backend (Server-Side)
✅ **Authentication Control**
- User registration validation
- Email/phone uniqueness checks
- Password hashing and security
- OTP generation and sending
- Email/phone verification
- Account activation
- JWT token generation and management
- Login authentication
- Password reset flows

✅ **Data Master**
- Primary data storage (PostgreSQL/MySQL)
- User account management
- Cross-device synchronization
- Data backup and recovery

### Flutter App (Client-Side)
✅ **UI & User Experience**
- Registration/login screens
- OTP input interface
- Loading states and animations
- Error message display

✅ **Local Data Cache**
- Cache authenticated user data in SQLite
- Enable offline access
- Fast local queries
- Sync with backend when online

## 📋 Detailed Implementation Flow

### 1. Registration Flow (Backend-Controlled)

#### Step 1: User Registration
```dart
// Flutter Side
Future<void> registerUser() async {
  final request = RegisterRequest(
    email: 'tailor@example.com',
    password: 'password123',
    passwordConfirm: 'password123',
    name: 'John Doe',
    shopName: 'John\'s Tailoring',
    phone: '+1234567890',
    address: '123 Main Street',
  );
  
  try {
    // Call Django backend
    final response = await accountsApiService.register(request);
    
    // Backend response: { "message": "OTP sent to email", "temp_token": "..." }
    // DO NOT save to local DB yet - user not verified
    
    // Navigate to OTP verification screen
    navigateToOTPScreen(email: request.email, tempToken: response.tempToken);
    
  } catch (e) {
    // Show error from backend
    showError(e.message);
  }
}
```

#### Django Backend (Step 1)
```python
# accounts/views.py
class RegisterView(APIView):
    def post(self, request):
        # 1. Validate input data
        serializer = RegisterSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({"error": serializer.errors}, status=400)
        
        # 2. Check if email already exists
        if Tailor.objects.filter(email=serializer.validated_data['email']).exists():
            return Response({"error": "Email already registered"}, status=400)
        
        # 3. Create Tailor account (NOT ACTIVATED YET)
        tailor = Tailor.objects.create_user(
            email=serializer.validated_data['email'],
            password=serializer.validated_data['password'],
            name=serializer.validated_data['name'],
            shop_name=serializer.validated_data.get('shop_name', ''),
            phone=serializer.validated_data.get('phone', ''),
            address=serializer.validated_data.get('address', ''),
            is_active=False,  # Not activated until OTP verified
            email_verified=False
        )
        
        # 4. Generate OTP
        otp_code = generate_otp()  # 6-digit code
        OTP.objects.create(
            tailor=tailor,
            otp_type='email',
            otp_code=otp_code,
            contact_info=tailor.email,
            expires_at=timezone.now() + timedelta(minutes=10)
        )
        
        # 5. Send OTP email
        send_otp_email(tailor.email, otp_code)
        
        # 6. Generate temporary token for OTP verification
        temp_token = generate_temp_token(tailor.id)
        
        return Response({
            "success": True,
            "message": "OTP sent to your email",
            "temp_token": temp_token,
            "email": tailor.email
        })
```

#### Step 2: OTP Verification
```dart
// Flutter Side
Future<void> verifyOTP(String otpCode, String tempToken) async {
  try {
    // Call Django backend to verify OTP
    final response = await accountsApiService.verifyEmailOTP(
      otpCode: otpCode,
      tempToken: tempToken,
    );
    
    // Backend returns: { "user": {...}, "tokens": {...} }
    final tailor = response.user;  // Tailor object
    final tokens = response.tokens;  // JWT access + refresh tokens
    
    // NOW save to local database (user is verified and active)
    await saveToLocalDatabase(tailor);
    
    // Save JWT tokens securely
    await tokenStorage.saveTokens(
      accessToken: tokens.access,
      refreshToken: tokens.refresh,
    );
    
    // Navigate to home screen
    navigateToHome();
    
  } catch (e) {
    showError('Invalid OTP or expired');
  }
}

Future<void> saveToLocalDatabase(Tailor tailor) async {
  final db = await LocalDatabaseService().database;
  
  // Insert into local SQLite
  await db.insert('tailors', {
    'id': tailor.id,
    'unique_id': tailor.uniqueId,
    'name': tailor.name,
    'shop_name': tailor.shopName,
    'email': tailor.email,
    'phone': tailor.phone,
    'password_hash': '', // Don't store password locally
    'auth_provider': tailor.authProvider,
    'address': tailor.address,
    'profile_image_path': tailor.profileImagePath,
    'created_at': tailor.createdAt.toIso8601String(),
    'updated_at': tailor.updatedAt.toIso8601String(),
    'is_deleted': 0,
  });
  
  print('✅ User data saved to local database');
}
```

#### Django Backend (Step 2)
```python
# accounts/views.py
class VerifyEmailOTPView(APIView):
    def post(self, request):
        otp_code = request.data.get('otp_code')
        temp_token = request.data.get('temp_token')
        
        # 1. Validate temp token and get tailor ID
        tailor_id = decode_temp_token(temp_token)
        if not tailor_id:
            return Response({"error": "Invalid token"}, status=400)
        
        # 2. Get tailor
        try:
            tailor = Tailor.objects.get(id=tailor_id)
        except Tailor.DoesNotExist:
            return Response({"error": "User not found"}, status=404)
        
        # 3. Verify OTP
        otp = OTP.objects.filter(
            tailor=tailor,
            otp_code=otp_code,
            otp_type='email',
            is_used=False,
            expires_at__gt=timezone.now()
        ).first()
        
        if not otp:
            return Response({"error": "Invalid or expired OTP"}, status=400)
        
        # 4. Activate account
        tailor.is_active = True
        tailor.email_verified = True
        tailor.save()
        
        # 5. Mark OTP as used
        otp.is_used = True
        otp.save()
        
        # 6. Generate JWT tokens
        refresh = RefreshToken.for_user(tailor)
        access_token = str(refresh.access_token)
        refresh_token = str(refresh)
        
        # 7. Return user data + tokens
        serializer = TailorSerializer(tailor)
        return Response({
            "success": True,
            "message": "Email verified successfully",
            "user": serializer.data,
            "tokens": {
                "access": access_token,
                "refresh": refresh_token
            }
        })
```

### 2. Login Flow (Backend-Controlled)

```dart
// Flutter Side
Future<void> loginUser(String email, String password) async {
  try {
    // Call Django backend
    final response = await accountsApiService.login(
      LoginRequest(email: email, password: password)
    );
    
    final tailor = response.user;
    final tokens = response.tokens;
    
    // Check if user exists in local DB
    final localTailor = await getFromLocalDatabase(tailor.id);
    
    if (localTailor == null) {
      // First time login on this device - insert to local DB
      await saveToLocalDatabase(tailor);
    } else {
      // Update local data with latest from backend
      await updateLocalDatabase(tailor);
    }
    
    // Save JWT tokens
    await tokenStorage.saveTokens(
      accessToken: tokens.access,
      refreshToken: tokens.refresh,
    );
    
    navigateToHome();
    
  } catch (e) {
    showError('Invalid email or password');
  }
}
```

#### Django Backend (Login)
```python
# accounts/views.py
class LoginView(APIView):
    def post(self, request):
        email = request.data.get('email')
        password = request.data.get('password')
        
        # 1. Authenticate user
        tailor = authenticate(email=email, password=password)
        
        if not tailor:
            return Response({"error": "Invalid credentials"}, status=401)
        
        # 2. Check if account is active
        if not tailor.is_active:
            return Response({"error": "Account not activated"}, status=403)
        
        # 3. Generate JWT tokens
        refresh = RefreshToken.for_user(tailor)
        access_token = str(refresh.access_token)
        refresh_token = str(refresh)
        
        # 4. Return user data + tokens
        serializer = TailorSerializer(tailor)
        return Response({
            "success": True,
            "message": "Login successful",
            "user": serializer.data,
            "tokens": {
                "access": access_token,
                "refresh": refresh_token
            }
        })
```

### 3. OTP Generation & Management

#### Django Backend
```python
# otp/utils.py
import random
import string

def generate_otp():
    """Generate 6-digit OTP code"""
    return ''.join(random.choices(string.digits, k=6))

def send_otp_email(email, otp_code):
    """Send OTP via email"""
    from django.core.mail import send_mail
    
    subject = 'Your OTP Code - Tailor App'
    message = f'''
    Hello,
    
    Your OTP code is: {otp_code}
    
    This code will expire in 10 minutes.
    
    If you didn't request this, please ignore this email.
    '''
    
    send_mail(
        subject,
        message,
        'noreply@tailorapp.com',
        [email],
        fail_silently=False,
    )
```

### 4. Token Management

#### Django Backend (JWT Settings)
```python
# settings.py
from datetime import timedelta

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'UPDATE_LAST_LOGIN': True,
    
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'AUTH_HEADER_TYPES': ('Bearer',),
}
```

#### Flutter Side (Token Storage)
```dart
// Token storage already implemented in TokenStorageService
await tokenStorage.saveAccessToken(accessToken);
await tokenStorage.saveRefreshToken(refreshToken);
await tokenStorage.saveUserId(tailor.id);
await tokenStorage.saveUserEmail(tailor.email);
```

## 🔄 Data Synchronization Strategy

### When to Insert/Update Local DB

```dart
class AuthSyncService {
  final LocalDatabaseService _localDb;
  final AccountsApiService _apiService;
  
  // Insert to local DB after successful verification
  Future<void> syncAfterRegistration(Tailor tailor) async {
    await _localDb.insertTailor(tailor);
    print('✅ New user synced to local DB');
  }
  
  // Update local DB on login
  Future<void> syncOnLogin(Tailor backendTailor) async {
    final localTailor = await _localDb.getTailorById(backendTailor.id);
    
    if (localTailor == null) {
      // First login on this device
      await _localDb.insertTailor(backendTailor);
    } else {
      // Update with latest data from backend
      await _localDb.updateTailor(backendTailor);
    }
    print('✅ User data synced from backend');
  }
  
  // Periodic sync when online
  Future<void> syncPeriodically() async {
    if (await isOnline()) {
      final backendTailor = await _apiService.getCurrentUser();
      await _localDb.updateTailor(backendTailor);
      print('✅ Periodic sync completed');
    }
  }
}
```

## 📊 Database Comparison

### Django Backend (PostgreSQL/MySQL)
```sql
-- Master database with all features
CREATE TABLE accounts_tailor (
    id VARCHAR(10) PRIMARY KEY,  -- MAT1234567
    unique_id VARCHAR(10) UNIQUE,
    name VARCHAR(100),
    shop_name VARCHAR(100),
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20) UNIQUE,
    password VARCHAR(128),  -- Hashed
    auth_provider VARCHAR(20),
    address TEXT,
    profile_image_path VARCHAR(255),
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    is_deleted BOOLEAN,
    is_active BOOLEAN,
    is_staff BOOLEAN,
    email_verified BOOLEAN,
    phone_verified BOOLEAN
);
```

### Flutter Local DB (SQLite)
```sql
-- Cached user data for offline access
CREATE TABLE tailors (
    id TEXT PRIMARY KEY,
    unique_id TEXT,
    name TEXT,
    shop_name TEXT,
    email TEXT,
    phone TEXT,
    password_hash TEXT,  -- Empty, don't store passwords locally
    auth_provider TEXT,
    address TEXT,
    profile_image_path TEXT,
    created_at TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0
);
```

## ✅ Implementation Checklist

### Backend (Django)
- [ ] **Tailor Model**: Complete with all fields
- [ ] **OTP Model**: For email/phone verification
- [ ] **Register View**: Create user + send OTP
- [ ] **Verify OTP View**: Activate account + generate tokens
- [ ] **Login View**: Authenticate + return tokens
- [ ] **JWT Setup**: Token generation and validation
- [ ] **Email Service**: OTP sending configured
- [ ] **CORS**: Allow Flutter connections

### Frontend (Flutter)
- [ ] **Registration Screen**: Call backend register API
- [ ] **OTP Screen**: Verify OTP with backend
- [ ] **Login Screen**: Call backend login API
- [ ] **Local DB Insert**: Save user after verification
- [ ] **Token Storage**: Save JWT tokens securely
- [ ] **Sync Service**: Update local DB from backend
- [ ] **Offline Mode**: Use cached data when offline

## 🎯 Summary

**Authentication Control**: 100% Django Backend
- ✅ Registration validation
- ✅ OTP generation and sending
- ✅ Email verification
- ✅ Account activation
- ✅ JWT token generation
- ✅ Login authentication

**Data Storage**: Hybrid
- ✅ **Master Data**: Django backend (PostgreSQL/MySQL)
- ✅ **Cache**: Flutter local SQLite
- ✅ **Sync**: Backend → Local DB after verification/login

**Flow**:
1. User registers → Django validates → Sends OTP
2. User verifies OTP → Django activates account → Returns tokens + user data
3. Flutter saves to local DB → User can now use app
4. User login → Django authenticates → Flutter syncs latest data to local DB

This architecture gives you the best of both worlds: **secure backend authentication** with **fast offline access**! 🚀