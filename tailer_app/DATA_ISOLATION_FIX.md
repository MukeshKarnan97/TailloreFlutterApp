# 🔴 DATA ISOLATION BUG FIX

## Problem
When User 2 logs in, they see User 1's data (customers, orders, measurements). 

**Root Cause:** Database queries are NOT filtering by `tailor_id`.

---

## 🔍 Files That Need Fixing

### 1. ❌ `lib/data/services/local_db_service.dart`

**Line 1533** - `getOrders()` method:
```dart
// CURRENT (BROKEN):
Future<List<Order>> getOrders() async {
  final maps = await select(
    'orders',
    orderBy: 'created_at DESC',
  );
  return maps.map((map) => Order.fromMap(map)).toList();
}

// FIXED:
Future<List<Order>> getOrders({String? tailorId}) async {
  final maps = await select(
    'orders',
    where: tailorId != null ? 'tailor_id = ?' : null,
    whereArgs: tailorId != null ? [tailorId] : null,
    orderBy: 'created_at DESC',
  );
  return maps.map((map) => Order.fromMap(map)).toList();
}
```

---

### 2. ❌ `lib/data/services/dashboard_service.dart`

**Multiple Methods Missing `tailor_id` Filter:**

#### Line 181 - `_getTotalCustomers()`:
```dart
// CURRENT (BROKEN):
Future<int> _getTotalCustomers([Map<String, DateTime?>? dateRange]) async {
  try {
    final customers = await _dbService.select(
      'customer',
      where: 'is_deleted = ?',
      whereArgs: [0],
    );
    return customers.length;
  }
}

// FIXED:
Future<int> _getTotalCustomers(String tailorId, [Map<String, DateTime?>? dateRange]) async {
  try {
    final customers = await _dbService.select(
      'customer',
      where: 'tailor_id = ? AND is_deleted = ?',
      whereArgs: [tailorId, 0],
    );
    return customers.length;
  }
}
```

#### Line 194 - `_getActiveOrders()`:
```dart
// CURRENT (BROKEN):
Future<int> _getActiveOrders([Map<String, DateTime?>? dateRange]) async {
  String where = 'status IN (?, ?, ?) AND is_deleted = ?';
  List<dynamic> whereArgs = ['pending', 'in_progress', 'measurement_pending', 0];
  // ... missing tailor_id filter
}

// FIXED:
Future<int> _getActiveOrders(String tailorId, [Map<String, DateTime?>? dateRange]) async {
  String where = 'tailor_id = ? AND status IN (?, ?, ?) AND is_deleted = ?';
  List<dynamic> whereArgs = [tailorId, 'pending', 'in_progress', 'measurement_pending', 0];
  // ... rest of code
}
```

#### Line 219 - `_getCompletedOrders()`:
```dart
// CURRENT (BROKEN):
Future<int> _getCompletedOrders([Map<String, DateTime?>? dateRange]) async {
  String where = 'status = ? AND is_deleted = ?';
  List<dynamic> whereArgs = ['completed', 0];
  // ... missing tailor_id filter
}

// FIXED:
Future<int> _getCompletedOrders(String tailorId, [Map<String, DateTime?>? dateRange]) async {
  String where = 'tailor_id = ? AND status = ? AND is_deleted = ?';
  List<dynamic> whereArgs = [tailorId, 'completed', 0];
  // ... rest of code
}
```

#### Line 245 - `_getTotalRevenue()`:
```dart
// CURRENT (BROKEN):
Future<double> _getTotalRevenue([Map<String, DateTime?>? dateRange]) async {
  String where = 'is_deleted = ?';
  List<dynamic> whereArgs = [0];
  // ... missing tailor_id filter on orders table
}

// FIXED:
Future<double> _getTotalRevenue(String tailorId, [Map<String, DateTime?>? dateRange]) async {
  String where = 'tailor_id = ? AND is_deleted = ?';
  List<dynamic> whereArgs = [tailorId, 0];
  // ... rest of code
}
```

#### Line 27 - `initializeDashboard()`:
```dart
// CURRENT (BROKEN):
Future<void> initializeDashboard({String timePeriod = 'all_time'}) async {
  final dateRange = _getDateRangeForPeriod(timePeriod);
  
  final totalCustomers = await _getTotalCustomers(dateRange);
  final activeOrders = await _getActiveOrders(dateRange);
  // ... missing tailorId parameter
}

// FIXED:
Future<void> initializeDashboard({
  required String tailorId, 
  String timePeriod = 'all_time'
}) async {
  final dateRange = _getDateRangeForPeriod(timePeriod);
  
  final totalCustomers = await _getTotalCustomers(tailorId, dateRange);
  final activeOrders = await _getActiveOrders(tailorId, dateRange);
  final completedOrders = await _getCompletedOrders(tailorId, dateRange);
  final totalRevenue = await _getTotalRevenue(tailorId, dateRange);
  // ... pass tailorId to all methods
}
```

---

### 3. ❌ `lib/features/dashboard/screens/dashboard_screen.dart`

**Need to pass `tailorId` to dashboard service:**

#### Add at top of class:
```dart
class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  final AuthService _authService = AuthService(); // ADD THIS
  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = true;
  String? _tailorId; // ADD THIS
```

#### Line 33 - `initState()`:
```dart
@override
void initState() {
  super.initState();
  _initializeAuth(); // ADD THIS
  _loadDashboardData();
  _startAutoRefresh();
}

// ADD THIS METHOD:
Future<void> _initializeAuth() async {
  await _authService.initialize();
  if (_authService.currentUser != null) {
    setState(() {
      _tailorId = _authService.currentUser!.email; // or use unique_id
    });
  }
}
```

