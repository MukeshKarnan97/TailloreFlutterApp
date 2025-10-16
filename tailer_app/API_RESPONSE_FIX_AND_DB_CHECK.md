# API Response Parsing Fix & Local DB Check Guide

## Problem Fixed ✅

### Issue
The Django API response structure didn't match the Flutter model expectations:

**Django API Response:**
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "tailor": {
      "id": "MAT2ZWGYPN",
      "name": "ghsbbgv",
      "shop_name": "ghsbbgv's Shop",
      "email": "hjNsttbtn@hshsj.hbj",
      "phone": null,  // ← Nullable
      "profile_image_url": "...",  // ← Different field name
      "email_verified": false,  // ← Extra fields
      "phone_verified": false
    },
    "tokens": {
      "access": "...",
      "refresh": "..."
    }
  }
}
```

**Expected by Model:**
```json
{
  "user": {...},
  "tokens": {...}
}
```

### Error Message
```
Error: type 'Null' is not a subtype of type 'Map<String, dynamic>'
```

This happened because:
1. Model expected `json['user']` but API returned `json['data']['tailor']`
2. Model expected `phone` as String but API returned `null`
3. Model expected `profile_image_path` but API returned `profile_image_url`

## Changes Made

### 1. Updated RegisterResponse.fromJson()

**File:** `lib/data/models/account/auth_models.dart`

```dart
factory RegisterResponse.fromJson(Map<String, dynamic> json) {
  // Handle both response formats:
  // 1. Direct format: {"user": {...}, "tokens": {...}}
  // 2. Wrapped format: {"success": true, "data": {"tailor": {...}, "tokens": {...}}}
  
  final Map<String, dynamic> userData;
  final Map<String, dynamic> tokensData;
  final String? msg;
  
  if (json.containsKey('data')) {
    // ✅ Wrapped format from Django (YOUR CASE)
    final data = json['data'] as Map<String, dynamic>;
    userData = data['tailor'] as Map<String, dynamic>;  // ← Fixed: tailor instead of user
    tokensData = data['tokens'] as Map<String, dynamic>;
    msg = json['message'] as String?;
  } else {
    // Direct format
    userData = json['user'] as Map<String, dynamic>;
    tokensData = json['tokens'] as Map<String, dynamic>;
    msg = json['message'] as String?;
  }
  
  return RegisterResponse(
    user: Tailor.fromMap(userData),
    accessToken: tokensData['access'] as String,
    refreshToken: tokensData['refresh'] as String,
    message: msg,
  );
}
```

### 2. Updated Tailor.fromMap()

**File:** `lib/data/models/tailor_model.dart`

```dart
factory Tailor.fromMap(Map<String, dynamic> map) {
  return Tailor(
    id: map['id'] as String,
    uniqueId: map['unique_id'] as String,
    name: map['name'] as String,
    shopName: map['shop_name'] as String,
    email: map['email'] as String,
    phone: (map['phone'] as String?) ?? '',  // ✅ Handle nullable phone
    passwordHash: (map['password_hash'] as String?) ?? '',  // ✅ May not be in API response
    authProvider: map['auth_provider'] as String? ?? 'email',
    address: (map['address'] as String?) ?? '',
    // ✅ Handle both local path and API URL
    profileImagePath: map['profile_image_path'] as String? ?? 
                     map['profile_image_url'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
    isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
  );
}
```

## How to Check Local Database

### Method 1: Using the Check Script (Recommended)

1. **Add to your app:**
   ```dart
   // In main.dart or any screen, add:
   import 'package:tailer_app/utils/check_local_db.dart';
   
   // Add a button somewhere:
   ElevatedButton(
     onPressed: () async {
       await checkLocalDatabase();
     },
     child: Text('Check Database'),
   ),
   ```

2. **Or navigate to the check screen:**
   ```dart
   Navigator.push(
     context,
     MaterialPageRoute(builder: (_) => DatabaseCheckScreen()),
   );
   ```

3. **Check console output:**
   ```
   ========================================
   CHECKING LOCAL DATABASE...
   ========================================
   
   📊 TOTAL TAILORS IN LOCAL DB: 1
   ========================================
   
   ✅ TAILORS FOUND IN LOCAL DATABASE:
   
   👤 TAILOR #1:
      ID: MAT2ZWGYPN
      Name: ghsbbgv
      Shop: ghsbbgv's Shop
      Email: hjNsttbtn@hshsj.hbj
      Phone: N/A
      Auth Provider: email
      Created: 2025-10-14T16:48:19.402247+00:00
      Updated: 2025-10-14T16:48:19.402247+00:00
      Is Deleted: 0
   
   ========================================
   DATABASE CHECK COMPLETE
   ========================================
   ```

### Method 2: Using Terminal Commands

#### On Android:
```bash
# 1. Find your app's package name
flutter run --verbose | grep "package:"

# 2. Access the database file
adb shell
cd /data/data/com.example.tailer_app/databases/
ls -la

# 3. Pull database to your computer
exit
adb pull /data/data/com.example.tailer_app/databases/tailor_app.db .

# 4. Open with SQLite browser
# Download: https://sqlitebrowser.org/
```

#### On Windows/Desktop:
```powershell
# Database location:
# Windows: C:\Users\<USER>\AppData\Roaming\com.example.tailor_app\databases\
# Look for: tailor_app.db
```

### Method 3: Add Debug Print in HybridAuthService

**File:** `lib/data/services/hybrid_auth_service.dart`

Find the `_syncTailorToLocalDB` method and add prints:

```dart
Future<void> _syncTailorToLocalDB(Tailor tailor) async {
  try {
    Logger.info('HybridAuth', '📥 Syncing tailor to local DB: ${tailor.email}');
    
    // Check if exists
    final existing = await _dbService.select(
      'tailor',
      where: 'id = ?',
      whereArgs: [tailor.id],
    );

    if (existing.isEmpty) {
      // Insert new tailor
      await _dbService.insert('tailor', tailor.toMap());
      Logger.info('HybridAuth', '✅ Tailor inserted to local DB: ${tailor.id}');
      
      // ✅ VERIFY IT WAS INSERTED
      final verify = await _dbService.select('tailor', where: 'id = ?', whereArgs: [tailor.id]);
      debugPrint('🔍 VERIFICATION: Tailor in DB = ${verify.isNotEmpty}');
      if (verify.isNotEmpty) {
        debugPrint('✅ CONFIRMED: ${verify.first}');
      }
    } else {
      // Update existing tailor
      await _dbService.update(
        'tailor',
        tailor.toMap(),
        where: 'id = ?',
        whereArgs: [tailor.id],
      );
      Logger.info('HybridAuth', '✅ Tailor updated in local DB: ${tailor.id}');
    }
  } catch (e) {
    Logger.error('HybridAuth', '❌ Failed to sync tailor to local DB', error: e);
    rethrow;
  }
}
```

## Testing the Complete Flow

### 1. Start Fresh
```bash
# Clear app data
flutter clean
flutter pub get

# Uninstall app from device
adb uninstall com.example.tailer_app

# Rebuild and run
flutter run
```

### 2. Register a New User
1. Open signup screen
2. Fill form with test data:
   - Name: `Test User`
   - Email: `test@example.com`
   - Password: `Test123!@#`
3. Click "Sign Up"
4. Watch console for logs

### 3. Expected Console Output

```
[22:18:16] [API] 🔐 Registering user: test@example.com
[22:18:16] [API] [DIO] POST http://192.168.0.11:8000/api/v1/auth/register/
[22:18:16] [API] Response: {"success":true,"message":"Registration successful",...}
[22:18:16] [INFO] [AccountsApi] ✅ User registered successfully: test@example.com
[22:18:16] [INFO] [HybridAuth] Backend registration successful, inserting into local DB
[22:18:16] [INFO] [HybridAuth] 📥 Syncing tailor to local DB: test@example.com
[22:18:16] [INFO] [HybridAuth] ✅ Tailor inserted to local DB: MAT2ZWGYPN
🔍 VERIFICATION: Tailor in DB = true
✅ CONFIRMED: {id: MAT2ZWGYPN, email: test@example.com, ...}
[22:18:16] [INFO] [HybridAuth] User data synced to local DB, ready for OTP verification
```

### 4. Check Local Database
```dart
// Add anywhere in your code:
await checkLocalDatabase();
```

**Expected output:**
```
📊 TOTAL TAILORS IN LOCAL DB: 1
✅ TAILORS FOUND IN LOCAL DATABASE:

👤 TAILOR #1:
   ID: MAT2ZWGYPN
   Name: Test User
   Email: test@example.com
```

## Troubleshooting

### ❌ Error: "Tailor in DB = false"
**Problem:** Insert failed
**Solution:**
1. Check database table exists:
   ```dart
   final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
   debugPrint('Tables: $tables');
   ```
2. Check for schema mismatch
3. Clear app data and try again

### ❌ Error: "phone field is null"
**Problem:** Database expects non-null phone
**Solution:** Already fixed in `Tailor.fromMap()` - phone defaults to `''`

### ❌ Error: "password_hash is null"
**Problem:** API doesn't return password_hash (security)
**Solution:** Already fixed in `Tailor.fromMap()` - passwordHash defaults to `''`

### ✅ Success Indicators
1. Console shows: `✅ Tailor inserted to local DB`
2. Verification shows: `Tailor in DB = true`
3. `checkLocalDatabase()` shows user data
4. OTP screen navigation happens

## Quick Test Script

Add this to your `main.dart` for quick testing:

```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add this for quick DB check on startup (DEBUG ONLY)
  if (kDebugMode) {
    Future.delayed(Duration(seconds: 2), () {
      checkLocalDatabase();
    });
  }
  
  runApp(MyApp());
}
```

This will automatically check and print database contents 2 seconds after app starts!

---

## Summary

### ✅ Fixed Issues:
1. API response parsing now handles Django's `{success, data: {tailor, tokens}}` format
2. Nullable phone field now handled gracefully
3. `profile_image_url` from API mapped to `profileImagePath`
4. Missing `password_hash` in API response handled

### ✅ Verification Tools:
1. `checkLocalDatabase()` function for instant verification
2. `DatabaseCheckScreen` widget for UI-based checking
3. Console logs in `_syncTailorToLocalDB()`
4. Manual database file inspection

### ✅ Next Steps:
1. Run the app
2. Register a new user
3. Call `checkLocalDatabase()` to verify
4. Check console for confirmation logs
5. Proceed to OTP verification

The local database should now properly save user data after successful API registration! 🎉
