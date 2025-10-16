# API Configuration Summary

## ✅ Updated Configuration

### Base URL
```
http://192.168.0.11:8000
```

### API Endpoints

#### Registration Endpoint (Verified in Postman ✅)
```
POST http://192.168.0.11:8000/api/v1/auth/register/
```

**Full endpoint paths configured:**
- Register: `/auth/register/`
- Login: `/auth/login/`
- Verify OTP: `/auth/verify-otp/`
- Resend OTP: `/auth/resend-otp/`
- Check Email: `/auth/check-email/`
- Forgot Password: `/auth/forgot-password/`
- Reset Password: `/auth/reset-password/`

## 🔄 Data Flow for Registration

### Step 1: User Submits Form
```dart
// User fills signup form
Name: "John Doe"
Shop Name: "John's Tailoring"
Email: "john@example.com"
Phone: "+1234567890"
Password: "Password123"
```

### Step 2: Flutter Sends to Django Backend
```http
POST http://192.168.0.11:8000/api/v1/auth/register/
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "Password123",
  "password_confirm": "Password123",
  "name": "John Doe",
  "shop_name": "John's Tailoring",
  "phone": "+1234567890",
  "address": "",
  "auth_provider": "email"
}
```

### Step 3: Django Backend Response
```json
{
  "user": {
    "id": "MAT1234567",
    "unique_id": "MAT1234567",
    "email": "john@example.com",
    "name": "John Doe",
    "shop_name": "John's Tailoring",
    "phone": "+1234567890",
    "address": "",
    "auth_provider": "email",
    "is_active": false,
    "created_at": "2025-10-14T10:30:00Z",
    "updated_at": "2025-10-14T10:30:00Z"
  },
  "tokens": {
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  }
}
```

**At this point:**
- ✅ User created in Django backend (inactive)
- ✅ JWT tokens saved in FlutterSecureStorage
- ✅ OTP sent to user's email
- ❌ **NOT inserted into local SQLite database yet**

### Step 4: User Enters OTP
```dart
// User receives OTP via email and enters it
OTP: "123456"
```

### Step 5: Flutter Verifies OTP with Backend
```http
POST http://192.168.0.11:8000/api/v1/auth/verify-otp/
Content-Type: application/json

{
  "email": "john@example.com",
  "otp_code": "123456",
  "otp_type": "registration"
}
```

### Step 6: Django Activates User and Responds
```json
{
  "success": true,
  "message": "OTP verified successfully. Account activated.",
  "user": {
    "id": "MAT1234567",
    "unique_id": "MAT1234567",
    "email": "john@example.com",
    "name": "John Doe",
    "shop_name": "John's Tailoring",
    "phone": "+1234567890",
    "address": "",
    "auth_provider": "email",
    "is_active": true,  // ✅ NOW ACTIVATED
    "created_at": "2025-10-14T10:30:00Z",
    "updated_at": "2025-10-14T10:35:00Z"
  }
}
```

### Step 7: Flutter Inserts into Local DB
```dart
// ONLY NOW insert into local SQLite database
await _dbService.insertTailor(response.user);
```

**Final result:**
- ✅ User activated in Django backend
- ✅ User data inserted into local SQLite database
- ✅ Ready to use the app

## 🎯 Key Points

### ✅ Correct Flow
1. **Register** → Backend creates user (inactive) + sends OTP
2. **Wait** → User checks email for OTP
3. **Verify OTP** → Backend activates user
4. **Insert Local DB** → ONLY after successful OTP verification
5. **Login** → User can now login

### ❌ What Does NOT Happen
- ❌ Local DB insertion during registration
- ❌ Local DB insertion before OTP verification
- ❌ User activation without OTP verification

## 🔧 Implementation Status

### Files Updated:
1. ✅ `api_config.dart` - Updated endpoints to match Django URLs
2. ✅ `hybrid_auth_service.dart` - Implements delayed local DB insertion
3. ✅ `accounts_api_service.dart` - API calls to Django backend
4. ✅ `auth_models.dart` - Request/response models

### Configuration:
```dart
// Base URL
developmentBaseUrl = 'http://192.168.0.11:8000'

// API Prefix
apiPrefix = '/api/v1'

// Full Registration URL
http://192.168.0.11:8000/api/v1/auth/register/
```

## 🧪 Testing Checklist

- [x] Postman test successful for registration endpoint
- [ ] Flutter app sends registration request
- [ ] Django backend creates user (check Django admin)
- [ ] OTP email sent successfully
- [ ] JWT tokens saved in FlutterSecureStorage
- [ ] Local DB empty (check with SQLite viewer)
- [ ] User enters OTP
- [ ] Django activates user
- [ ] Local DB now contains user (check with SQLite viewer)
- [ ] User can login

## 📊 Database Verification

### Check Local SQLite Database:
```sql
-- Before OTP verification - should be EMPTY
SELECT * FROM tailor WHERE email = 'john@example.com';
-- Result: 0 rows

-- After OTP verification - should have 1 row
SELECT * FROM tailor WHERE email = 'john@example.com';
-- Result: 1 row with all user data
```

### Check Django Backend:
```python
# Django shell
from accounts.models import Tailor
tailor = Tailor.objects.get(email='john@example.com')
print(f"Active: {tailor.is_active}")  # Should be True after OTP
```

## 🚀 Next Steps

1. **Update signup_screen.dart** to use `HybridAuthService`
2. **Update otp_screen.dart** to call `verifyOTPAndActivate()`
3. **Test complete flow** from registration to login
4. **Verify local DB** is empty until OTP verification
5. **Verify local DB** contains data after OTP verification

## 📝 Important Notes

- **Backend is source of truth** - All authentication happens in Django
- **Local DB is cache** - Synced only after successful backend operations
- **OTP is mandatory** - User cannot use app until email is verified
- **Tokens are secure** - Stored in FlutterSecureStorage (encrypted)
- **Offline access** - Local DB provides profile data when offline
