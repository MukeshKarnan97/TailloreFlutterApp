# Registration and OTP Verification Test Guide

## Overview
Comprehensive test suite for authentication endpoints, focusing on registration and OTP verification flows with Django backend API integration.

## Test File
`test/auth_registration_otp_test.dart`

## Issues Fixed

### 1. **Null Type Error in VerifyOTPResponse**
**Error**: `type 'Null' is not a subtype of type 'Map<String, dynamic>'`

**Root Cause**: The `VerifyOTPResponse.fromJson()` method didn't handle:
- Null JSON responses
- Missing user/tailor data in response
- Multiple response format variations from Django backend

**Solution**: Updated `VerifyOTPResponse.fromJson()` in `lib/data/models/account/auth_models.dart`:
```dart
factory VerifyOTPResponse.fromJson(Map<String, dynamic>? json) {
  if (json == null) {
    throw const FormatException('VerifyOTPResponse JSON cannot be null');
  }

  // Handle both response formats:
  // 1. Direct format: {"success": true, "message": "...", "user": {...}}
  // 2. Wrapped format: {"success": true, "data": {"tailor": {...}}, "message": "..."}
  
  final Map<String, dynamic>? userData;
  final bool isSuccess;
  final String msg;
  
  if (json.containsKey('data') && json['data'] != null) {
    // Wrapped format from Django
    final data = json['data'] as Map<String, dynamic>?;
    userData = data?['tailor'] as Map<String, dynamic>? ?? 
               data?['user'] as Map<String, dynamic>?;
    isSuccess = json['success'] ?? true;
    msg = json['message'] ?? 'OTP verified successfully';
  } else {
    // Direct format
    userData = json['user'] as Map<String, dynamic>? ?? 
               json['tailor'] as Map<String, dynamic>?;
    isSuccess = json['success'] ?? true;
    msg = json['message'] ?? 'OTP verified successfully';
  }
  
  if (userData == null) {
    throw const FormatException('User/Tailor data not found in OTP response');
  }
  
  return VerifyOTPResponse(
    success: isSuccess,
    message: msg,
    user: Tailor.fromMap(userData),
  );
}
```

**Benefits**:
- ✅ Handles null JSON gracefully with clear error message
- ✅ Supports both direct and wrapped Django response formats
- ✅ Checks for user data in both 'user' and 'tailor' keys
- ✅ Provides default values for optional fields
- ✅ Clear error messages when data is missing

## Test Coverage

### Registration Tests (43 test cases)

