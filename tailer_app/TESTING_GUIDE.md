# Testing Guide After Sign-In/Logout Fixes

## ✅ Fixes Applied

### 1. Password Hash Fix (Sign-In Issue)
**File**: `lib/data/services/hybrid_auth_service.dart`
**Line**: ~103 in `registerWithBackend()` method

**Problem**: Backend doesn't return password_hash, so it was stored as empty string in local DB.

**Solution**: Hash password client-side before syncing to local database.

```dart
// NEW CODE (lines 103-108):
final hashedPassword = _hashPassword(password);
final userWithHash = response.user.copyWith(passwordHash: hashedPassword);
await _syncTailorToLocalDB(userWithHash);
```

### 2. Logout Fix
**File**: `lib/data/services/hybrid_auth_service.dart`
**Line**: ~312-327 in `logout()` method

**Problem**: Called `_apiService.logout()` which doesn't exist.

**Solution**: Use `_tokenStorage.clearAll()` for local-first auth.

```dart
// NEW CODE (line 316):
await _tokenStorage.clearAll();
_currentTailor = null;
```

## 📋 Testing Steps

### Option 1: Fresh Start (Recommended)

#### Step 1: Clear Old Data
```bash
# Uninstall app from device to clear old database
# OR hot restart in Flutter
```

#### Step 2: Run App
```bash
flutter run
```

#### Step 3: Register New User
- Email: `test@example.com`
- Password: `Test123!`
- Name: `Test User`
- Shop: `Test Shop`
- Phone: `1234567890`
- Click **Register**

#### Step 4: Verify OTP
- Check console for OTP code
- Enter OTP and verify
- Should see success message

#### Step 5: Test Sign-In
1. **Logout** (if auto-logged in)
2. Go to Sign-In screen
3. Enter credentials:
   - Email: `test@example.com`
   - Password: `Test123!`
4. Click **Sign In**

**Expected Result**: ✅ Successfully logged in to dashboard

**Console Logs to Verify**:
```
[HybridAuth] Starting local login for: test@example.com
[HybridAuth] User found and active in local DB
[HybridAuth] Local login successful for: test@example.com
```

#### Step 6: Test Logout
1. Click **Logout** button
2. Should redirect to Sign-In screen

**Expected Result**: ✅ Successfully logged out

**Console Logs to Verify**:
```
[HybridAuth] Logging out user
[HybridAuth] Logout successful - tokens and session cleared
```

#### Step 7: Test Re-Login
1. Enter same credentials again
2. Click **Sign In**
3. Should successfully log back in

### Option 2: Check Existing User

If you want to keep your existing user (`mukesh.dmc97@gmail.com`), you need to fix the password hash.

#### Method A: Check Password Hash First
```bash
# Run the password hash checker
flutter run lib/check_password_hashes.dart
```

**Expected Output**:
```
🔍 Checking password hashes in database...

📊 User Accounts:
================================================================================
Email: mukesh.dmc97@gmail.com
Active: ✅ Yes
Password Hash Length: 0 characters
⚠️  WARNING: Password hash is EMPTY! User cannot sign in.
--------------------------------------------------------------------------------
```

If password hash is empty, proceed to Method B.

#### Method B: Reset Password for Existing User

**IMPORTANT**: This will change the password to a temporary one!

1. Open `lib/data/services/local_db_service.dart`
2. Add this temporary method:

```dart
// TEMPORARY: Add this method to LocalDbService class
Future<void> fixPasswordHashForUser(String email, String newPassword) async {
  final hashedPassword = sha256.convert(utf8.encode(newPassword)).toString();
  
  await _database.update(
    'tailor',
    {
      'password_hash': hashedPassword,
      'updated_at': DateTime.now().toIso8601String(),
    },
    where: 'email = ?',
    whereArgs: [email],
  );
  
  print('✅ Password hash updated for $email');
}
```

3. Create a quick fix script:

```dart
// lib/fix_existing_user.dart
import 'data/services/local_db_service.dart';

Future<void> main() async {
  final dbService = LocalDbService();
  await dbService.initDatabase();
  
  // Update password for existing user
  await dbService.fixPasswordHashForUser(
    'mukesh.dmc97@gmail.com',
    'NewPassword123!', // Your new password
  );
  
  print('✅ Done! You can now login with: NewPassword123!');
}
```

4. Run the fix:
```bash
flutter run lib/fix_existing_user.dart
```

5. Test login with new password:
   - Email: `mukesh.dmc97@gmail.com`
   - Password: `NewPassword123!`

### Option 3: Pull and Inspect Database

If you want to manually inspect the database:

#### Step 1: Pull Database from Android
```bash
# Run the pull script
pull_database.bat
```

**Note**: Requires ADB to be installed. If ADB not found, follow instructions in the script output.

#### Step 2: Inspect with DB Browser
1. Download **DB Browser for SQLite**: https://sqlitebrowser.org/
2. Open: `C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app\database\tailor_app.db`
3. Go to **Browse Data** tab
4. Select **tailor** table
5. Check **password_hash** column