#### Line 68 - `_loadDashboardData()`:
```dart
// CURRENT (BROKEN):
Future<void> _loadDashboardData() async {
  try {
    await _dashboardService.initializeDashboard();
    // ...
  }
}

// FIXED:
Future<void> _loadDashboardData() async {
  if (_tailorId == null) return;
  
  try {
    await _dashboardService.initializeDashboard(tailorId: _tailorId!);
    // ...
  }
}
```

#### Line 91 - `_loadDashboardDataWithFilter()`:
```dart
// CURRENT (BROKEN):
Future<void> _loadDashboardDataWithFilter(String timePeriod) async {
  await _dashboardService.initializeDashboard(timePeriod: timePeriod);
  // ...
}

// FIXED:
Future<void> _loadDashboardDataWithFilter(String timePeriod) async {
  if (_tailorId == null) return;
  
  await _dashboardService.initializeDashboard(
    tailorId: _tailorId!, 
    timePeriod: timePeriod
  );
  // ...
}
```

#### Line 114 - `_refreshDashboard()`:
```dart
// CURRENT (BROKEN):
Future<void> _refreshDashboard() async {
  await _dashboardService.refreshDashboard();
  // ...
}

// FIXED:
Future<void> _refreshDashboard() async {
  if (_tailorId == null) return;
  
  await _dashboardService.refreshDashboard(tailorId: _tailorId!);
  // ...
}
```

---

### 4. ❌ `lib/features/orders/screens/order_list_screen.dart`

**Line 55 - `_loadOrders()` method:**

#### Add at top of class:
```dart
class _OrderListScreenState extends State<OrderListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final AuthService _authService = AuthService(); // ADD THIS
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();
  
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _tailorId; // ADD THIS
```

#### Update initState():
```dart
@override
void initState() {
  super.initState();
  _initializeAuth(); // ADD THIS
  _loadOrders();
}

// ADD THIS METHOD:
Future<void> _initializeAuth() async {
  await _authService.initialize();
  if (_authService.currentUser != null) {
    setState(() {
      _tailorId = _authService.currentUser!.email;
    });
  }
}
```

#### Fix _loadOrders():
```dart
// CURRENT (BROKEN):
Future<void> _loadOrders() async {
  try {
    setState(() {
      _isLoading = true;
    });

    final orders = await _dbService.getOrders();
    // ... missing tailorId
  }
}

// FIXED:
Future<void> _loadOrders() async {
  if (_tailorId == null) return;
  
  try {
    setState(() {
      _isLoading = true;
    });

    final orders = await _dbService.getOrders(tailorId: _tailorId);
    
    if (mounted) {
      setState(() {
        _orders = orders;
        _filteredOrders = orders;
        _isLoading = false;
      });
    }
  } catch (e, stackTrace) {
    Logger.error('OrderListScreen', 'Failed to load orders', error: e, stackTrace: stackTrace);
    // ... error handling
  }
}
```

---

## 🎯 Summary of Changes

### Files to Modify:
1. ✅ `lib/data/services/local_db_service.dart` - Add `tailorId` parameter to `getOrders()`
2. ✅ `lib/data/services/dashboard_service.dart` - Add `tailorId` to ALL methods
3. ✅ `lib/features/dashboard/screens/dashboard_screen.dart` - Get `tailorId` from AuthService
4. ✅ `lib/features/orders/screens/order_list_screen.dart` - Pass `tailorId` to `getOrders()`
5. ⚠️ **Check ALL other screens** for similar issues

### Screens That Likely Need Fixing:
- `lib/features/orders/screens/pending_orders_screen.dart`
- `lib/features/orders/screens/completed_orders_screen.dart`
- `lib/features/payments/screens/payment_collection_screen.dart`
- `lib/features/payments/screens/payment_history_screen.dart`
- `lib/features/measurements/screens/measurement_list_screen.dart`

---

## 🔧 How to Get TailorId

**Option 1: From AuthService (Current Users Table)**
```dart
final AuthService _authService = AuthService();
await _authService.initialize();
final tailorId = _authService.currentUser?.email; // Use email as tailor_id
```

**Option 2: From Tailor Table (if using tailor login)**
```dart
final tailor = await _dbService.getTailorByEmail(email);
final tailorId = tailor['unique_id']; // or tailor['email']
```

---

## ✅ Testing After Fix

### Test Steps:
1. **Create User 1:**
   - Sign up as user1@test.com
   - Add 2 customers (Alice, Bob)
   - Add 3 orders for Alice
   - Add 2 measurements

2. **Create User 2:**
   - Sign up as user2@test.com
   - Add 1 customer (Charlie)
   - Add 1 order for Charlie

3. **Verify Isolation:**
   - ✅ User 1 sees: Alice, Bob, 3 orders, 2 measurements
   - ✅ User 2 sees: Charlie, 1 order, 0 measurements
   - ✅ User 1 does NOT see Charlie
   - ✅ User 2 does NOT see Alice/Bob

4. **Dashboard Test:**
   - ✅ User 1 dashboard shows 2 customers, 3 orders
   - ✅ User 2 dashboard shows 1 customer, 1 order

---

## 🚨 CRITICAL

**Every database query MUST include `tailor_id` filter:**
```dart
// ❌ WRONG:
await _dbService.select('customer');

// ✅ CORRECT:
await _dbService.select('customer', 
  where: 'tailor_id = ?', 
  whereArgs: [tailorId]
);
```

---

**Priority: CRITICAL** 🔴
**Impact: All users see all data** (security & privacy issue)
**Fix Required: Immediately**

