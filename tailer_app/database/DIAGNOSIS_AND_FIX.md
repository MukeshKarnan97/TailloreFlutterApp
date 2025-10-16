# 🔧 Database & Authentication Issues - Diagnosis & Fix

**Date:** October 16, 2025  
**Status:** 🚨 CRITICAL - Database not found on device

---

## 🐛 **Issues Identified**

### 1. ❌ Database Not Found on Device
```
Database path: /data/user/0/com.example.tailer_app/databases/tailor_app.db
Checking what databases exist: No databases folder found
```

**Root Cause:** Database is NOT being created on Android device

### 2. ❌ Registration → Dashboard → Auth Fails
**Symptom:** After successful registration, app goes to dashboard but shows auth error

**Root Cause:** 
- User registered but `is_active = 0` (not verified with OTP)
- Sign in checks `is_active = 1` but user hasn't completed OTP verification
- Database may not exist, so user isn't saved at all

### 3. ❌ Cannot Login with Credentials
```
Email: mukesh.dmc97@gmail.com
Password: Admin#234
```

**Root Cause:** 
- Database doesn't exist on device
- No user records exist locally
- Authentication queries fail silently

---

## 🔍 **Diagnostic Steps**

### Step 1: Check if Database Exists

**Run this Flutter debug tool:**
```dart
// Create file: lib/check_database.dart
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dbPath = await getDatabasesPath();
  final fullPath = join(dbPath, 'tailor_app.db');
  
  print('📍 Expected database path: $fullPath');
  
  final dbFile = File(fullPath);
  final exists = await dbFile.exists();
  
  print(exists ? '✅ Database EXISTS' : '❌ Database DOES NOT EXIST');
  
  if (!exists) {
    print('🔧 Creating database...');
    final db = await openDatabase(fullPath, version: 13);
    print('✅ Database created!');
    await db.close();
  }
  
  // Check database folder
  final dbDir = Directory(dbPath);
  final files = await dbDir.list().toList();
  print('\\n📂 Files in databases folder:');
  for (var file in files) {
    print('  - ${file.path}');
  }
}
```

**Run:**
```bash
flutter run lib/check_database.dart
```

---

### Step 2: Verify Database Creation in App Initialization

**Check:** `lib/features/splash/splash_screen_manager.dart`

The database SHOULD be created during splash screen initialization.

**Add debug logs:**
```dart
Future<void> _initializeDatabase() async {
  print('🔧 [DEBUG] Starting database initialization...');
  
  final dbService = LocalDatabaseService();
  final db = await dbService.database;
  
  // Get database path
  final dbPath = await getDatabasesPath();
  final fullPath = join(dbPath, 'tailor_app.db');
  print('📍 [DEBUG] Database path: $fullPath');
  
  // Check if file exists
  final dbFile = File(fullPath);
  final exists = await dbFile.exists();
  print(exists ? '✅ [DEBUG] Database file exists!' : '❌ [DEBUG] Database file MISSING!');
  
  // Verify tables
  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table'"
  );
  print('📋 [DEBUG] Tables created: ${tables.map((t) => t['name']).toList()}');
  
  // Check tailor table
  final tailorCount = Sqflite.firstIntValue(
    await db.rawQuery('SELECT COUNT(*) FROM tailor')
  );
  print('👥 [DEBUG] Tailor records: $tailorCount');
}
```

---

### Step 3: Check Registration Flow

**File:** `lib/features/auth/screens/signup_screen.dart`

**The registration flow SHOULD:**
1. ✅ Create user with `is_active = 0`
2. ✅ Navigate to OTP screen
3. ✅ After OTP verification → UPDATE user `SET is_active = 1`
4. ✅ Then navigate to dashboard

**Current Problem:** Skipping OTP or not updating `is_active`

---

## 🛠️ **Fixes**

### Fix 1: Force Database Creation

**Create file:** `lib/force_database_creation.dart`

```dart
import 'package:flutter/material.dart';
import 'data/services/local_db_service.dart';
import 'core/utils/logger.dart';

Future<void> forceDatabaseCreation() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔥 FORCE DATABASE CREATION');
  print('=' * 50);
  
  try {
    final dbService = LocalDatabaseService();
    
    // This will create database if it doesn't exist
    final db = await dbService.database;
    print('✅ Database instance obtained');
    
    // Verify database path
    final path = await db.getPath();
    print('📍 Database path: $path');
    
    // Verify version
    final version = await db.getVersion();
    print('📌 Database version: $version');
    
    // List all tables
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
    );
    
    print('\\n📋 Tables in database:');
    for (final table in tables) {
      final tableName = table['name'] as String;
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableName')
      ) ?? 0;
      print('  ✓ $tableName ($count records)');
    }
    
    print('\\n✅ Database is ready!');
    
  } catch (e, stackTrace) {
    print('❌ ERROR: $e');
    print('Stack trace: $stackTrace');
  }
}
```

**Add to `main.dart`:**
```dart
import 'force_database_creation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await AppConfig.initialize();
  
  // FORCE DATABASE CREATION
  await forceDatabaseCreation();
  
  // Continue with app...
  runApp(const MyApp());
}
```

---

### Fix 2: Update Registration Flow

**File:** `lib/features/auth/screens/signup_screen.dart`

**Change the signup success handler:**

