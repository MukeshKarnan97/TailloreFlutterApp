# 🧪 Django-Flutter Integration Test Guide

**Django Server**: `http://127.0.0.1:8000/`  
**Django Project**: `C:\Users\mukes\Videos\Android_Dev\Devlopment\TailerBackend\tailor_project\`  
**Flutter API**: Updated to point to Django backend  
**Date**: October 14, 2025

## ✅ Configuration Updated

### Flutter API Configuration
```dart
// Updated in: lib/core/config/api_config.dart
static const String developmentBaseUrl = 'http://127.0.0.1:8000';
```

The Flutter app will now connect to your Django server at `http://127.0.0.1:8000`.

## 🔍 Django Backend Compatibility Check

Based on your `DJANGO_AUTH_COMPLETE_STRUCTURE.md`, here's what your Django backend needs to work with the Flutter API:

### 1. Required Django URL Patterns
Your Django `urls.py` should have these endpoints:

```python
# tailor_project/urls.py
urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/accounts/', include('accounts.urls')),
]

# accounts/urls.py  
urlpatterns = [
    # Authentication
    path('auth/register/', RegisterView.as_view(), name='register'),
    path('auth/login/', LoginView.as_view(), name='login'),
    path('auth/logout/', LogoutView.as_view(), name='logout'),
    path('auth/refresh/', RefreshTokenView.as_view(), name='refresh'),
    
    # Password Management
    path('auth/forgot-password/', ForgotPasswordView.as_view(), name='forgot_password'),
    path('auth/reset-password/', ResetPasswordView.as_view(), name='reset_password'),
    path('users/me/password/', ChangePasswordView.as_view(), name='change_password'),
    
    # User Management  
    path('users/me/', CurrentUserView.as_view(), name='current_user'),
    
    # Email Verification
    path('auth/verify-email/', VerifyEmailView.as_view(), name='verify_email'),
    path('auth/resend-verification/', ResendVerificationView.as_view(), name='resend_verification'),
]
```

### 2. Required Django Models
Your Django models should match the Flutter Tailor structure:

```python
# accounts/models.py
class Tailor(AbstractBaseUser, PermissionsMixin):
    id = models.CharField(max_length=10, primary_key=True)           # MAT + 7 chars
    unique_id = models.CharField(max_length=10, unique=True)
    name = models.CharField(max_length=100)                         # Full name
    shop_name = models.CharField(max_length=100)                    # Shop name
    email = models.EmailField(unique=True)                         # Login field
    phone = models.CharField(max_length=20, unique=True)
    password = models.CharField(max_length=128)                    # Django handles hashing
    auth_provider = models.CharField(max_length=20, default='email')
    address = models.TextField(blank=True)
    profile_image_path = models.ImageField(upload_to='profiles/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_deleted = models.BooleanField(default=False)
    
    # Django auth fields
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    email_verified = models.BooleanField(default=False)
    phone_verified = models.BooleanField(default=False)
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['name', 'shop_name', 'phone']
    
    objects = TailorManager()  # Custom manager needed
```

### 3. Expected API Request/Response Format

**Registration Request (Flutter → Django):**
```json
POST /api/v1/accounts/auth/register/
{
    "email": "tailor@example.com",
    "password": "password123",
    "password_confirm": "password123",
    "name": "John Doe",
    "shop_name": "John's Tailoring",
    "phone": "+1234567890", 
    "address": "123 Main Street",
    "auth_provider": "email"
}
```

**Expected Response (Django → Flutter):**
```json
{
    "user": {
        "id": "MAT1234567",
        "unique_id": "MAT1234567", 
        "name": "John Doe",
        "shop_name": "John's Tailoring",
        "email": "tailor@example.com",
        "phone": "+1234567890",
        "address": "123 Main Street",
        "auth_provider": "email",
        "profile_image_path": null,
        "created_at": "2025-10-14T07:34:21.123456Z",
        "updated_at": "2025-10-14T07:34:21.123456Z",
        "is_deleted": false
    },
    "tokens": {
        "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
        "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
    }
}
```

## 🧪 Testing Steps

### 1. Basic Connection Test
```bash
# Test if Django server is accessible from Flutter
curl http://127.0.0.1:8000/
```

### 2. API Endpoint Tests

