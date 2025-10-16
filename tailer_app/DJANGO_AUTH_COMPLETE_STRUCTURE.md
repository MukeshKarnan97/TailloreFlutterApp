# Django Authentication System Structure

**Project**: Tailor App Authentication System  
**User Model**: Tailor (existing model - DO NOT create separate User model)  
**Date**: October 13, 2025

## 🏗️ Django Project Structure

### 1. Project Architecture
```
tailor_project/
├── tailor_project/
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── accounts/                    # Main authentication app
│   ├── models.py               # Tailor model + related models
│   ├── serializers.py          # DRF serializers
│   ├── views.py               # API views
│   ├── urls.py                # API endpoints
│   ├── managers.py            # Custom managers
│   ├── utils.py               # Helper functions
│   └── permissions.py         # Custom permissions
├── otp/                       # OTP management app
│   ├── models.py              # OTP models
│   ├── views.py               # OTP views
│   ├── utils.py               # OTP utilities
│   └── urls.py                # OTP endpoints
└── social_auth/               # Social authentication app
    ├── views.py               # Google/Facebook auth
    ├── serializers.py         # Social auth serializers
    └── urls.py                # Social auth endpoints
```

## 📊 Database Models Structure

### 1. Tailor Model (Primary User Model)
**File**: `accounts/models.py`
```python
# Use existing Tailor model structure with these Django fields:
class Tailor(AbstractBaseUser, PermissionsMixin):
    id = CharField(primary_key=True)           # MAT + 7 chars
    unique_id = CharField(unique=True)         # Same as id
    name = CharField()                         # Full name
    shop_name = CharField()                    # Shop name
    email = EmailField(unique=True)           # Email (login field)
    phone = CharField(unique=True)            # Phone number
    password_hash = CharField()               # Hashed password
    auth_provider = CharField()               # 'email', 'google', 'facebook'
    address = TextField()                     # Address
    profile_image_path = ImageField()         # Profile image
    created_at = DateTimeField()              # Creation date
    updated_at = DateTimeField()              # Last update
    is_deleted = BooleanField()               # Soft delete flag
    
    # Django auth fields
    is_active = BooleanField()                # Account active status
    is_staff = BooleanField()                 # Admin access
    email_verified = BooleanField()           # Email verification status
    phone_verified = BooleanField()           # Phone verification status
```

### 2. OTP Model
**File**: `otp/models.py`
```python
class OTP:
    tailor = ForeignKey(Tailor)               # Link to tailor
    otp_type = CharField()                    # 'email', 'phone', 'password_reset'
    otp_code = CharField()                    # 6-digit code
    contact_info = CharField()                # Email or phone
    is_used = BooleanField()                  # Used status
    expires_at = DateTimeField()              # Expiry time
    created_at = DateTimeField()              # Creation time
    attempts = IntegerField()                 # Verification attempts
```

### 3. Social Auth Profile
**File**: `social_auth/models.py`
```python
class SocialAuthProfile:
    tailor = OneToOneField(Tailor)            # Link to tailor
    provider = CharField()                    # 'google', 'facebook'
    provider_id = CharField()                 # Provider user ID
    provider_email = EmailField()             # Provider email
    access_token = TextField()                # Provider access token
    refresh_token = TextField()               # Provider refresh token
    created_at = DateTimeField()              # Link creation date
```

## 🔗 API Endpoints Structure

### 1. Authentication Endpoints
**File**: `accounts/urls.py`

#### Basic Authentication
- `POST /auth/register/`               - User registration
- `POST /auth/login/`                  - Email/password login  
- `POST /auth/logout/`                 - User logout
- `POST /auth/refresh/`                - Refresh JWT token
- `GET /auth/profile/`                 - Get current user profile
- `PUT /auth/profile/`                 - Update user profile

#### Password Management  
- `POST /auth/forgot-password/`        - Request password reset
- `POST /auth/reset-password/`         - Reset password with token
- `POST /auth/change-password/`        - Change password (authenticated)

#### Account Verification
- `POST /auth/verify-email/`           - Verify email with OTP
- `POST /auth/resend-verification/`    - Resend email verification
- `POST /auth/verify-phone/`           - Verify phone with OTP

### 2. OTP Endpoints  
**File**: `otp/urls.py`
- `POST /otp/send-email/`              - Send email OTP
- `POST /otp/send-phone/`              - Send phone OTP  
- `POST /otp/verify/`                  - Verify OTP code
- `POST /otp/resend/`                  - Resend OTP

### 3. Social Authentication
**File**: `social_auth/urls.py`
- `POST /auth/google/`                 - Google OAuth login
- `POST /auth/facebook/`               - Facebook OAuth login
- `POST /auth/google/register/`        - Register with Google
- `POST /auth/facebook/register/`      - Register with Facebook

## 📝 API Input/Output Structure

### 1. Registration API
**Endpoint**: `POST /auth/register/`

**Input Required**:
```json
{
    "name": "string (required)",
    "shop_name": "string (not required)", 
    "email": "email (required, unique)",
    "phone": "string (not required, unique)",
    "password": "string (required, min 8 chars)",
    "confirm_password": "string (not required)",
    "address": "string (not optional)",
    "auth_provider": "email (default)"
}
```

**Output**:
```json
{
    "success": true,
    "message": "Registration successful",
    "data": {
        "tailor": {
            "id": "MAT1234567",
            "name": "John Doe",
            "shop_name": "John's Tailoring",
            "email": "john@example.com",
            "phone": "+1234567890"
        },
        "tokens": {
            "access": "jwt_token",
            "refresh": "refresh_token"
        }
    }
}
```

