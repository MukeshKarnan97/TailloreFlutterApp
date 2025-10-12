# Migration Plan: Use Tailor Model for Authentication

## Current Problem
- Currently using **UserModel** for authentication (generic user table)
- Should be using **Tailor** model (tailor-specific with shop details)
- Need to maintain **single Tailor table** for all tailor-related data

## New Architecture

### Single Source of Truth: `tailors` Table

```sql
CREATE TABLE tailors (
  id TEXT PRIMARY KEY,              -- Auto-generated: "MAT" + 7 random chars
  unique_id TEXT NOT NULL UNIQUE,   -- Same as id
  name TEXT NOT NULL,               -- Tailor's name
  shop_name TEXT NOT NULL,          -- Shop/business name
  email TEXT NOT NULL UNIQUE,       -- Email (for login)
  phone TEXT NOT NULL,              -- Phone number
  password_hash TEXT NOT NULL,      -- Hashed password
  auth_provider TEXT NOT NULL,      -- 'email', 'google', 'facebook'
  address TEXT NOT NULL,            -- Shop address
  created_at TEXT NOT NULL,         -- Registration date
  updated_at TEXT NOT NULL          -- Last update
);
```

### What This Means

**Before (Wrong):**
```
users table → Used for authentication
  ↓
UserModel.email → Used as tailor_id in orders/customers
```

**After (Correct):**
```
tailors table → Single source of truth
  ↓
Tailor.email → Used as tailor_id in orders/customers
  ↓
Same person who logged in = same tailor who owns the data
```

## Benefits

1. ✅ **Single table** - No confusion between users and tailors
2. ✅ **Shop details** - Name, address, phone all in one place
3. ✅ **Unique IDs** - Professional "MAT" prefix IDs
4. ✅ **Clean data model** - Each tailor owns their orders/customers
5. ✅ **Scalable** - Easy to add more tailor-specific features later

## Migration Steps

### Step 1: Update Database Schema

Add the tailors table creation to `LocalDatabaseService`:

```dart
// In _createTables() method
await db.execute('''
  CREATE TABLE IF NOT EXISTS tailors (
    id TEXT PRIMARY KEY,
    unique_id TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    shop_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    auth_provider TEXT NOT NULL DEFAULT 'email',
    address TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    is_deleted INTEGER NOT NULL DEFAULT 0
  )
''');
```

### Step 2: Update AuthService to Use Tailor Model

**Current:**
```dart
class AuthService {
  UserModel? _currentUser;  // ❌ Wrong
  UserModel? get currentUser => _currentUser;
}
```

**New:**
```dart
class AuthService {
  Tailor? _currentTailor;  // ✅ Correct
  Tailor? get currentTailor => _currentTailor;
  
  // Keep backward compatibility
  String? get currentUserEmail => _currentTailor?.email;
}
```

### Step 3: Update Registration Flow

**signup_screen.dart:**
```dart
// Instead of creating UserModel
final tailor = Tailor.create(
  name: _nameController.text,
  shopName: _shopNameController.text,  // Add this field
  email: _emailController.text,
  phone: _phoneController.text,
  passwordHash: hashedPassword,
  authProvider: 'email',
  address: _addressController.text,    // Add this field
);

await _dbService.insertTailor(tailor);
```

### Step 4: Update All References

Replace everywhere:
- `UserModel` → `Tailor`
- `currentUser` → `currentTailor`
- `currentUser.email` → `currentTailor.email`
- `users` table → `tailors` table

### Step 5: Migrate Existing Data

```dart
// Migration script
Future<void> migrateUsersToTailors() async {
  final db = await LocalDatabaseService().database;
  
  // Copy users to tailors table
  final users = await db.query('users');
  
  for (var user in users) {
    final tailor = {
      'id': 'MAT${DateTime.now().millisecondsSinceEpoch}',
      'unique_id': 'MAT${DateTime.now().millisecondsSinceEpoch}',
      'name': user['username'],
      'shop_name': 'My Tailor Shop',  // Default
      'email': user['email'],
      'phone': user['phone'] ?? '',
      'password_hash': user['password_hash'],
      'auth_provider': 'email',
      'address': '',  // Default
      'created_at': user['created_at'],
      'updated_at': user['updated_at'],
      'is_deleted': 0,
    };
    
    await db.insert('tailors', tailor);
  }
  
  Logger.info('Migration', 'Migrated ${users.length} users to tailors');
}
```

## Files to Update

### 1. Database Service
- `lib/data/services/local_db_service.dart`
  - Add `tailors` table schema
  - Add `insertTailor()` method
  - Add `getTailorByEmail()` method
  - Add `updateTailor()` method

### 2. Auth Service
- `lib/data/services/auth_service.dart`
  - Change `UserModel?` to `Tailor?`
  - Update all methods to use Tailor
  - Update repository calls

### 3. Auth Repository
- `lib/data/repositories/auth_repository.dart`
  - Change from `users` table to `tailors` table
  - Update all queries

### 4. Signup Screen
- `lib/features/auth/screens/signup_screen.dart`
  - Add fields: Shop Name, Address
  - Create Tailor instead of UserModel
  - Use `insertTailor()` instead of `insertUser()`

### 5. All Screens Using Auth
- `lib/features/dashboard/screens/dashboard_screen.dart`
- `lib/features/orders/screens/orders_main_screen.dart`
- `lib/features/orders/screens/add_order_screen.dart`
- `lib/features/customers/screens/add_customer_screen.dart`
- Update `currentUser` → `currentTailor`
- Update `.email` references

## Simplified Approach (Recommended)

Instead of migrating everything, we can:

1. ✅ **Keep using UserModel for now** but rename it conceptually
2. ✅ **Add shop_name and address to users table**
3. ✅ **Use UserModel.email as tailor_id** (already working)
4. ✅ **Consider it as "TailorUser"** - same thing, different name

This way:
- Less code changes
- No complex migration
- Same functionality
- Just add shop fields to registration

## Quick Fix Option

**Add shop fields to registration without changing the entire model:**

```dart
// signup_screen.dart - Add these fields
TextField(
  controller: _shopNameController,
  decoration: InputDecoration(labelText: 'Shop Name'),
),
TextField(
  controller: _addressController,
  decoration: InputDecoration(labelText: 'Shop Address'),
),

// Store in user_preferences or separate shop_details table
await db.insert('shop_details', {
  'tailor_id': user.email,
  'shop_name': _shopNameController.text,
  'address': _addressController.text,
});
```

## Recommendation

**Option 1: Quick Fix (Easiest)**
- Keep UserModel
- Add shop_details table
- Link by email
- Works immediately

**Option 2: Proper Migration (Better Long-term)**
- Migrate to Tailor model
- Single source of truth
- More professional
- Takes more time

**Your Choice:** Which approach do you prefer?

---

**Status:** Ready to implement - awaiting your decision
**Estimated Time:** 
- Quick Fix: 30 minutes
- Full Migration: 2-3 hours
