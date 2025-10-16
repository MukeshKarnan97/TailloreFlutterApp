# Django Backend - Required Endpoints Checklist

Based on the Flutter app implementation, here are **all the endpoints** that need to be implemented in your Django backend.

---

## ✅ Working Endpoints

### 1. Registration
```
✅ POST /api/v1/auth/register/
Status: 201 Created (Working)
```

---

## ❌ Missing/Unverified Endpoints

### 2. OTP Verification
```
❌ POST /api/v1/auth/verify-otp/
Status: 404 Not Found (MISSING)
Priority: HIGH - Needed for user activation
```

### 3. Resend OTP
```
❓ POST /api/v1/auth/resend-otp/
Status: Unknown
Priority: HIGH - Needed with OTP verification
```

### 4. Login
```
❓ POST /api/v1/auth/login/
Status: Unknown
Priority: HIGH - Core functionality
```

### 5. Token Refresh
```
❓ POST /api/v1/auth/refresh/
Status: Unknown
Priority: HIGH - Required for auth
```

### 6. Check Email
```
❓ POST /api/v1/auth/check-email/
Status: Unknown
Priority: MEDIUM - Nice to have
```

### 7. Forgot Password
```
❓ POST /api/v1/auth/forgot-password/
Status: Unknown
Priority: MEDIUM
```

### 8. Reset Password
```
❓ POST /api/v1/auth/reset-password/
Status: Unknown
Priority: MEDIUM
```

### 9. Change Password
```
❓ POST /api/v1/auth/change-password/
Status: Unknown
Priority: MEDIUM
```

### 10. Get Current User
```
❓ GET /api/v1/auth/users/me/
Status: Unknown
Priority: HIGH - User profile
```

### 11. Update User Profile
```
❓ PATCH /api/v1/auth/users/me/
Status: Unknown
Priority: MEDIUM
```

---

## Quick Test Script

Create this file in your Django project root to test all endpoints:

**File:** `test_endpoints.py`

```python
import requests
import json

BASE_URL = "http://192.168.0.3:8000/api/v1"

def test_endpoint(method, endpoint, data=None, token=None):
    url = f"{BASE_URL}{endpoint}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    
    try:
        if method == "GET":
            response = requests.get(url, headers=headers)
        elif method == "POST":
            response = requests.post(url, json=data, headers=headers)
        elif method == "PATCH":
            response = requests.patch(url, json=data, headers=headers)
        
        print(f"{'✅' if response.status_code < 400 else '❌'} {method} {endpoint} - {response.status_code}")
        return response.status_code < 400
    except Exception as e:
        print(f"❌ {method} {endpoint} - ERROR: {e}")
        return False

# Test all endpoints
print("\n" + "="*60)
print("TESTING DJANGO BACKEND ENDPOINTS")
print("="*60 + "\n")

# Registration (should work)
print("1. Registration:")
test_endpoint("POST", "/auth/register/", {
    "email": "test@test.com",
    "password": "Test123",
    "password_confirm": "Test123",
    "name": "Test User",
    "shop_name": "Test Shop"
})

# OTP Verification (currently 404)
print("\n2. OTP Verification:")
test_endpoint("POST", "/auth/verify-otp/", {
    "email": "test@test.com",
    "otp_code": "1234",
    "otp_type": "registration"
})

# Resend OTP
print("\n3. Resend OTP:")
test_endpoint("POST", "/auth/resend-otp/", {
    "email": "test@test.com",
    "otp_type": "registration"
})

# Login
print("\n4. Login:")
test_endpoint("POST", "/auth/login/", {
    "email": "test@test.com",
    "password": "Test123"
})

# Check Email
print("\n5. Check Email:")
test_endpoint("POST", "/auth/check-email/", {
    "email": "test@test.com"
})

# Forgot Password
print("\n6. Forgot Password:")
test_endpoint("POST", "/auth/forgot-password/", {
    "email": "test@test.com"
})

# Reset Password
print("\n7. Reset Password:")
test_endpoint("POST", "/auth/reset-password/", {
    "email": "test@test.com",
    "otp_code": "1234",
    "new_password": "NewPass123",
    "new_password_confirm": "NewPass123"
})

print("\n" + "="*60)
print("TEST COMPLETE")
print("="*60 + "\n")
```

