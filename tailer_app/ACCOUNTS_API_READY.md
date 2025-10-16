# Flutter API Integration - Accounts Module

**Status:** ✅ COMPLETE & READY FOR USE  
**Module:** Accounts (Authentication & User Management)  
**Last Updated:** October 13, 2025

---

## 📦 **What's Been Implemented**

### ✅ Core Services
- `api_config.dart` - API configuration, endpoints, constants
- `api_client.dart` - HTTP client with Dio, interceptors, auto-token-refresh
- `token_storage_service.dart` - Secure JWT token storage

### ✅ Data Models
- `user_model.dart` - User entity
- `user_preference_model.dart` - User preferences
- `auth_models.dart` - Login/Register/Password request/response models

### ✅ API Service
- `accounts_api_service.dart` - Complete accounts API with 15+ endpoints

### ✅ Dependencies Added
```yaml
dio: ^5.7.0                      # HTTP client  
equatable: ^2.0.7                # Value equality
flutter_secure_storage: ^9.2.2  # Already present
```

---

## 🚀 **Quick Start**

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure API URL

Edit `lib/core/config/api_config.dart` line 12:

```dart
// For Android Emulator
static const String developmentBaseUrl = 'http://10.0.2.2:8000';

// For iOS Simulator  
static const String developmentBaseUrl = 'http://localhost:8000';

// For Physical Device (Replace with your PC's IP)
static const String developmentBaseUrl = 'http://192.168.1.100:8000';
```

### 3. Use in Your Code

```dart
import 'package:tailer_app/data/services/accounts_api_service.dart';
import 'package:tailer_app/data/models/account/auth_models.dart';

// Initialize service
final accountsApi = AccountsApiService();

// Register
final registerRequest = RegisterRequest(
  email: 'user@example.com',
  password: 'SecurePass123!',
  passwordConfirm: 'SecurePass123!',
  firstName: 'John',
  lastName: 'Doe',
  phone: '+91 9876543210',
  userType: 'tailor',
);

try {
  final response = await accountsApi.register(registerRequest);
  print('Registered: ${response.user.email}');
  // Tokens are automatically saved
} on ApiException catch (e) {
  print('Error: ${e.message}');
}

// Login
final loginRequest = LoginRequest(
  email: 'user@example.com',
  password: 'SecurePass123!',
);

final loginResponse = await accountsApi.login(loginRequest);
print('Logged in: ${loginResponse.user.fullName}');

// Get current user
final user = await accountsApi.getCurrentUser();
print('User: ${user.fullName} (${user.email})');

// Update user
final updateRequest = UpdateUserRequest(
  firstName: 'Jane',
  phone: '+91 9999999999',
);
final updatedUser = await accountsApi.updateCurrentUser(updateRequest);

// Change password
final changePasswordRequest = ChangePasswordRequest(
  oldPassword: 'OldPass123!',
  newPassword: 'NewPass123!',
  newPasswordConfirm: 'NewPass123!',
);
await accountsApi.changePassword(changePasswordRequest);

// Get preferences
final preferences = await accountsApi.getUserPreferences();
print('Theme: ${preferences.theme}, Language: ${preferences.language}');

// Logout
await accountsApi.logout();
```

---

## 📚 **Available API Methods**

### Authentication
- ✅ `register(RegisterRequest)` → RegisterResponse
- ✅ `login(LoginRequest)` → LoginResponse  
- ✅ `logout()` → void
- ✅ `refreshToken()` → RefreshTokenResponse
- ✅ `verifyEmail(EmailVerificationRequest)` → String
- ✅ `resendEmailVerification()` → String

### User Management
- ✅ `getCurrentUser()` → User
- ✅ `updateCurrentUser(UpdateUserRequest)` → User
- ✅ `deleteAccount()` → void

### Password Management
- ✅ `changePassword(ChangePasswordRequest)` → String
- ✅ `forgotPassword(ForgotPasswordRequest)` → String
- ✅ `resetPassword(ResetPasswordRequest)` → String

### Preferences
- ✅ `getUserPreferences()` → UserPreference
- ✅ `updateUserPreferences(UserPreference)` → UserPreference

### Utility
- ✅ `isAuthenticated()` → bool
- ✅ `getUserId()` → String?
- ✅ `getUserEmail()` → String?
- ✅ `getUserType()` → String?

---

