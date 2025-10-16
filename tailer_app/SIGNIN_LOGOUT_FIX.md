# Sign-In and Logout Fix Guide

## Issues Identified

### 1. Sign-In Issue: "Invalid password hash format"
**Root Cause**: 
- During registration, the backend API returns user data WITHOUT the `password_hash` field (for security)
- The `Tailor.fromMap()` defaults missing `password_hash` to empty string `''`
- User is synced to local DB with empty `password_hash`
- During login, the hashed password is compared against empty string, which fails

**Error Location**: `hybrid_auth_service.dart` line 232
```dart
where: 'email = ? AND password_hash = ? AND is_deleted = 0',
whereArgs: [email.trim(), passwordHash], // passwordHash never matches empty string
```

### 2. Logout Issue: Method doesn't exist
**Root Cause**:
- `logout()` calls `_apiService.logout()` which doesn't exist in ApiService
- For local-first authentication, we don't need to call backend logout
- Just need to clear local tokens and reset state

**Error Location**: `hybrid_auth_service.dart` line 316
```dart
await _apiService.logout(); // This method doesn't exist
```

## Solution

### Fix 1: Hash Password Locally During Registration

**File**: `lib/data/services/hybrid_auth_service.dart`

**Method**: `registerWithBackend()` (around line 103)

**Change**: Before syncing to local DB, add the password hash to the user object

```dart
// OLD CODE (line 103):
await _syncTailorToLocalDB(response.user);

// NEW CODE:
// Hash the password locally and add it to user data before syncing
final hashedPassword = _hashPassword(password);
final userWithHash = response.user.copyWith(passwordHash: hashedPassword);
await _syncTailorToLocalDB(userWithHash);
```

### Fix 2: Update Logout Method for Local-First Auth

**File**: `lib/data/services/hybrid_auth_service.dart`

**Method**: `logout()` (around line 312-327)

**Replace entire method**:

```dart
/// Logout and clear tokens (keeps local DB data)
Future<void> logout() async {
  try {
    Logger.info('HybridAuth', 'Logging out user');
    
    // Clear all tokens and session data from secure storage
    await _tokenStorage.clearTokens();
    await _tokenStorage.clearUserId();
    await _tokenStorage.clearUserEmail();
    await _tokenStorage.clearUserType();
    await _tokenStorage.saveLoginState(false);
    
    // Clear current user from memory
    _currentTailor = null;
    
    // Note: We keep local DB data for offline access
    // Only clear tokens and session
    
    Logger.info('HybridAuth', 'Logout successful - tokens cleared');
  } catch (e) {
    Logger.error('HybridAuth', 'Logout error', error: e);
    rethrow;
  }
}
```

### Fix 3: Verify TokenStorage Has Clear Methods

**File**: `lib/data/services/token_storage.dart`

Ensure these methods exist:
- `clearTokens()` - Remove access and refresh tokens
- `clearUserId()` - Remove user ID
- `clearUserEmail()` - Remove email
- `clearUserType()` - Remove user type
- `saveLoginState(false)` - Set logged out state

## Implementation Steps

### Step 1: Apply Password Hash Fix
```bash
# Edit hybrid_auth_service.dart
# Update line 103 in registerWithBackend() method
```

### Step 2: Apply Logout Fix
```bash
# Edit hybrid_auth_service.dart
# Replace logout() method (lines 312-327)
```

### Step 3: Test Sign-In Flow
1. **Clear app data** (to start fresh):
   ```bash
   flutter run
   # In VS Code debug console: Hot restart (r)
   # Or uninstall app from device
   ```

2. **Register a new user**:
   - Use email: test@example.com
   - Password: Test123!
   - Complete OTP verification

3. **Test sign-in**:
   - Use same credentials
   - Should successfully authenticate

### Step 4: Test Logout Flow
1. After successful login, click logout button
2. Verify:
   - User is redirected to sign-in screen
   - No errors in console
   - Cannot access protected routes
   - Can sign in again with same credentials

## Testing After Fix

### Verify Database Has Password Hash
```bash
# Run this script after registration
flutter run lib/debug_database.dart
```

In debug console:
```sql
SELECT email, LENGTH(password_hash) as hash_length, is_active FROM tailor;
```

Expected output:
```
mukesh.dmc97@gmail.com | 64 | 1
```
(SHA256 produces 64 character hex string)

### Verify Sign-In Works
Check logs for:
```
[HybridAuth] Starting local login for: mukesh.dmc97@gmail.com
[HybridAuth] User found and active in local DB
[HybridAuth] Local login successful for: mukesh.dmc97@gmail.com
```

### Verify Logout Works
Check logs for:
```
[HybridAuth] Logging out user
[HybridAuth] Logout successful - tokens cleared
```

## Alternative: Update Existing Users

If you want to fix existing users without re-registering, create a migration script:

**File**: `lib/fix_password_hashes.dart`

```dart
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'services/local_db_service.dart';

Future<void> fixPasswordHashes() async {
  final dbService = LocalDbService();
  await dbService.initDatabase();
  
  print('⚠️  This will reset ALL user passwords to: "Temp123!"');
  print('Users will need to be notified of this temporary password.');
  
  // Set all users to temporary password
  final tempPassword = 'Temp123!';
  final tempHash = sha256.convert(utf8.encode(tempPassword)).toString();
  
  await dbService.database.rawUpdate('''
    UPDATE tailor 
    SET password_hash = ?, 
        updated_at = ?
    WHERE password_hash = '' OR password_hash IS NULL
  ''', [tempHash, DateTime.now().toIso8601String()]);
  
  print('✅ Password hashes updated. Temporary password: $tempPassword');
}

void main() async {
  await fixPasswordHashes();
}
```

## Root Cause Analysis

### Why This Happened

1. **Security Best Practice**: Backend doesn't return password hashes in API responses (correct behavior)
2. **Missing Client-Side Hashing**: App didn't hash passwords before local storage
3. **Assumption**: Code assumed password_hash would come from backend
4. **Local-First Gap**: Transition to local-first auth didn't account for password handling

### Prevention

- Always hash sensitive data client-side before local storage
- Never rely on backend to provide password hashes
- Test full authentication flow (register → verify → logout → login)
- Add validation to ensure password_hash is not empty before storing

## Related Files

- `lib/data/services/hybrid_auth_service.dart` - Main authentication service
- `lib/data/services/token_storage.dart` - Secure token management
- `lib/data/models/tailor_model.dart` - User model with password_hash field
- `lib/data/services/local_db_service.dart` - Local database operations

## Status

- [x] Issue identified
- [x] Root cause analyzed
- [ ] Password hash fix applied
- [ ] Logout fix applied
- [ ] Testing completed
- [ ] Verified in production

Last Updated: 2025-01-15