**Run it:**
```bash
python test_endpoints.py
```

---

## PowerShell Test Script

Or use this PowerShell script to test from Windows:

```powershell
$baseUrl = "http://192.168.0.3:8000/api/v1"

function Test-Endpoint {
    param($Method, $Endpoint, $Body)
    
    $url = "$baseUrl$Endpoint"
    $headers = @{"Content-Type" = "application/json"}
    
    try {
        if ($Method -eq "GET") {
            $response = Invoke-WebRequest -Uri $url -Method $Method -Headers $headers -ErrorAction Stop
        } else {
            $jsonBody = $Body | ConvertTo-Json
            $response = Invoke-WebRequest -Uri $url -Method $Method -Headers $headers -Body $jsonBody -ErrorAction Stop
        }
        Write-Host "✅ $Method $Endpoint - $($response.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "❌ $Method $Endpoint - $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "TESTING DJANGO BACKEND ENDPOINTS" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

# Test Registration
Write-Host "1. Registration:" -ForegroundColor Yellow
Test-Endpoint "POST" "/auth/register/" @{
    email = "test@test.com"
    password = "Test123"
    password_confirm = "Test123"
    name = "Test User"
    shop_name = "Test Shop"
}

# Test OTP Verification
Write-Host "`n2. OTP Verification:" -ForegroundColor Yellow
Test-Endpoint "POST" "/auth/verify-otp/" @{
    email = "test@test.com"
    otp_code = "1234"
    otp_type = "registration"
}

# Test Resend OTP
Write-Host "`n3. Resend OTP:" -ForegroundColor Yellow
Test-Endpoint "POST" "/auth/resend-otp/" @{
    email = "test@test.com"
    otp_type = "registration"
}

# Test Login
Write-Host "`n4. Login:" -ForegroundColor Yellow
Test-Endpoint "POST" "/auth/login/" @{
    email = "test@test.com"
    password = "Test123"
}

Write-Host "`n============================================" -ForegroundColor Cyan
```

Save as `test-endpoints.ps1` and run:
```powershell
.\test-endpoints.ps1
```

---

## What You Need to Add to Django

### Priority 1: OTP Endpoints (HIGH)

**File:** `accounts/urls.py`
```python
urlpatterns = [
    # ... existing
    path('auth/verify-otp/', views.verify_otp, name='verify-otp'),
    path('auth/resend-otp/', views.resend_otp, name='resend-otp'),
]
```

**File:** `accounts/views.py`
```python
@api_view(['POST'])
def verify_otp(request):
    # Implementation needed
    pass

@api_view(['POST'])
def resend_otp(request):
    # Implementation needed
    pass
```

### Priority 2: Login & Refresh (HIGH)

```python
urlpatterns = [
    # ... existing
    path('auth/login/', views.login_user, name='login'),
    path('auth/refresh/', views.refresh_token, name='refresh-token'),
]
```

### Priority 3: User Management (HIGH)

```python
urlpatterns = [
    # ... existing
    path('auth/users/me/', views.current_user, name='current-user'),
]
```

---

## Check Django URLs Now

Run this command in your Django project:

```bash
cd C:\Users\mukes\Videos\Android_Dev\Devlopment\TailerBackend\tailor_project
python manage.py show_urls | findstr "auth"
```

Or:
```bash
python manage.py shell
>>> from django.urls import get_resolver
>>> [str(p.pattern) for p in get_resolver().url_patterns]
```

---

## Summary

**Immediate Action Required:**
1. Add `/api/v1/auth/verify-otp/` endpoint to Django backend
2. Add `/api/v1/auth/resend-otp/` endpoint to Django backend
3. Ensure `/api/v1/auth/login/` endpoint exists
4. Test all endpoints using provided scripts

The Flutter app is **correctly implemented** ✅. All issues are on the Django backend side.
