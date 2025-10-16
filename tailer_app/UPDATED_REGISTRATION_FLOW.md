# Updated Registration Flow - API First Approach

## 🔄 New Flow Summary

### Step 1: Sign Up (Registration)
```
User fills form → Call API → API creates user in Django → API returns user data → 
Insert into local DB → Navigate to OTP screen
```

### Step 2: OTP Verification
```
User enters OTP → Call API → API verifies OTP → API activates user → 
Update local DB (activation status) → Navigate to dashboard
```

---

## 📊 Detailed Flow

### 1️⃣ SIGNUP - Call API and Insert into Local DB

**User Action:**
```
Fills signup form:
- Name: "John Doe"
- Shop Name: "John's Tailoring"
- Email: "john@example.com"
- Phone: "+1234567890"
- Password: "Password123"
- Confirm Password: "Password123"
```

**Flutter Sends to Django:**
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

**Django Backend:**
```python
# 1. Creates user in database
# 2. Generates OTP
# 3. Sends OTP via email (backend handles this)
# 4. Generates JWT tokens
# 5. Returns response
```

**Django Returns:**
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

**Flutter Actions:**
```dart
1. Save tokens to FlutterSecureStorage ✅
2. Insert user data into local SQLite database ✅
3. Navigate to OTP verification screen ✅
```

**Local SQLite Database After Step 1:**
```sql
SELECT * FROM tailor WHERE email = 'john@example.com';

Result:
id: MAT1234567
email: john@example.com
name: John Doe
shop_name: John's Tailoring
is_active: 0  -- Not activated yet
```

---

### 2️⃣ OTP VERIFICATION - Verify with API Only

**User Action:**
```
Receives OTP via email (sent by Django backend)
Enters OTP: "123456"
```

**Flutter Sends to Django:**
```http
POST http://192.168.0.11:8000/api/v1/auth/verify-otp/
Content-Type: application/json

{
  "email": "john@example.com",
  "otp_code": "123456",
  "otp_type": "registration"
}
```

**Django Backend:**
```python
# 1. Verifies OTP code
# 2. Activates user (sets is_active = True)
# 3. Returns updated user data
```

**Django Returns:**
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

**Flutter Actions:**
```dart
1. Update user in local SQLite database (activation status) ✅
2. Set current user in memory ✅
3. Navigate to dashboard ✅
```

**Local SQLite Database After Step 2:**
```sql
SELECT * FROM tailor WHERE email = 'john@example.com';

Result:
id: MAT1234567
email: john@example.com
name: John Doe
shop_name: John's Tailoring
is_active: 1  -- ✅ NOW ACTIVATED
```

---

## 🎯 Key Differences from Previous Flow

### ❌ OLD FLOW (Wrong):
```
1. Signup → API creates user → NO local DB insert
2. OTP verify → API activates → INSERT into local DB
```

### ✅ NEW FLOW (Correct):
```
1. Signup → API creates user → ✅ INSERT into local DB immediately
2. OTP verify → API activates → ✅ UPDATE local DB (activation status only)
```

---

## 📝 Code Implementation

### HybridAuthService - registerWithBackend()

```dart
Future<RegisterResponse> registerWithBackend({
  required String name,
  required String shopName,
  required String email,
  required String phone,
  required String password,
  required String passwordConfirm,
  String address = '',
}) async {
  // Call Django API
  final response = await _apiService.register(request);
  
  // ✅ INSERT into local DB immediately after API returns
  await _syncTailorToLocalDB(response.user);
  
  return response;
}
```

### HybridAuthService - verifyOTPAndActivate()

```dart
Future<bool> verifyOTPAndActivate({
  required String email,
  required String otpCode,
}) async {
  // Call Django API to verify OTP
  final response = await _apiService.verifyOTP(
    email: email,
    otpCode: otpCode,
  );

  if (response.success) {
    // ✅ UPDATE local DB (user already exists, just update activation)
    await _syncTailorToLocalDB(response.user);
    _currentTailor = response.user;
    return true;
  }
  return false;
}
```

---

## 🧪 Testing Steps

### Test 1: Registration
```bash
1. Fill signup form
2. Click "Sign Up"
3. Check Django logs → User created ✅
4. Check email → OTP received ✅
5. Check local DB → User exists with is_active=0 ✅
6. Check screen → Navigated to OTP screen ✅
```

### Test 2: OTP Verification
```bash
1. Enter OTP from email
2. Click "Verify"
3. Check Django logs → User activated ✅
4. Check local DB → User updated with is_active=1 ✅
5. Check screen → Navigated to dashboard ✅
```

---

## 🔍 Database Verification

### After Registration (Before OTP):
```sql
-- Django Database
SELECT id, email, is_active FROM accounts_tailor WHERE email = 'john@example.com';
Result: MAT1234567 | john@example.com | false

-- Local SQLite Database
SELECT id, email, is_deleted FROM tailor WHERE email = 'john@example.com';
Result: MAT1234567 | john@example.com | 0
```

### After OTP Verification:
```sql
-- Django Database
SELECT id, email, is_active FROM accounts_tailor WHERE email = 'john@example.com';
Result: MAT1234567 | john@example.com | true ✅

-- Local SQLite Database  
SELECT id, email, is_deleted FROM tailor WHERE email = 'john@example.com';
Result: MAT1234567 | john@example.com | 0 ✅
```

---

## ✅ Summary

| Action | API Call | Django Action | Local DB Action | OTP Action |
|--------|----------|---------------|----------------|------------|
| **Signup** | POST /auth/register/ | Create user (inactive) | ✅ INSERT user | Backend sends OTP email |
| **Verify OTP** | POST /auth/verify-otp/ | Activate user | ✅ UPDATE user | Backend verifies OTP |
| **Login** | POST /auth/login/ | Validate credentials | ✅ UPDATE/INSERT user | N/A |

**Key Points:**
- ✅ API handles ALL business logic (user creation, OTP generation, OTP verification)
- ✅ Local DB is immediately synced after API returns data
- ✅ OTP is generated and sent by Django backend (not Flutter)
- ✅ OTP verification screen just sends code to API for verification
- ✅ No OTP generation in Flutter code