## 🔐 **Token Management (Automatic)**

Tokens are automatically:
- ✅ Saved securely after login/register (flutter_secure_storage)
- ✅ Attached to all API requests (Bearer token)
- ✅ Refreshed when expired (401 error → refresh → retry)
- ✅ Cleared on logout

You don't need to manually handle tokens!

---

## ⚠️ **Error Handling**

```dart
try {
  final response = await accountsApi.login(request);
} on ApiException catch (e) {
  // API errors (400, 401, 404, 500)
  print('Error: ${e.message}');
  print('Status Code: ${e.statusCode}');
  
  if (e.statusCode == 401) {
    // Invalid credentials
  } else if (e.statusCode == 422) {
    // Validation error
    print('Errors: ${e.data}');
  }
} on SocketException catch (e) {
  // No internet
  print('Network error');
} catch (e) {
  // Other errors
  print('Unknown error: $e');
}
```

---

## 🗂️ **File Locations**

```
lib/
├── core/
│   ├── config/
│   │   └── api_config.dart              ✅ API config & endpoints
│   └── services/
│       ├── api_client.dart              ✅ HTTP client
│       └── token_storage_service.dart   ✅ Token storage
│
├── data/
│   ├── models/
│   │   └── account/
│   │       ├── user_model.dart          ✅ User model
│   │       ├── user_preference_model.dart ✅ Preferences
│   │       └── auth_models.dart         ✅ Auth models
│   └── services/
│       └── accounts_api_service.dart    ✅ Accounts API
│
└── pubspec.yaml                         ✅ Dependencies added
```

---

## 🔧 **Configuration Checklist**

- [x] Dependencies added to `pubspec.yaml`
- [x] API base URL configured in `api_config.dart`
- [x] All models created
- [x] API client with interceptors
- [x] Token storage service
- [x] Accounts API service with 15+ endpoints
- [x] Error handling
- [x] Auto token refresh
- [ ] Django backend running
- [ ] Test API endpoints

---

## 🧪 **Testing**

### 1. Start Django Backend
```bash
cd tailor_backend
python manage.py runserver
```

### 2. Test Registration
```dart
final accountsApi = AccountsApiService();

final request = RegisterRequest(
  email: 'test@example.com',
  password: 'Test123!@#',
  passwordConfirm: 'Test123!@#',
  firstName: 'Test',
  lastName: 'User',
  phone: '+91 9876543210',
);

try {
  final response = await accountsApi.register(request);
  print('✅ Success: ${response.user.email}');
} catch (e) {
  print('❌ Error: $e');
}
```

### 3. Test Login
```dart
final request = LoginRequest(
  email: 'test@example.com',
  password: 'Test123!@#',
);

final response = await accountsApi.login(request);
print('✅ Logged in: ${response.user.fullName}');
```

---

## 📝 **Next Steps**

1. ✅ **Accounts Module** - COMPLETE
2. ⏳ **Integrate with Auth Provider/State Management**
3. ⏳ **Update SignIn/SignUp screens to use API**
4. ⏳ **Implement Customers API**
5. ⏳ **Implement Orders API**
6. ⏳ **Implement Measurements API**

---

## 💡 **Tips**

### Tip 1: Use with Provider
```dart
class AuthProvider with ChangeNotifier {
  final AccountsApiService _accountsApi = AccountsApiService();
  User? _user;
  
  Future<void> login(String email, String password) async {
    final request = LoginRequest(email: email, password: password);
    final response = await _accountsApi.login(request);
    _user = response.user;
    notifyListeners();
  }
}
```

### Tip 2: Check Auth on App Start
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final accountsApi = AccountsApiService();
  final isAuth = await accountsApi.isAuthenticated();
  
  runApp(MyApp(isAuthenticated: isAuth));
}
```

### Tip 3: Handle Network Errors
```dart
try {
  await accountsApi.login(request);
} on SocketException {
  showSnackBar('No internet connection');
} on ApiException catch (e) {
  showSnackBar(e.message);
}
```

---

## ✅ **Ready to Use!**

All accounts API endpoints are implemented and ready to use. Just run `flutter pub get` and start integrating with your screens!

**Need help?** Check the full guide in `FLUTTER_API_INTEGRATION_GUIDE.md` (to be created with detailed examples).

---

**Status:** 🎉 **IMPLEMENTATION COMPLETE**
