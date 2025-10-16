# OTP Verification Endpoint - 404 Error Fix

## Problem
```
WARNING Not Found: /api/v1/auth/verify-otp/
WARNING "POST /api/v1/auth/verify-otp/ HTTP/1.1" 404 7106
```

The OTP verification endpoint is returning **404 Not Found**, which means the Django backend doesn't have this URL registered.

---

## Root Cause

The Django backend URLs might be configured differently than expected. The endpoint `/api/v1/auth/verify-otp/` is not found.

---

## Solution Steps

### Step 1: Check Django Backend URLs

Navigate to your Django backend and check the URL configuration:

```bash
cd C:\Users\mukes\Videos\Android_Dev\Devlopment\TailerBackend\tailor_project
```

Check these files:
1. `tailor_project/urls.py` - Main URL configuration
2. `accounts/urls.py` - Authentication app URLs
3. `accounts/views.py` - Check if verify_otp view exists

### Step 2: Verify Django URL Patterns

Your Django `accounts/urls.py` should have something like:

```python
from django.urls import path
from . import views

urlpatterns = [
    path('auth/register/', views.register, name='register'),
    path('auth/verify-otp/', views.verify_otp, name='verify-otp'),  # ← Check this exists
    path('auth/resend-otp/', views.resend_otp, name='resend-otp'),
    path('auth/login/', views.login, name='login'),
    # ... other endpoints
]
```

### Step 3: Check Available Endpoints

Run this command in your Django project to see all available URLs:

```bash
python manage.py show_urls
```

Or if that command doesn't exist:

```bash
python manage.py shell
```

Then in the Python shell:
```python
from django.urls import get_resolver
resolver = get_resolver()
for pattern in resolver.url_patterns:
    print(pattern)
```

---

## Possible Django Backend Issues

### Issue 1: Missing URL Pattern

**Check:** `accounts/urls.py`

The URL pattern for `verify-otp/` might be missing. Add it:

```python
urlpatterns = [
    # ... existing patterns
    path('auth/verify-otp/', views.verify_otp, name='verify-otp'),
    path('auth/resend-otp/', views.resend_otp, name='resend-otp'),
]
```

### Issue 2: Different URL Structure

Your Django backend might use a different URL structure. Common variations:

```python
# Variation 1: Without 'auth/' prefix
path('verify-otp/', views.verify_otp, name='verify-otp')

# Variation 2: With 'accounts/' prefix
path('accounts/auth/verify-otp/', views.verify_otp, name='verify-otp')

# Variation 3: Different naming
path('auth/otp/verify/', views.verify_otp, name='verify-otp')
```

### Issue 3: Missing View Function

**Check:** `accounts/views.py`

Make sure the view exists:

```python
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status

@api_view(['POST'])
def verify_otp(request):
    email = request.data.get('email')
    otp_code = request.data.get('otp_code')
    otp_type = request.data.get('otp_type', 'registration')
    
    # Your OTP verification logic here
    
    return Response({
        'success': True,
        'message': 'OTP verified successfully',
        'user': user_data
    })
```

---

## Quick Check Commands

### 1. Check Django Server Logs
Look at the Django console output to see what URLs are registered when the server starts.

### 2. Test with cURL
```bash
# Test registration (working)
curl -X POST http://192.168.0.3:8000/api/v1/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"Test123","password_confirm":"Test123","name":"Test"}'

# Test OTP verification (failing)
curl -X POST http://192.168.0.3:8000/api/v1/auth/verify-otp/ \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","otp_code":"1234","otp_type":"registration"}'
```

### 3. List All Django URLs
```python
# In Django shell
from django.urls import get_resolver
urls = get_resolver().url_patterns
for url in urls:
    print(url)
```

---

## Temporary Workaround

If the endpoint doesn't exist yet, you can temporarily disable OTP verification and activate users automatically on registration:

**Option 1: Auto-activate on registration**
In Django `views.py`:
```python
@api_view(['POST'])
def register(request):
    # ... create user
    user.is_active = True  # ← Auto-activate
    user.save()
    # ... return response
```

**Option 2: Skip OTP screen**
In Flutter, modify signup flow to go directly to dashboard after registration.

