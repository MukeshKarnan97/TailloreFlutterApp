# Quick Start: Django Backend + Local DB Integration

## What Was Created

### 1. **HybridAuthService** (`lib/data/services/hybrid_auth_service.dart`)
   - Main service combining Django backend + local SQLite database
   - Handles registration, OTP verification, login, profile updates
   - Automatically syncs data to local DB at the right time

### 2. **Updated API Models** (`lib/data/models/account/auth_models.dart`)
   - Added `VerifyOTPRequest` and `VerifyOTPResponse`
   - Added `ResendOTPRequest`
   - Updated `ResetPasswordRequest` to use OTP

### 3. **Updated API Service** (`lib/data/services/accounts_api_service.dart`)
   - Added `verifyOTP()` method
   - Added `resendOTP()` method
   - Added `checkEmailExists()` method
   - Added `requestPasswordReset()` method

### 4. **Updated API Config** (`lib/core/config/api_config.dart`)
   - Added OTP-related endpoints
   - Added email check endpoint

## How It Works

### The Flow:

```
1. REGISTER → Django creates user (INACTIVE) + Sends OTP
   ❌ NOT in local DB yet

2. VERIFY OTP → Django activates user
   ✅ NOW insert into local DB

3. LOGIN → Django validates credentials
   ✅ Sync to local DB

4. UPDATE PROFILE → Django updates data
   ✅ Sync changes to local DB
```

## Immediate Next Steps

### Step 1: Update Your Registration Screen

Find your signup screen (probably `lib/features/auth/screens/signup_screen.dart` or similar):

**Replace this:**
```dart
final AuthService _authService = AuthService();
```

**With this:**
```dart
final HybridAuthService _authService = HybridAuthService();
```

**Then update the registration handler:**
```dart
Future<void> _handleRegistration() async {
  try {
    // Register with Django backend (user inactive, no local DB yet)
    final response = await _authService.registerWithBackend(
      name: _nameController.text.trim(),
      shopName: _shopNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      passwordConfirm: _confirmPasswordController.text,
      address: _addressController.text.trim(),
    );
    
    // Navigate to OTP screen
    Navigator.pushNamed(
      context,
      '/otp-verification',
      arguments: {
        'email': _emailController.text.trim(),
      },
    );
  } catch (e) {
    // Show error
  }
}
```

### Step 2: Update Your OTP Verification Screen

You already have `lib/features/auth/screens/otp_screen.dart`. Update the verify method:

**Replace this:**
```dart
final isValid = await _authService.verifyOTP(otp, widget.email);
```

**With this:**
```dart
final HybridAuthService _hybridAuthService = HybridAuthService();

Future<void> _verifyOTP() async {
  final otp = _pin1Controller.text + _pin2Controller.text + 
               _pin3Controller.text + _pin4Controller.text;
  
  try {
    setState(() => _isLoading = true);
    
    // This verifies with Django AND inserts into local DB
    final success = await _hybridAuthService.verifyOTPAndActivate(
      email: widget.email,
      otpCode: otp,
    );
    
    if (success) {
      // User is now activated AND in local database
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
        (route) => false,
      );
    }
  } catch (e) {
    setState(() => _errorMessage = 'Invalid OTP');
  } finally {
    setState(() => _isLoading = false);
  }
}
```

### Step 3: Update Your Login Screen

Find your signin screen and update it:

**Replace AuthService with HybridAuthService:**
```dart
final HybridAuthService _authService = HybridAuthService();

Future<void> _handleLogin() async {
  try {
    setState(() => _isLoading = true);
    
    // Login with Django and sync to local DB
    final tailor = await _authService.loginWithBackend(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    
    // User authenticated and synced to local DB
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/dashboard',
      (route) => false,
    );
  } catch (e) {
    // Show error
  } finally {
    setState(() => _isLoading = false);
  }
}
```

## Test Your Implementation

### 1. Start Django Backend
```powershell
cd C:\Users\mukes\Videos\Android_Dev\Devlopment\TailerBackend\tailor_project
python manage.py runserver
```

### 2. Start Flutter App
```powershell
cd C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app
flutter run
```

### 3. Test Registration Flow
1. Fill registration form
2. Submit → Check Django logs (user created)
3. Enter OTP from email
4. Verify → Check local DB:
   ```sql
   SELECT * FROM tailor WHERE email = 'your@email.com';
   ```
   Should show your user data ✅