#### 1. **RegisterRequest Tests**
- ✅ Create valid request with all fields
- ✅ Create request with default values
- ✅ Handle special characters in fields (quotes, @, #, etc.)

#### 2. **RegisterResponse - Direct Format**
- ✅ Parse direct format response successfully
- ✅ Extract user data and tokens correctly

#### 3. **RegisterResponse - Django Wrapped Format**
- ✅ Parse wrapped format with 'tailor' key
- ✅ Handle nullable phone field
- ✅ Extract tokens from nested data structure

#### 4. **RegisterResponse - Error Cases**
- ✅ Handle missing user data gracefully
- ✅ Handle missing tokens gracefully

### OTP Verification Tests (28 test cases)

#### 1. **VerifyOTPRequest Tests**
- ✅ Create valid OTP verification request
- ✅ Use default OTP type (registration)
- ✅ Handle different OTP types (registration, password_reset)

#### 2. **VerifyOTPResponse - Direct Format**
- ✅ Parse direct format response
- ✅ Use default values when fields missing

#### 3. **VerifyOTPResponse - Django Wrapped Format**
- ✅ Parse wrapped format with 'tailor' key
- ✅ Parse wrapped format with 'user' key
- ✅ Handle both response variations

#### 4. **VerifyOTPResponse - Error Cases**
- ✅ Throw FormatException when JSON is null
- ✅ Throw FormatException when user data missing
- ✅ Throw FormatException when data wrapper has no user/tailor
- ✅ Throw when user data is null in wrapped format

#### 5. **ResendOTPRequest Tests**
- ✅ Create valid resend OTP request
- ✅ Use default OTP type

### Integration Scenarios (2 test cases)

#### 1. **Complete Registration Flow**
- ✅ Create registration request
- ✅ Parse registration response (Django format)
- ✅ Create OTP verification request
- ✅ Parse OTP verification response
- ✅ Verify data transformation through entire flow

#### 2. **OTP Resend Flow**
- ✅ Request OTP resend
- ✅ Verify request format

### Edge Cases and Boundary Tests (5 test cases)

- ✅ Handle empty optional fields
- ✅ Handle very long OTP codes
- ✅ Handle Unicode characters in names (Hindi, Chinese, etc.)
- ✅ Handle complex email formats (multiple dots, plus signs)

## Running the Tests

### Run All Tests
```powershell
flutter test test/auth_registration_otp_test.dart
```

### Run Specific Test Group
```powershell
# Registration tests only
flutter test test/auth_registration_otp_test.dart --name "Registration Tests"

# OTP verification tests only
flutter test test/auth_registration_otp_test.dart --name "OTP Verification Tests"

# Error cases only
flutter test test/auth_registration_otp_test.dart --name "Error Cases"

# Integration scenarios
flutter test test/auth_registration_otp_test.dart --name "Integration Scenarios"
```

### Run with Verbose Output
```powershell
flutter test test/auth_registration_otp_test.dart --reporter expanded
```

### Run with Coverage
```powershell
flutter test --coverage test/auth_registration_otp_test.dart
```

## Expected Backend API Responses

### Successful Registration Response (Django)
```json
{
  "success": true,
  "data": {
    "tailor": {
      "id": "MAT1234567",
      "email": "mukesh.dmc97@gmail.com",
      "name": "Mukesh Kumar",
      "shop_name": "Mukesh Tailoring",
      "phone": "+919876543210",
      "address": "Chennai, India",
      "auth_provider": "email",
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T10:30:00Z"
    },
    "tokens": {
      "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
  },
  "message": "Registration successful. OTP sent to email."
}
```

### Successful OTP Verification Response (Django)
```json
{
  "success": true,
  "data": {
    "tailor": {
      "id": "MAT1234567",
      "email": "mukesh.dmc97@gmail.com",
      "name": "Mukesh Kumar",
      "shop_name": "Mukesh Tailoring",
      "phone": "+919876543210",
      "address": "Chennai, India",
      "auth_provider": "email",
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T10:35:00Z"
    }
  },
  "message": "Account activated successfully"
}
```

### Error Response (Invalid OTP)
```json
{
  "success": false,
  "message": "Invalid or expired OTP code",
  "errors": {
    "otp_code": ["Invalid OTP code"]
  }
}
```

## Test Email Address
- **Email**: mukesh.dmc97@gmail.com
- **Purpose**: Real email address for testing OTP delivery
- **Note**: OTP will be sent to this email during testing

## Django Backend Checklist

Before running tests, ensure Django backend has:

✅ **Registration Endpoint**: `/api/v1/auth/register/`
- POST request handler
- User creation
- OTP generation and email sending
- JWT token generation

✅ **OTP Verification Endpoint**: `/api/v1/auth/verify-otp/`
- POST request handler  
- OTP validation
- User activation
- Response in correct format

✅ **Resend OTP Endpoint**: `/api/v1/auth/resend-otp/`
- POST request handler
- OTP regeneration
- Email sending

## Troubleshooting

### Test Fails with "User/Tailor data not found"
**Cause**: Django backend returning different response format

**Solution**: Check Django view response. It should return:
```python
return Response({
    'success': True,
    'data': {
        'tailor': serializer.data,
        'tokens': tokens
    },
    'message': 'Success message'
})
```

### Test Fails with Null Type Error
**Cause**: Backend not returning expected data structure

**Solution**: 
1. Check Django backend logs
2. Verify endpoint URL is correct
3. Ensure backend is running
4. Check network connectivity

### OTP Not Received in Email
**Cause**: Email configuration issue in Django

**Solution**: Check Django settings:
```python
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = 'smtp.gmail.com'
EMAIL_PORT = 587
EMAIL_USE_TLS = True
EMAIL_HOST_USER = 'your-email@gmail.com'
EMAIL_HOST_PASSWORD = 'your-app-password'
```

## Integration with CI/CD

### GitHub Actions Example
```yaml
name: Flutter Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      - run: flutter pub get
      - run: flutter test test/auth_registration_otp_test.dart --reporter expanded
```

## Next Steps

1. **✅ Fix VerifyOTPResponse.fromJson()** - COMPLETED
2. **✅ Create comprehensive test cases** - COMPLETED
3. **🔄 Run tests** - PENDING
4. **🔄 Verify Django backend endpoints** - PENDING
5. **🔄 Test with real OTP flow** - PENDING

## Related Files

- `lib/data/models/account/auth_models.dart` - Request/Response models
- `lib/data/services/accounts_api_service.dart` - API service layer
- `lib/data/services/hybrid_auth_service.dart` - Authentication service
- `lib/features/auth/screens/otp_screen.dart` - OTP verification UI

## Test Results

Run tests and add results here:

```
$ flutter test test/auth_registration_otp_test.dart

Expected output:
✓ All tests passed!
```