```dart
// After successful registration
final user = await _authService.signUpNewTailor(
  name: _usernameController.text.trim(),
  shopName: '${_usernameController.text.trim()}\'s Shop',
  email: _emailController.text.trim(),
  phone: _phoneController.text.trim(),
  password: _passwordController.text,
  address: '',
);

// Save credentials for auto-login after OTP
final email = _emailController.text.trim();
final password = _passwordController.text;

// Navigate to OTP screen
if (mounted) {
  context.pushNamed(
    RouteNames.otpVerification,
    extra: {
      'userId': user.id,
      'email': user.email,
      'onVerified': () async {
        // After OTP verification, activate user and login
        print('🔥 OTP verified! Activating user...');
        
        // Update is_active to 1
        await _dbService.update(
          'tailor',
          {'is_active': 1},
          where: 'email = ?',
          whereArgs: [email],
        );
        
        print('✅ User activated! Logging in...');
        
        // Auto-login
        try {
          await _authService.signIn(
            email: email,
            password: password,
            keepSignedIn: true,
          );
          
          print('✅ Auto-login successful!');
          
          // Navigate to dashboard
          if (mounted) {
            context.goNamed(RouteNames.dashboard);
          }
        } catch (e) {
          print('❌ Auto-login failed: $e');
          // Navigate to sign in
          if (mounted) {
            context.goNamed(RouteNames.signIn);
          }
        }
      },
    },
  );
}
```

---

### Fix 3: Add is_active Check in Sign In

**File:** `lib/data/repositories/tailor_auth_repository.dart`

**Update the `signIn()` method:**

```dart
Future<Tailor> signIn({
  required String email,
  required String password,
  bool rememberMe = false,
}) async {
  try {
    debugPrint('TailorAuthRepository: Starting sign in for: $email');

    // Find tailor by email
    final tailors = await _dbService.select(
      'tailor',
      where: 'email = ? AND is_deleted = 0',
      whereArgs: [email.toLowerCase().trim()],
    );

    if (tailors.isEmpty) {
      throw Exception('User not found. Please sign up first.');
    }

    final tailorData = tailors.first;
    final tailor = Tailor.fromMap(tailorData);

    // ✅ CHECK IS_ACTIVE FIELD
    if (tailor.isActive == false || tailorData['is_active'] == 0) {
      throw Exception('Account not activated. Please verify your OTP first.');
    }

    // Verify password
    final passwordParts = tailor.passwordHash.split(':');
    if (passwordParts.length != 2) {
      throw Exception('Invalid password hash format');
    }

    final salt = passwordParts[0];
    final storedHash = passwordParts[1];
    final inputHash = _hashPassword(password, salt);

    if (inputHash != storedHash) {
      throw Exception('Invalid password');
    }

    // Continue with session creation...
    final accessToken = _generateToken();
    await _storageService.storeAuthTokens(
      accessToken: accessToken,
      refreshToken: _generateToken(),
      sessionId: tailor.id,
      userId: tailor.id,
      userEmail: tailor.email,
    );

    await _storageService.setRememberMe(rememberMe);

    debugPrint('TailorAuthRepository: ✅ Sign in successful!');
    return tailor;
  } catch (e) {
    debugPrint('TailorAuthRepository: ❌ Sign in error: $e');
    rethrow;
  }
}
```

---

### Fix 4: Create Manual User Activation Script

**File:** `lib/activate_user.dart`

```dart
import 'package:flutter/material.dart';
import 'data/services/local_db_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final email = 'mukesh.dmc97@gmail.com';
  
  print('🔧 Activating user: $email');
  
  final dbService = LocalDatabaseService();
  final db = await dbService.database;
  
  // Update is_active to 1
  final updated = await db.update(
    'tailor',
    {'is_active': 1},
    where: 'email = ?',
    whereArgs: [email],
  );
  
  if (updated > 0) {
    print('✅ User activated successfully!');
    
    // Verify
    final user = await db.query(
      'tailor',
      where: 'email = ?',
      whereArgs: [email],
    );
    
    if (user.isNotEmpty) {
      print('\\n📋 User details:');
      print('  Email: ${user.first['email']}');
      print('  Name: ${user.first['name']}');
      print('  is_active: ${user.first['is_active']}');
      print('  is_deleted: ${user.first['is_deleted']}');
    }
  } else {
    print('❌ User not found or already activated');
  }
}
```

**Run:**
```bash
flutter run lib/activate_user.dart
```

---

## 🎯 **Complete Fix Sequence**

### On Android Device:

**1. Force Database Creation**
```bash
flutter run lib/force_database_creation.dart
```

**2. Check Database Exists**
```bash
adb shell run-as com.example.tailer_app ls -la databases/
```

**3. If database exists, pull it**
```bash
cd C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app\database
adb exec-out run-as com.example.tailer_app cat databases/tailor_app.db > tailor_app.db
```

**4. View local database**
```bash
python view_tailor_data.py
```

**5. If user exists but not active, activate:**
```bash
flutter run lib/activate_user.dart
```

**6. Try logging in:**
```
Email: mukesh.dmc97@gmail.com
Password: Admin#234
```

---

## 📋 **Expected Results**

After fixes:

✅ Database should exist at: `/data/user/0/com.example.tailer_app/databases/tailor_app.db`  
✅ Registration should create user with `is_active = 0`  
✅ OTP verification should update `is_active = 1`  
✅ Login should check `is_active = 1` before allowing access  
✅ Should be able to login with verified credentials

---

## 🚀 **Next Steps**

1. Run `force_database_creation.dart` on Android
2. Check if database is created
3. Pull database to Windows
4. Inspect user records
5. Activate user if needed
6. Test login flow

---

**Need Help?** Check logs at each step and share error messages.