### 2. Login API
**Endpoint**: `POST /auth/login/`

**Input Required**:
```json
{
    "email": "email (required)",
    "password": "string (required)"
}
```

**Output**:
```json
{
    "success": true,
    "message": "Login successful", 
    "data": {
        "tailor": {
            "id": "MAT1234567",
            "name": "John Doe",
            "shop_name": "John's Tailoring",
            "email": "john@example.com",
            "email_verified": true,
            "phone_verified": false
        },
        "tokens": {
            "access": "jwt_token",
            "refresh": "refresh_token"
        }
    }
}
```

### 3. OTP Verification API
**Endpoint**: `POST /otp/verify/`

**Input Required**:
```json
{
    "otp_code": "string (required, 6 digits)",
    "contact_info": "email or phone (required)",
    "otp_type": "email|phone|password_reset (required)"
}
```

**Output**:
```json
{
    "success": true,
    "message": "OTP verified successfully",
    "data": {
        "verified": true,
        "otp_type": "email"
    }
}
```

### 4. Forgot Password API
**Endpoint**: `POST /auth/forgot-password/`

**Input Required**:
```json
{
    "email": "email (required)"
}
```

**Output**:
```json
{
    "success": true,
    "message": "Password reset OTP sent to email",
    "data": {
        "reset_token": "temp_token_for_reset",
        "expires_in": 600
    }
}
```

### 5. Password Reset API
**Endpoint**: `POST /auth/reset-password/`

**Input Required**:
```json
{
    "reset_token": "string (required)",
    "otp_code": "string (required, 6 digits)",
    "new_password": "string (required, min 8 chars)",
    "confirm_password": "string (required)"
}
```

### 6. Google Authentication API
**Endpoint**: `POST /auth/google/`

**Input Required**:
```json
{
    "access_token": "google_access_token (required)",
    "id_token": "google_id_token (required)"
}
```

**Output**:
```json
{
    "success": true,
    "message": "Google authentication successful",
    "data": {
        "tailor": {
            "id": "MAT1234567",
            "name": "John Doe",
            "email": "john@gmail.com",
            "auth_provider": "google"
        },
        "tokens": {
            "access": "jwt_token", 
            "refresh": "refresh_token"
        },
        "is_new_user": false
    }
}
```

### 7. Facebook Authentication API
**Endpoint**: `POST /auth/facebook/`

**Input Required**:
```json
{
    "access_token": "facebook_access_token (required)",
    "user_id": "facebook_user_id (required)"
}
```

## 🔧 Django Settings Requirements

### Required Packages
```python
# In requirements.txt
djangorestframework==3.14.0
djangorestframework-simplejwt==5.2.0
django-cors-headers==4.0.0
google-auth==2.17.0
facebook-sdk==3.1.0
celery==5.2.0
redis==4.5.0
pillow==9.4.0
```

### Settings Configuration
```python
# Key settings needed
INSTALLED_APPS = [
    'rest_framework',
    'rest_framework_simplejwt',
    'corsheaders',
    'accounts',
    'otp', 
    'social_auth',
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ]
}

# JWT Settings
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
}

# OTP Settings  
OTP_EXPIRY_MINUTES = 10
OTP_MAX_ATTEMPTS = 3

# Email Settings (for OTP)
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'

# Social Auth Settings
GOOGLE_OAUTH2_CLIENT_ID = 'your_google_client_id'
FACEBOOK_APP_ID = 'your_facebook_app_id'
```

## 📱 Flutter Integration Points

### Required Flutter Packages
```yaml
# In pubspec.yaml
dependencies:
  dio: ^5.7.0
  flutter_secure_storage: ^9.2.2
  google_sign_in: ^6.1.0
  flutter_facebook_auth: ^6.0.0
```

### API Service Methods Needed
```dart
// AccountsApiService methods to implement:
- Future<AuthResponse> register(RegisterRequest request)
- Future<AuthResponse> login(LoginRequest request)
- Future<void> logout()
- Future<Tailor> getCurrentProfile()
- Future<Tailor> updateProfile(UpdateProfileRequest request)
- Future<void> forgotPassword(String email)
- Future<void> resetPassword(ResetPasswordRequest request)
- Future<void> changePassword(ChangePasswordRequest request)
- Future<void> sendEmailOTP(String email)
- Future<void> sendPhoneOTP(String phone)
- Future<bool> verifyOTP(VerifyOTPRequest request)
- Future<AuthResponse> googleAuth(String accessToken, String idToken)
- Future<AuthResponse> facebookAuth(String accessToken, String userId)
```

## 🔐 Security Considerations

### Input Validation
- Email format validation
- Password strength requirements (min 8 chars, special chars)
- Phone number format validation
- OTP code format (6 digits only)
- Rate limiting for OTP requests
- CSRF protection for all endpoints

### Authentication Security
- JWT token rotation
- Secure token storage
- Password hashing with salt
- Account lockout after failed attempts
- Email/phone verification requirements
- Social auth token validation

## 📋 Implementation Priority

### Phase 1 (Core Authentication)
1. Tailor model setup with Django auth
2. Basic register/login APIs
3. JWT token management
4. Password reset with email OTP

### Phase 2 (Verification)  
1. Email OTP verification
2. Phone OTP verification
3. Account verification workflows

### Phase 3 (Social Authentication)
1. Google OAuth integration
2. Facebook OAuth integration
3. Social profile linking

### Phase 4 (Flutter Integration)
1. Flutter API service implementation
2. UI screen updates
3. State management integration
4. Error handling and validation

This structure provides a complete authentication system using your existing Tailor model while adding all modern authentication features including OTP verification and social login capabilities.