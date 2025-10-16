# Database Location and Debugging Guide

## 📍 Database Path Information

### Database Name
```
tailor_app.db
```

### Database Version
```
Version: 13 (includes is_active field)
```

### Common Database Locations by Platform

#### 🪟 Windows
```
C:\Users\<USERNAME>\AppData\Local\<app_package>\app_flutter\tailor_app.db
```
Or during development:
```
%TEMP%\tailor_app.db
```

#### 🍎 macOS
```
~/Library/Containers/<app_bundle_id>/Data/Library/Application Support/tailor_app.db
```

#### 🐧 Linux
```
~/.local/share/<app_package>/tailor_app.db
```

#### 📱 Android
```
/data/data/<app_package>/databases/tailor_app.db
```
**Note:** Requires root access or ADB to view

#### 🍏 iOS
```
/var/mobile/Containers/Data/Application/<app_id>/Library/Application Support/tailor_app.db
```
**Note:** Requires jailbreak or simulator access

---

## 🛠️ How to Debug the Database

### Method 1: Use the Debug Script (Recommended)
```bash
# Run the batch file (Windows)
debug_db.bat

# Or run the Dart debug script
dart run lib/debug_database.dart
```

### Method 2: Use the Debug Screen in App
1. Add the debug screen to your app routes:
   ```dart
   import 'package:tailer_app/debug_database_screen.dart';
   
   // In your routes:
   GoRoute(
     path: '/debug-database',
     builder: (context, state) => const DatabaseDebugScreen(),
   ),
   ```

2. Navigate to `/debug-database` in your app
3. View database path, schema, and records

### Method 3: Use SQLite Browser
1. Download SQLite Browser: https://sqlitebrowser.org/
2. Find your database using the debug script
3. Open → Browse to database path
4. Explore tables, schema, and data

### Method 4: Use ADB (Android Only)
```bash
# Find your app package name
adb shell pm list packages | grep tailor

# Access database
adb shell
cd /data/data/<your_package>/databases/
sqlite3 tailor_app.db

# View tailor table
.schema tailor
SELECT * FROM tailor;
```

### Method 5: Use VS Code Extension
1. Install "SQLite Viewer" extension in VS Code
2. Use debug script to find database path
3. Right-click database file → Open Database

---

## 📊 Tailor Table Schema

```sql
CREATE TABLE tailor (
  id TEXT PRIMARY KEY,
  unique_id TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  shop_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  auth_provider TEXT CHECK(auth_provider IN ('google', 'facebook', 'email')) NOT NULL,
  address TEXT NOT NULL,
  profile_image_path TEXT,
  is_active INTEGER DEFAULT 0,       -- ✅ Active status (0=inactive, 1=active)
  is_deleted INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- Index for performance
CREATE INDEX idx_tailor_active ON tailor(is_active);
```

### Column Descriptions

| Column | Type | Description | Default |
|--------|------|-------------|---------|
| `id` | TEXT | Primary key (MAT + 7 chars) | - |
| `unique_id` | TEXT | Unique identifier (same as id) | - |
| `name` | TEXT | User's full name | - |
| `shop_name` | TEXT | Shop/business name | - |
| `email` | TEXT | Email (unique) | - |
| `phone` | TEXT | Phone number | - |
| `password_hash` | TEXT | SHA256 hashed password | - |
| `auth_provider` | TEXT | Auth method (google/facebook/email) | 'email' |
| `address` | TEXT | Physical address | '' |
| `profile_image_path` | TEXT | Local image path | NULL |
| **`is_active`** | **INTEGER** | **Activated via OTP (0/1)** | **0** |
| `is_deleted` | INTEGER | Soft delete flag (0/1) | 0 |
| `created_at` | TEXT | Creation timestamp (ISO8601) | - |
| `updated_at` | TEXT | Last update timestamp (ISO8601) | - |

---

## 🔍 Useful SQL Queries for Debugging

### Count All Users
```sql
SELECT COUNT(*) as total_users FROM tailor WHERE is_deleted = 0;
```

### Count Active vs Inactive Users
```sql
SELECT 
  COUNT(*) as total,
  SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) as active,
  SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END) as inactive
FROM tailor 
WHERE is_deleted = 0;
```

