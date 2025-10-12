# 🧪 QUICK TEST GUIDE - Data Isolation Fix

## Problem Fixed
**"When I login as User 2, I see User 1's data"**

Now each user only sees their own data! 🎉

---

## ⚡ Quick Test (5 Minutes)

### Step 1: Run the App
```powershell
flutter run
```

### Step 2: Create User 1
1. Click **Sign Up**
2. Fill in:
   - Username: `Test User 1`
   - Email: `user1@test.com`
   - Password: `Test123!`
3. Click **Sign Up**
4. You should be logged in

### Step 3: Add Data for User 1
1. Go to **Customers** → Click **+**
2. Add customer:
   - Name: `Alice Smith`
   - Phone: `1234567890`
   - Save
3. Add another customer:
   - Name: `Bob Johnson`
   - Phone: `0987654321`
   - Save
4. Go to **Dashboard**
   - ✅ Should show: **2 Customers**

### Step 4: Logout
1. Go to **Settings**
2. Scroll down → Click **Logout**
3. Confirm logout

### Step 5: Create User 2
1. Click **Sign Up** (not Sign In!)
2. Fill in:
   - Username: `Test User 2`
   - Email: `user2@test.com`
   - Password: `Test123!`
3. Click **Sign Up**

### Step 6: Add Data for User 2
1. Go to **Customers** → Click **+**
2. Add customer:
   - Name: `Charlie Brown`
   - Phone: `5555555555`
   - Save
3. Go to **Dashboard**
   - ✅ Should show: **1 Customer** (NOT 3!)
   - ❌ Should NOT see Alice or Bob

### Step 7: Verify Isolation ✅
While logged in as **user2@test.com**:
- ✅ Customers: Only shows **Charlie Brown**
- ✅ Dashboard: Shows **1 customer, 0 orders**
- ❌ Does NOT show Alice or Bob
- ❌ Does NOT show User 1's data

### Step 8: Switch Back to User 1
1. Logout from User 2
2. Click **Sign In**
3. Email: `user1@test.com`
4. Password: `Test123!`
5. Check Dashboard: Should show **2 Customers**
6. Check Customers: Should show **Alice and Bob** only

---

## ✅ Expected Results

| Screen | User 1 (user1@test.com) | User 2 (user2@test.com) |
|--------|-------------------------|-------------------------|
| **Dashboard** | 2 customers, 0 orders | 1 customer, 0 orders |
| **Customers** | Alice, Bob | Charlie |
| **Orders** | Empty | Empty |
| **Can See User 2 Data?** | ❌ NO | N/A |
| **Can See User 1 Data?** | N/A | ❌ NO |

---

## 🔴 If You Still See Other User's Data

### Check These:
1. **Did you fully logout?** 
   - Settings → Logout (don't just close the app)

2. **Are you on the correct user?**
   - Check Settings → Profile → Email

3. **Did you create NEW users?**
   - Don't use existing users from before the fix

4. **Clear app data and try again:**
   ```powershell
   flutter clean
   flutter pub get
   flutter run --uninstall-only
   flutter run
   ```

---

## 📱 Mobile Device Testing

### For Android:
```powershell
# Connect device via USB
flutter devices

# Run on device
flutter run -d <device-id>
```

### For iOS:
```powershell
# Connect iPhone/iPad
flutter devices

# Run on device
flutter run -d <device-id>
```

### Manual Test on Device:
1. Install app
2. Create user1@test.com → Add Alice customer
3. **Uninstall app completely**
4. Reinstall app
5. Create user2@test.com → Add Charlie customer
6. Check: Should NOT see Alice ✅

---

## 🎯 What Was Fixed

### Before:
```dart
// ❌ Gets ALL orders from database
final orders = await _dbService.getOrders();
```

### After:
```dart
// ✅ Gets only THIS user's orders
final orders = await _dbService.getOrders(tailorId: user.email);
```

### How It Works:
```
User Login → AuthService stores user.email
             ↓
Dashboard loads → Gets tailorId = "user1@test.com"
                  ↓
Query database → WHERE tailor_id = "user1@test.com"
                 ↓
Returns → ONLY User 1's data ✅
```

---

## 💡 Quick Summary

**Fixed 4 Files:**
1. ✅ `local_db_service.dart` - Added `tailorId` parameter to `getOrders()`
2. ✅ `dashboard_service.dart` - All methods now filter by `tailorId`
3. ✅ `dashboard_screen.dart` - Gets `tailorId` from AuthService
4. ✅ `order_list_screen.dart` - Passes `tailorId` to queries

**Result:**
- Each user sees ONLY their own data
- No data leakage between users
- Complete privacy & isolation ✅

---

**Test Status:** Ready to test!
**Time Required:** 5 minutes
**Complexity:** Easy

Just follow the steps above and verify each user only sees their own customers! 🎉