### 4. Test Login Flow
1. Enter credentials
2. Login → User data should sync to local DB
3. Check local DB again - data should be updated

## Verify Local Database Insertion

### Option 1: Use SQLite Viewer Extension (VS Code)
1. Install "SQLite Viewer" extension
2. Find your database file (usually in app data directory)
3. Open and view `tailor` table

### Option 2: Use Command Line
```powershell
# Find your database location (check logs for path)
sqlite3 "path/to/database.db"

# Run query
SELECT * FROM tailor;

# Check specific user
SELECT * FROM tailor WHERE email = 'test@example.com';

# Exit
.quit
```

### Option 3: Add Debug Logging
Add this to your `hybrid_auth_service.dart` after sync:
```dart
// After _syncTailorToLocalDB(tailor)
final check = await _dbService.select(
  'tailor',
  where: 'email = ?',
  whereArgs: [tailor.email],
);
debugPrint('✅ Verified in local DB: ${check.isNotEmpty}');
```

## Expected Console Output

When everything works correctly, you should see:

```
✅ Registration:
I/flutter: [HybridAuth] Starting backend registration for: user@example.com
I/flutter: [HybridAuth] Backend registration successful, awaiting OTP verification

✅ OTP Verification:
I/flutter: [HybridAuth] Verifying OTP for: user@example.com
I/flutter: [HybridAuth] OTP verified successfully, user activated in backend
I/flutter: [LocalDatabaseService] Inserting new tailor: John Doe (user@example.com)
I/flutter: [HybridAuth] User data synced to local DB successfully

✅ Login:
I/flutter: [HybridAuth] Starting backend login for: user@example.com
I/flutter: [HybridAuth] Login successful and synced to local DB
```

## Common Import Statements You'll Need

Add these imports to your screens:

```dart
import 'package:tailer_app/data/services/hybrid_auth_service.dart';
import 'package:tailer_app/core/exceptions/auth_exceptions.dart';
```

## Django Backend Checklist

Make sure your Django backend has these endpoints working:

- [ ] `POST /api/v1/accounts/auth/register/` - Register user
- [ ] `POST /api/v1/accounts/auth/verify-otp/` - Verify OTP and activate
- [ ] `POST /api/v1/accounts/auth/login/` - Login user
- [ ] `POST /api/v1/accounts/auth/resend-otp/` - Resend OTP
- [ ] `PATCH /api/v1/accounts/users/me/` - Update profile

## Key Points to Remember

1. **Registration does NOT insert into local DB** - Only after OTP verification
2. **OTP verification triggers local DB insert** - User is activated + synced
3. **Login always syncs to local DB** - Keeps data fresh
4. **Profile updates sync immediately** - Backend first, then local DB
5. **Logout keeps local data** - Only clears tokens

## What's Different from Before

### Old Way (Local Only):
```dart
// Stored everything locally, no backend
await _authService.signUpNewTailor(...);
await _dbService.insertTailor(tailor);
```

### New Way (Hybrid):
```dart
// Register with backend first
await _hybridAuthService.registerWithBackend(...);
// OTP verification inserts into local DB
await _hybridAuthService.verifyOTPAndActivate(...);
```

## Troubleshooting

### Issue: "User already exists" error during registration
**Solution:** User might be in Django but not activated. Try login instead.

### Issue: OTP verification fails
**Solution:** 
- Check Django logs for OTP sent
- Check email for OTP code
- Make sure OTP hasn't expired (10 minutes)

### Issue: User not in local DB after login
**Solution:**
- Check `_syncTailorToLocalDB()` is being called
- Look for errors in console logs
- Verify database path is correct

### Issue: Network errors
**Solution:**
- Make sure Django is running at `http://127.0.0.1:8000`
- Check `api_config.dart` has correct base URL
- Test endpoint in Postman first

## Need More Help?

See the full documentation in:
- `DJANGO_LOCAL_DB_INTEGRATION.md` - Complete implementation guide
- `HYBRID_AUTH_IMPLEMENTATION_COMPLETE.md` - Detailed authentication flow
- `DJANGO_AUTH_COMPLETE_STRUCTURE.md` - Django backend structure

## Summary

You now have:
✅ Django backend handling all authentication
✅ OTP verification via email
✅ JWT token management
✅ Automatic local database synchronization
✅ Offline access to user data
✅ Profile update synchronization

**The key difference:** Local database is synchronized AFTER backend operations, not before. Backend is the source of truth.