### View All Active Users
```sql
SELECT id, name, email, phone, created_at 
FROM tailor 
WHERE is_active = 1 AND is_deleted = 0
ORDER BY created_at DESC;
```

### View All Inactive Users (Pending OTP Verification)
```sql
SELECT id, name, email, phone, created_at 
FROM tailor 
WHERE is_active = 0 AND is_deleted = 0
ORDER BY created_at DESC;
```

### Find Specific User by Email
```sql
SELECT * FROM tailor WHERE email = 'user@example.com';
```

### Check User Active Status
```sql
SELECT 
  name, 
  email, 
  CASE WHEN is_active = 1 THEN 'Active' ELSE 'Inactive' END as status,
  created_at
FROM tailor 
WHERE email = 'user@example.com';
```

### Manually Activate User (For Testing)
```sql
UPDATE tailor 
SET is_active = 1, updated_at = datetime('now') 
WHERE email = 'user@example.com';
```

### Manually Deactivate User
```sql
UPDATE tailor 
SET is_active = 0, updated_at = datetime('now') 
WHERE email = 'user@example.com';
```

### View Recent Registrations
```sql
SELECT id, name, email, is_active, created_at 
FROM tailor 
WHERE is_deleted = 0
ORDER BY created_at DESC 
LIMIT 10;
```

### Delete All Test Data (⚠️ Careful!)
```sql
DELETE FROM tailor WHERE email LIKE '%test%' OR email LIKE '%example%';
```

### Reset Database (⚠️ Very Careful!)
```sql
DELETE FROM tailor;
VACUUM;
```

---

## 🔧 Quick Debugging Checklist

### Problem: "User cannot login after OTP"
```sql
-- Check user's active status
SELECT email, is_active FROM tailor WHERE email = 'user@example.com';

-- Expected: is_active = 1
-- If is_active = 0, user hasn't verified OTP yet
```

### Problem: "Database not found"
1. Run the app first to create the database
2. Use `debug_db.bat` to locate it
3. Check logs for database path

### Problem: "User registered but not in database"
```sql
-- Check if user exists
SELECT * FROM tailor WHERE email = 'user@example.com';

-- Check if soft deleted
SELECT * FROM tailor WHERE email = 'user@example.com' AND is_deleted = 1;
```

### Problem: "Multiple users with same email"
```sql
-- This should return only 1 row (email is UNIQUE)
SELECT COUNT(*) FROM tailor WHERE email = 'user@example.com';

-- If > 1, there's a database integrity issue
```

---

## 📱 Debug in Running App

### Quick Code Snippet to Print DB Path
```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Future<void> printDatabasePath() async {
  final databasePath = await getDatabasesPath();
  final fullPath = join(databasePath, 'tailor_app.db');
  print('📍 Database Path: $fullPath');
}
```

### Check User Active Status in App
```dart
import 'package:tailer_app/data/services/local_db_service.dart';

Future<void> checkUserStatus(String email) async {
  final db = LocalDatabaseService();
  final results = await db.select(
    'tailor',
    where: 'email = ?',
    whereArgs: [email],
  );
  
  if (results.isEmpty) {
    print('❌ User not found: $email');
  } else {
    final user = results.first;
    print('✅ User found:');
    print('   Name: ${user['name']}');
    print('   Email: ${user['email']}');
    print('   Active: ${user['is_active'] == 1 ? '✅ YES' : '❌ NO'}');
    print('   Created: ${user['created_at']}');
  }
}
```

---

## 🎯 Debug Files Created

1. **`debug_db.bat`** - Windows batch script to find database
2. **`lib/debug_database.dart`** - Command-line debug tool
3. **`lib/debug_database_screen.dart`** - Flutter screen for debugging
4. **`DATABASE_DEBUG_GUIDE.md`** - This file

---

## 📞 Getting Help

If you're still having issues:

1. Run `debug_db.bat` and share the output
2. Run these queries and share results:
   ```sql
   SELECT COUNT(*) FROM tailor;
   SELECT * FROM tailor LIMIT 5;
   PRAGMA table_info(tailor);
   ```
3. Check app logs for database errors
4. Verify database version is 13

---

**Last Updated:** October 15, 2025  
**Database Version:** 13  
**Status:** ✅ Ready for Debugging