---

## Expected Django Implementation

Here's what your Django backend should have:

### 1. URL Configuration (`accounts/urls.py`)
```python
from django.urls import path
from . import views

urlpatterns = [
    path('auth/register/', views.register_user, name='register'),
    path('auth/verify-otp/', views.verify_otp, name='verify-otp'),
    path('auth/resend-otp/', views.resend_otp, name='resend-otp'),
    path('auth/login/', views.login_user, name='login'),
    path('auth/refresh/', views.refresh_token, name='refresh-token'),
    path('auth/check-email/', views.check_email, name='check-email'),
]
```

### 2. OTP Verification View (`accounts/views.py`)
```python
@api_view(['POST'])
def verify_otp(request):
    email = request.data.get('email')
    otp_code = request.data.get('otp_code')
    otp_type = request.data.get('otp_type', 'registration')
    
    try:
        # Get OTP from database
        otp_obj = OTP.objects.get(
            email=email,
            otp_code=otp_code,
            otp_type=otp_type,
            is_used=False
        )
        
        # Check if expired
        if timezone.now() > otp_obj.expires_at:
            return Response({
                'success': False,
                'message': 'OTP has expired'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Mark OTP as used
        otp_obj.is_used = True
        otp_obj.save()
        
        # Activate user
        user = User.objects.get(email=email)
        user.is_active = True
        user.email_verified = True
        user.save()
        
        return Response({
            'success': True,
            'message': 'OTP verified successfully',
            'user': {
                'id': user.id,
                'email': user.email,
                'name': user.name,
                'is_active': True
            }
        })
        
    except OTP.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Invalid OTP'
        }, status=status.HTTP_400_BAD_REQUEST)
```

### 3. OTP Model (`accounts/models.py`)
```python
class OTP(models.Model):
    email = models.EmailField()
    otp_code = models.CharField(max_length=6)
    otp_type = models.CharField(max_length=20)  # registration, password_reset
    is_used = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    
    class Meta:
        ordering = ['-created_at']
```

---

## Flutter Side Check

The Flutter code is correct and pointing to `/api/v1/auth/verify-otp/`. You don't need to change anything on the Flutter side.

**Current Flutter Implementation:**
```dart
// In AccountsApiService
Future<VerifyOTPResponse> verifyOTP({
  required String email,
  required String otpCode,
  String otpType = 'registration',
}) async {
  final response = await _apiClient.post(
    ApiEndpoints.verifyOTP,  // '/auth/verify-otp/'
    data: request.toJson(),
  );
  // ...
}
```

This is **correct** ✅. The issue is on the Django backend.

---

## Next Steps

1. **Check Django backend** - Verify the URL exists in `accounts/urls.py`
2. **Check Django view** - Ensure `verify_otp` function exists in `accounts/views.py`
3. **Check URL registration** - Make sure the accounts app URLs are included in main `urls.py`
4. **Restart Django server** - After making changes
5. **Test again** - Use the Flutter app or cURL to test

---

## How to Check Django URLs

```bash
# Navigate to Django project
cd C:\Users\mukes\Videos\Android_Dev\Devlopment\TailerBackend\tailor_project

# Check what's in accounts/urls.py
Get-Content accounts/urls.py

# Check what's in accounts/views.py
Get-Content accounts/views.py | Select-String "verify_otp"

# Check main urls.py
Get-Content tailor_project/urls.py
```

---

## Expected Output After Fix

When the endpoint is properly configured, you should see:

```
INFO "POST /api/v1/auth/register/ HTTP/1.1" 201 1143
INFO "POST /api/v1/auth/verify-otp/ HTTP/1.1" 200 256
```

Instead of:
```
INFO "POST /api/v1/auth/register/ HTTP/1.1" 201 1143
WARNING Not Found: /api/v1/auth/verify-otp/  ← This error will be gone
WARNING "POST /api/v1/auth/verify-otp/ HTTP/1.1" 404 7106  ← This too
```

---

**Summary:** The Flutter app is correctly configured. The issue is that the Django backend doesn't have the `/api/v1/auth/verify-otp/` endpoint registered. You need to add this endpoint to your Django backend's URL configuration.
