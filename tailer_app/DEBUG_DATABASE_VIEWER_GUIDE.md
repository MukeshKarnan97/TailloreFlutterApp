# Debug Database Viewer - Quick Guide

## What is it?

A debug screen accessible from the Sign-In page that shows ALL tailor data from the local database, including:
- User details (name, email, shop name, etc.)
- Password hashes (to debug sign-in issues)
- Account status (active/inactive, deleted)
- Database information

## How to Access

### From Sign-In Screen:
1. Open the app
2. Go to Sign-In screen
3. Look for the **purple bug icon** (🐛) in the bottom-left corner
4. Tap it to open the Database Viewer

### Location:
- **File**: `lib/features/debug/database_viewer_screen.dart`
- **Access**: Floating button on `signin_screen.dart`

## Features

### 1. Database Information Header
- Database path on device
- Database version (current: 13)
- Total number of user records

### 2. User Cards
Each user is displayed in a card showing:
- **User Number**: Sequential numbering
- **Status Badges**:
  - ✅ Active (green) - User can sign in
  - ⚠️ Inactive (orange) - Email not verified yet
  - 🗑️ Deleted (red) - Soft deleted user

### 3. User Details
- 👤 Name
- 🏪 Shop Name
- 📧 Email (with copy button)
- 📱 Phone (with copy button)
- 🔑 User ID (with copy button)
- 🔐 Auth Provider (google/facebook/email)
- 📅 Created Date

### 4. Password Hash Section
The most important debugging feature:

#### Valid Hash (Green):
```
✅ Valid SHA256 hash
Hash: a1b2c3d4e5f6... (64 characters)
```

#### Empty Hash (Red):
```
⚠️ EMPTY - User cannot sign in!
Length: 0
```

#### Invalid Length (Orange):
```
⚠️ Invalid length (expected 64 for SHA256)
Length: 32
```

## Understanding Password Hashes

### What to Look For:
1. **Length**: Should be exactly 64 characters
2. **Format**: Hexadecimal string (0-9, a-f)
3. **Not Empty**: Empty means user cannot sign in

### SHA256 Hash Example:
```
5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8
```

### Common Issues:

#### Issue 1: Empty Password Hash
```
Email: mukesh@example.com
Password Hash: "" (0 characters)
Status: ⚠️ EMPTY - User cannot sign in!
```
**Cause**: Password not hashed during registration
**Fix**: Re-register user OR use fix script

#### Issue 2: Wrong Length
```
Email: test@example.com
Password Hash: "abc123" (6 characters)
Status: ⚠️ Invalid length
```
**Cause**: Password stored in plain text or wrong algorithm
**Fix**: Update to use SHA256 hashing

#### Issue 3: Valid Hash
```
Email: john@example.com
Password Hash: "5e884898da2804..." (64 characters)
Status: ✅ Valid SHA256 hash
```
**Result**: User can sign in successfully

## Copy to Clipboard

All important fields have a copy button (📋):
- Email
- Phone
- User ID
- Password Hash (full hash)

Just tap the copy icon next to any field.

## Refresh Data

Tap the **refresh icon** (🔄) in the top-right corner to reload all data from the database.

## Use Cases

### 1. Debug Sign-In Failures
**Problem**: User cannot sign in
**Steps**:
1. Open Database Viewer
2. Find the user by email
3. Check password hash:
   - Is it empty? → Need to re-register
   - Is it 64 characters? → Password mismatch
   - Is user active? → Check is_active flag

### 2. Verify Registration
**Problem**: Want to confirm user was registered correctly
**Steps**:
1. Register new user
2. Open Database Viewer
3. Check:
   - User exists in database
   - Password hash is 64 characters
   - is_active is 0 (waiting for OTP)

### 3. Verify OTP Activation
**Problem**: Want to confirm OTP verification worked
**Steps**:
1. Complete OTP verification
2. Open Database Viewer
3. Check:
   - is_active changed from 0 to 1
   - User status shows "Active" badge

### 4. Compare Password Hashes
**Problem**: Sign-in works for one user but not another
**Steps**:
1. Open Database Viewer
2. Compare password hash lengths
3. Check if inactive users have different hash format

## Technical Details

### Database Location
```
Android: /data/user/0/com.example.tailer_app/databases/tailor_app.db
```

### Password Hashing Algorithm
```dart
String _hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString(); // 64 character hex string
}
```

### Expected Hash for "Admin#234"
```
6ca13d52ca70c883e0f0bb101e425a89e8624de51db2d2392593af6a84118090
```

## Troubleshooting

### Database Viewer Won't Open
**Error**: "Error Loading Database"
**Solutions**:
1. Restart the app
2. Check if app has storage permissions
3. Verify database exists (run app once to create it)

### No Users Showing
**Message**: "No Users in Database"
**This is normal if**:
- Fresh installation
- No one has registered yet
- Database was cleared

**To fix**: Register a user first

### Can't Copy Password Hash
**Issue**: Copy button not working
**Solutions**:
1. Long-press the hash text (it's selectable)
2. Manually select and copy

## Security Note

⚠️ **THIS IS A DEBUG TOOL - REMOVE IN PRODUCTION**

**Why**: Exposing password hashes is a security risk

**Before Production**:
1. Remove the debug button from signin_screen.dart
2. Or wrap it in `kDebugMode` check:
```dart
if (kDebugMode) {
  Positioned(
    left: 16,
    bottom: 0,
    child: FloatingActionButton(...),
  ),
}
```

3. Or remove entirely:
```dart
// Delete lib/features/debug/database_viewer_screen.dart
// Remove import from signin_screen.dart
// Remove debug button from floatingActionButton
```

## Quick Reference

| Symbol | Meaning |
|--------|---------|
| ✅ | Active account |
| ⚠️ | Inactive account |
| 🗑️ | Deleted account |
| 🟢 | Valid password hash |
| 🟠 | Invalid password hash |
| 🔴 | Empty password hash |
| 📋 | Copy to clipboard |
| 🔄 | Refresh data |
| 🐛 | Debug button |

## Related Files

- `lib/features/debug/database_viewer_screen.dart` - Main viewer screen
- `lib/features/auth/screens/signin_screen.dart` - Debug button location
- `lib/data/services/local_db_service.dart` - Database operations
- `lib/data/services/hybrid_auth_service.dart` - Password hashing
- `lib/data/models/tailor_model.dart` - User model

## Next Steps

After viewing database data:
1. If hash is empty → Re-register user
2. If hash is valid → Check logs for authentication flow
3. If multiple users → Compare working vs non-working accounts

---

**Last Updated**: 2025-01-16
**Database Version**: 13
**Hash Algorithm**: SHA256