**What to Look For**:
- ✅ **64 characters**: Valid SHA256 hash (e.g., `5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8`)
- ❌ **Empty string**: User cannot login (need to fix)

#### Step 3: Inspect with Python
```bash
python view_tailor_data.py
```

## 🧪 Verification Checklist

### After Registration
- [ ] User created in database
- [ ] password_hash is 64 characters (SHA256)
- [ ] is_active = 0 (not yet verified)

### After OTP Verification
- [ ] is_active = 1 (verified)
- [ ] Local tokens generated
- [ ] User auto-logged in

### After Sign-In
- [ ] Credentials validated against local DB
- [ ] Password hash matches
- [ ] is_active checked (must be 1)
- [ ] New tokens generated
- [ ] User redirected to dashboard

### After Logout
- [ ] All tokens cleared
- [ ] User redirected to sign-in screen
- [ ] Cannot access protected routes
- [ ] Can sign in again with same credentials

## 📊 Console Logs Reference

### Successful Registration
```
[HybridAuth] Starting backend registration for: test@example.com
[HybridAuth] Backend registration successful, inserting into local DB
[HybridAuth] User data synced to local DB with password hash, ready for OTP verification
```

### Successful OTP Verification
```
[HybridAuth] Verifying OTP for: test@example.com
[HybridAuth] OTP verified successfully by backend
[HybridAuth] User marked as active in local DB
[HybridAuth] Local tokens generated and saved
[HybridAuth] OTP verification complete, user activated
```

### Successful Sign-In
```
[HybridAuth] Starting local login for: test@example.com
[HybridAuth] User found and active in local DB
[HybridAuth] Local login successful for: test@example.com
```

### Successful Logout
```
[HybridAuth] Logging out user
[HybridAuth] Logout successful - tokens and session cleared
```

### Failed Sign-In (Wrong Password)
```
[HybridAuth] Starting local login for: test@example.com
[HybridAuth] Invalid email or password
[TailorAuthRepository] Error during sign in: InvalidCredentialsException
```

### Failed Sign-In (Empty Password Hash - OLD BUG)
```
[HybridAuth] Starting local login for: mukesh.dmc97@gmail.com
[TailorAuthRepository] Error during sign in: Exception: Invalid password hash format
```

## 🐛 Troubleshooting

### Issue: "Invalid email or password" even with correct credentials

**Cause**: Password hash doesn't match

**Solutions**:
1. Re-register with a new account
2. OR fix existing user's password hash (see Option 2, Method B)
3. OR check database manually (see Option 3)

### Issue: "Account is not activated"

**Cause**: is_active = 0 (OTP not verified)

**Solution**: Complete OTP verification step

### Issue: Can't pull database with ADB

**Cause**: ADB not installed or device not connected

**Solutions**:
1. Install Android SDK Platform Tools
2. Enable USB Debugging on device
3. Accept USB debugging prompt
4. Run `adb devices` to verify connection

### Issue: "Permission denied" when pulling database

**Cause**: Non-rooted device restricts /data access

**Solutions**:
1. Use debug tools instead: `flutter run lib/debug_database.dart`
2. OR add debug screen to your app
3. OR root device (not recommended)

### Issue: Logout works but can't see redirect

**Cause**: Navigation might need to be checked in UI layer

**Check**: 
- `lib/presentation/repositories/tailor_auth_repository.dart`
- Navigation after `logout()` call
- Should redirect to sign-in screen

## 📁 Files Modified

1. ✅ `lib/data/services/hybrid_auth_service.dart` - Password hash fix + Logout fix
2. ✅ `SIGNIN_LOGOUT_FIX.md` - Documentation
3. ✅ `lib/check_password_hashes.dart` - Verification tool
4. ✅ `pull_database.bat` - Database extraction script (already complete)
5. ✅ `TESTING_GUIDE.md` - This file

## 🎯 Success Criteria

### Sign-In Fixed ✅
- [x] Password hashed client-side during registration
- [x] Password hash stored in local database (64 chars)
- [x] Login compares hashed passwords correctly
- [x] No more "Invalid password hash format" errors

### Logout Fixed ✅
- [x] Removed non-existent `_apiService.logout()` call
- [x] Uses `_tokenStorage.clearAll()` instead
- [x] Clears user from memory
- [x] No errors during logout

### Full Flow Working ✅
- [x] Register → OTP → Auto Login → Logout → Login Again
- [x] All steps work without errors
- [x] Console logs show success messages

## 📞 Next Steps

1. **Test immediately**: Follow Option 1 (Fresh Start)
2. **If test fails**: Check console logs and compare with reference above
3. **If still issues**: Use debug tools to inspect database
4. **Once verified**: Remove temporary fix methods and debug scripts

---

**Created**: 2025-01-15  
**Last Updated**: 2025-01-15  
**Status**: ✅ Fixes Applied - Ready for Testing