**Test Registration:**
```bash
curl -X POST http://127.0.0.1:8000/api/v1/accounts/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123", 
    "password_confirm": "password123",
    "name": "Test Tailor",
    "shop_name": "Test Shop",
    "phone": "+1234567890",
    "address": "Test Address",
    "auth_provider": "email"
  }'
```

**Test Login:**
```bash
curl -X POST http://127.0.0.1:8000/api/v1/accounts/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

### 3. Flutter API Test
Create a simple test in Flutter:

```dart
// Test file: test_django_connection.dart
import 'package:tailer_app/data/services/accounts_api_service.dart';
import 'package:tailer_app/data/models/account/auth_models.dart';

void testDjangoConnection() async {
  final api = AccountsApiService();
  
  try {
    // Test registration
    final registerRequest = RegisterRequest(
      email: 'flutter@test.com',
      password: 'password123',
      passwordConfirm: 'password123',
      name: 'Flutter Test',
      shopName: 'Flutter Test Shop', 
      phone: '+1234567890',
      address: 'Flutter Test Address',
    );
    
    final registerResponse = await api.register(registerRequest);
    print('✅ Registration successful: ${registerResponse.user.name}');
    
    // Test login
    final loginRequest = LoginRequest(
      email: 'flutter@test.com',
      password: 'password123',
    );
    
    final loginResponse = await api.login(loginRequest);
    print('✅ Login successful: ${loginResponse.user.email}');
    
  } catch (e) {
    print('❌ Test failed: $e');
  }
}
```

## 🚨 Potential Issues & Solutions

### 1. CORS Issues
If you get CORS errors, add to Django settings:

```python
# settings.py
INSTALLED_APPS = [
    # ...
    'corsheaders',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    # ...
]

CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",   # Flutter web
    "http://127.0.0.1:3000",  # Flutter web alternative
]

# For development only
CORS_ALLOW_ALL_ORIGINS = True
```

### 2. Content-Type Issues
Ensure Django accepts JSON:

```python
# views.py
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator

@method_decorator(csrf_exempt, name='dispatch')
class RegisterView(APIView):
    def post(self, request):
        # Handle JSON data
        pass
```

### 3. Authentication Backend
Configure Django to use email as username:

```python
# settings.py
AUTH_USER_MODEL = 'accounts.Tailor'

AUTHENTICATION_BACKENDS = [
    'accounts.backends.EmailBackend',  # Custom backend
    'django.contrib.auth.backends.ModelBackend',
]
```

### 4. Flutter Network Permissions
For Android, ensure network permissions:

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
```

## ✅ Success Indicators

### Django Side
- ✅ Server running on `http://127.0.0.1:8000/`
- ✅ Admin panel accessible: `http://127.0.0.1:8000/admin/`
- ✅ API endpoints return proper JSON responses
- ✅ CORS configured for Flutter connections

### Flutter Side  
- ✅ API calls connect to Django server
- ✅ Registration creates new Tailor in Django database
- ✅ Login returns JWT tokens and Tailor object
- ✅ Token storage works for authenticated requests

## 🎯 Quick Start Commands

### Django Setup Check
```bash
cd "C:\Users\mukes\Videos\Android_Dev\Devlopment\TailerBackend\tailor_project\"
python manage.py makemigrations
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 127.0.0.1:8000
```

### Flutter Test  
```bash
cd "C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app\"
flutter run  # Test on device/emulator
```

## 📋 Integration Checklist

- [ ] **Django URLs**: All API endpoints configured
- [ ] **Django Models**: Tailor model matches Flutter expectations  
- [ ] **Django Views**: Handle registration/login with proper responses
- [ ] **Django CORS**: Flutter connections allowed
- [ ] **Flutter Config**: Points to `http://127.0.0.1:8000`
- [ ] **Network Permissions**: Android app can make HTTP requests
- [ ] **Test Registration**: Creates Tailor in Django database
- [ ] **Test Login**: Returns proper JWT tokens and user data

## 🎉 Expected Result

If everything is configured correctly:

1. **Registration**: Flutter app sends Tailor data → Django creates Tailor record → Returns JWT tokens
2. **Login**: Flutter app sends email/password → Django validates → Returns JWT + Tailor data  
3. **Authenticated Requests**: Flutter includes JWT token → Django validates → Returns protected data

Your Django backend running at `http://127.0.0.1:8000/` should work perfectly with the Flutter API integration! 🚀