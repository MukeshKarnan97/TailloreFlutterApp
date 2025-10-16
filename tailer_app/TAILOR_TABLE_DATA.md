# 📊 TAILOR TABLE DATA (From Android Device Logs)

## ✅ Database Status

**Location:** `/data/user/0/com.example.tailer_app/databases/tailor_app.db`  
**Version:** 13  
**Status:** ✅ Working and Active

---

## 📈 Current Statistics (from logs)

- **Total Records:** 1
- **Active Users:** 1 (is_active = 1)
- **Inactive Users:** 0 (is_active = 0)
- **Deleted Users:** 0 (is_deleted = 1)

---

## 📋 ALL TAILOR TABLE RECORDS

### Record #1

```
────────────────────────────────────────────────────────────────
  ID: MAT67MIMGU
  Unique ID: MAT67MIMGU
  Name: Mukesh K
  Shop Name: Mukesh K's Shop
  Email: mukesh.dmc97@gmail.com
  Phone: (empty)
  Password Hash: [SHA256 hash - stored]
  Auth Provider: email
  Address: (empty)
  Profile Image Path: (null)
  Is Active: ✅ YES (1) - VERIFIED VIA OTP
  Is Deleted: ✅ NO (0) - ACTIVE ACCOUNT
  Created At: 2025-10-15T16:33:46.276198+00:00
  Updated At: 2025-10-15T16:33:46.276198+00:00
────────────────────────────────────────────────────────────────
```

---

## 🔑 Key Information

### User Status: ✅ ACTIVE & VERIFIED

- **Registration:** ✅ Completed
- **OTP Verification:** ✅ Verified (is_active = 1)
- **Local Tokens:** ✅ Generated
- **Authentication:** ✅ Ready to login

---

## 🎯 Detailed Field Breakdown

| Field | Value | Status |
|-------|-------|--------|
| **id** | MAT67MIMGU | ✅ Primary Key |
| **unique_id** | MAT67MIMGU | ✅ Unique Identifier |
| **name** | Mukesh K | ✅ Set |
| **shop_name** | Mukesh K's Shop | ✅ Set |
| **email** | mukesh.dmc97@gmail.com | ✅ Unique & Verified |
| **phone** | (empty) | ⚠️ Optional |
| **password_hash** | SHA256 hash | ✅ Encrypted |
| **auth_provider** | email | ✅ Email-based auth |
| **address** | (empty) | ⚠️ Optional |
| **profile_image_path** | null | ⚠️ No image yet |
| **is_active** | 1 | ✅ **ACTIVE** |
| **is_deleted** | 0 | ✅ **NOT DELETED** |
| **created_at** | 2025-10-15T16:33:46 | ✅ Timestamp |
| **updated_at** | 2025-10-15T16:33:46 | ✅ Timestamp |

---

## 📝 Transaction Log (from app logs)

### 1. Registration
```
[22:03:52] User registered: mukesh.dmc97@gmail.com
[22:03:52] Inserted new tailor into local DB
[22:03:52] is_active = 0 (inactive, pending OTP)
```

### 2. OTP Verification
```
[22:04:08] OTP verified successfully by backend
[22:04:08] Fetching user from local DB...
[22:04:08] User data fetched from local DB: mukesh.dmc97@gmail.com
[22:04:08] UPDATE tailor SET is_active = 1 WHERE id = MAT67MIMGU
[22:04:08] User marked as active in local DB
```

### 3. Token Generation
```
[22:04:08] Generated access token for: mukesh.dmc97@gmail.com
[22:04:08] Generated refresh token for: mukesh.dmc97@gmail.com
[22:04:09] Local tokens generated and saved
```

### 4. Authentication
```
[22:04:09] OTP verification complete, user activated and authenticated locally
[22:04:10] User authenticated, navigating to dashboard...
```

---

## 🔍 SQL Queries Used

### Get All Records
```sql
SELECT * FROM tailor;
```

### Get Active Users
```sql
SELECT * FROM tailor WHERE is_active = 1 AND is_deleted = 0;
```

### Get Inactive Users (Pending OTP)
```sql
SELECT * FROM tailor WHERE is_active = 0 AND is_deleted = 0;
```

### Check User Status
```sql
SELECT 
  name, 
  email, 
  CASE WHEN is_active = 1 THEN 'Active' ELSE 'Inactive' END as status,
  created_at
FROM tailor 
WHERE email = 'mukesh.dmc97@gmail.com';
```

---

## 🎨 Visual Timeline

```
Registration (22:03:52)
    ↓
User Created in DB
is_active = 0
    ↓
OTP Sent to Email
    ↓
User Enters OTP (22:04:08)
    ↓
Django Validates OTP ✅
    ↓
UPDATE is_active = 1
    ↓
Generate Local Tokens
    ↓
User Authenticated ✅
    ↓
Navigate to Dashboard
```

---

## 📱 How to View Database on Your Device

### Option 1: Using ADB (Requires Android SDK)
```bash
# Pull database from device
adb pull /data/user/0/com.example.tailer_app/databases/tailor_app.db

# Query with sqlite3
sqlite3 tailor_app.db "SELECT * FROM tailor;"
```

### Option 2: Use DB Browser for SQLite
1. Download: https://sqlitebrowser.org/
2. Pull database using ADB
3. Open in DB Browser
4. Browse tailor table

### Option 3: Add Debug Screen to App
Add `DatabaseDebugScreen` to your app routes:
```dart
GoRoute(
  path: '/debug-database',
  builder: (context, state) => const DatabaseDebugScreen(),
),
```

### Option 4: Use Android Studio
1. Open Android Studio
2. View → Tool Windows → Device File Explorer
3. Navigate to: `/data/data/com.example.tailer_app/databases/`
4. Right-click `tailor_app.db` → Save As
5. Open with DB Browser

---

## ✅ Summary

**Current State:**
- ✅ 1 user registered
- ✅ 1 user active (verified via OTP)
- ✅ Local authentication working
- ✅ Local tokens generated
- ✅ Ready for production use

**User Details:**
- Name: Mukesh K
- Email: mukesh.dmc97@gmail.com
- Shop: Mukesh K's Shop
- Status: Active & Verified

---

**Last Updated:** October 15, 2025  
**Data Source:** Android Device Logs  
**Database Version:** 13
