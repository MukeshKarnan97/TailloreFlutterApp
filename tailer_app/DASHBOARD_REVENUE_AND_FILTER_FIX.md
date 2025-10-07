# Dashboard Revenue Fix & Time Period Filter Implementation

## Issues Fixed

### 1. Total Revenue Calculation ✅

**Problem**: Revenue was querying payment table with non-existent `status` column

**Root Cause**: 
- Payment table schema doesn't have a `status` column
- All payments in the table are by definition "received" payments
- Original query: `WHERE status = 'completed'` ❌

**Solution Applied**:
```dart
// File: lib/data/services/dashboard_service.dart
// Before:
final payments = await _dbService.select(
  'payment',
  where: 'status = ?',  // ❌ Column doesn't exist
  whereArgs: ['completed'],
);

// After:
final payments = await _dbService.select(
  'payment',
  where: 'is_deleted = ?',  // ✅ Correct query
  whereArgs: [0],
);
```

**Revenue Calculation**:
```dart
double totalRevenue = 0.0;
for (final payment in payments) {
  totalRevenue += (payment['amount'] as num).toDouble();
}
return totalRevenue;
```

This correctly sums all payment amounts from the `payment` table, which represents all collections.

---

### 2. Business Overview Time Period Filter ✅

**Feature Added**: Dropdown filter to view statistics for different time periods

**Time Periods Supported**:
- 📅 **Today** - Statistics for current day
- 📅 **This Week** - Current week (Monday to Sunday)
- 📅 **This Month** - Current calendar month
- 📅 **This Year** - Current calendar year
- 📅 **All Time** - Complete historical data (default)

**UI Implementation** (`dashboard_screen.dart`):

1. **Added State Variable**:
```dart
String _selectedTimePeriod = 'all_time'; // Default to show all data
```

2. **Added Dropdown in Business Overview Header**:
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: AppColors.primary.withOpacity(0.1),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: AppColors.primary.withOpacity(0.3),
      width: 1,
    ),
  ),
  child: DropdownButtonHideUnderline(
    child: DropdownButton<String>(
      value: _selectedTimePeriod,
      isDense: true,
      items: const [
        DropdownMenuItem(value: 'today', child: Text('Today')),
        DropdownMenuItem(value: 'this_week', child: Text('This Week')),
        DropdownMenuItem(value: 'this_month', child: Text('This Month')),
        DropdownMenuItem(value: 'this_year', child: Text('This Year')),
        DropdownMenuItem(value: 'all_time', child: Text('All Time')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedTimePeriod = value;
          });
          _loadDashboardDataWithFilter(value);
        }
      },
    ),
  ),
),
```

3. **Added Filter Loading Method**:
```dart
Future<void> _loadDashboardDataWithFilter(String timePeriod) async {
  setState(() => _isRefreshing = true);
  
  try {
    await _dashboardService.initializeDashboard(timePeriod: timePeriod);
    if (mounted) {
      setState(() {
        _dashboardData = _dashboardService.dashboardStats;
        _lastUpdated = DateTime.now();
        _isRefreshing = false;
      });
    }
  } catch (e) {
    // Error handling...
  }
}
```

---

## Backend Implementation (`dashboard_service.dart`)

### 1. Date Range Calculator

Added helper method to convert time period to date ranges:

```dart
Map<String, DateTime?> _getDateRangeForPeriod(String period) {
  final now = DateTime.now();
  DateTime? startDate;
  DateTime? endDate = now;
  
  switch (period) {
    case 'today':
      startDate = DateTime(now.year, now.month, now.day);
      endDate = startDate.add(const Duration(days: 1));
      break;
    case 'this_week':
      // Get start of week (Monday)
      final weekday = now.weekday;
      startDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weekday - 1));
      endDate = startDate.add(const Duration(days: 7));
      break;
    case 'this_month':
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 1);
      break;
    case 'this_year':
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year + 1, 1, 1);
      break;
    case 'all_time':
    default:
      startDate = null;
      endDate = null;
      break;
  }
  
  return {'start': startDate, 'end': endDate};
}
```

### 2. Updated Dashboard Initialization

```dart
Future<void> initializeDashboard({String timePeriod = 'all_time'}) async {
  try {
    debugPrint('Initializing dashboard data for period: $timePeriod...');
    
    // Get date range for the selected time period
    final dateRange = _getDateRangeForPeriod(timePeriod);
    
    // Fetch real data from database with time filter
    final totalCustomers = await _getTotalCustomers(dateRange);
    final activeOrders = await _getActiveOrders(dateRange);
    final completedOrders = await _getCompletedOrders(dateRange);
    final totalRevenue = await _getTotalRevenue(dateRange);
    final avgOrderValue = await _getAverageOrderValue(dateRange);
    
    // ... store in dashboardStats
  }
}
```

### 3. Updated All Stat Methods

Each method now accepts optional date range parameter:

**Example - Total Customers**:
```dart
Future<int> _getTotalCustomers([Map<String, DateTime?>? dateRange]) async {
  try {
    String where = 'is_deleted = ?';
    List<dynamic> whereArgs = [0];
    
    if (dateRange != null && dateRange['start'] != null && dateRange['end'] != null) {
      where += ' AND created_at >= ? AND created_at < ?';
      whereArgs.addAll([
        dateRange['start']!.millisecondsSinceEpoch,
        dateRange['end']!.millisecondsSinceEpoch,
      ]);
    }
    
    final customers = await _dbService.select(
      'customer',
      where: where,
      whereArgs: whereArgs,
    );
    return customers.length;
  }
}
```

**Example - Total Revenue** (with date filtering on `paid_on`):
```dart
Future<double> _getTotalRevenue([Map<String, DateTime?>? dateRange]) async {
  try {
    String where = 'is_deleted = ?';
    List<dynamic> whereArgs = [0];
    
    if (dateRange != null && dateRange['start'] != null && dateRange['end'] != null) {
      where += ' AND paid_on >= ? AND paid_on < ?';
      whereArgs.addAll([
        dateRange['start']!.toIso8601String(),
        dateRange['end']!.toIso8601String(),
      ]);
    }
    
    final payments = await _dbService.select(
      'payment',
      where: where,
      whereArgs: whereArgs,
    );
    
    double totalRevenue = 0.0;
    for (final payment in payments) {
      totalRevenue += (payment['amount'] as num).toDouble();
    }
    return totalRevenue;
  }
}
```

---

## Updated Methods with Date Filtering

All the following methods now support time period filtering:

1. ✅ `_getTotalCustomers()` - Filters by `created_at`
2. ✅ `_getActiveOrders()` - Filters by `created_at`
3. ✅ `_getCompletedOrders()` - Filters by `created_at`
4. ✅ `_getTotalRevenue()` - Filters by `paid_on` (payment date)
5. ✅ `_getAverageOrderValue()` - Filters by `created_at`

**Note**: 
- `_getPendingMeasurements()` - Not filtered (always shows current pending)
- `_getTodayAppointments()` - Already specific to today
- `_getMonthlyOrders()` - Already specific to current month

---

## Database Schema Reference

### Payment Table
```sql
CREATE TABLE payment (
  id TEXT PRIMARY KEY,
  unique_id TEXT UNIQUE NOT NULL,
  order_id TEXT NOT NULL,
  amount REAL NOT NULL,           -- ← Revenue source
  method TEXT NOT NULL DEFAULT 'cash',
  notes TEXT DEFAULT '',
  transaction_id TEXT,
  paid_on TEXT NOT NULL,          -- ← Date for revenue filtering
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  is_deleted INTEGER DEFAULT 0,   -- ← For filtering active payments
  FOREIGN KEY (order_id) REFERENCES orders (unique_id)
)
```

**Key Points**:
- ❌ No `status` column (all payments are received by definition)
- ✅ Use `is_deleted = 0` to filter active payments
- ✅ Use `paid_on` for date-based revenue filtering
- ✅ Sum `amount` column for total revenue

---

## How It Works

### User Flow:

1. **User opens dashboard** → Shows "All Time" data by default
2. **User clicks dropdown** → Sees time period options
3. **User selects "Today"** → Dashboard refreshes to show:
   - Customers added today
   - Orders created today  
   - Orders completed today
   - Payments received today
   - Average order value for today
4. **Filter persists** → Until user changes it or navigates away

### Data Flow:

```
User selects "This Week"
        ↓
_loadDashboardDataWithFilter('this_week')
        ↓
dashboardService.initializeDashboard(timePeriod: 'this_week')
        ↓
_getDateRangeForPeriod('this_week')
        ↓
Returns: { start: Monday 00:00, end: Sunday 23:59 }
        ↓
Each stat method filters by date range
        ↓
SQL: WHERE created_at >= Monday AND created_at < Next Monday
        ↓
Dashboard updates with filtered statistics
```

---

## Testing Checklist

### Revenue Calculation:
- [ ] Dashboard shows total revenue without errors
- [ ] Revenue = sum of all payments in `payment` table
- [ ] Filter by "Today" shows only today's payments
- [ ] Filter by "This Week" shows this week's payments
- [ ] Filter by "All Time" shows all payments

### Time Period Filters:
- [ ] Dropdown displays all 5 options
- [ ] "Today" shows data from midnight to now
- [ ] "This Week" shows data from Monday to Sunday
- [ ] "This Month" shows current month data
- [ ] "This Year" shows current year data
- [ ] "All Time" shows complete history
- [ ] Switching filters updates all cards correctly
- [ ] Loading indicator shows during filter change

### Business Overview Cards:
- [ ] Total Customers updates with filter
- [ ] Active Orders updates with filter
- [ ] Completed Orders updates with filter
- [ ] Total Revenue updates with filter
- [ ] All cards show correct values for each time period

---

## Files Modified

### 1. `lib/data/services/dashboard_service.dart`
**Changes**:
- ✅ Fixed `_getTotalRevenue()` payment query (removed non-existent status column)
- ✅ Added `_getDateRangeForPeriod()` helper method
- ✅ Updated `initializeDashboard()` to accept `timePeriod` parameter
- ✅ Updated `_getTotalCustomers()` to support date filtering
- ✅ Updated `_getActiveOrders()` to support date filtering
- ✅ Updated `_getCompletedOrders()` to support date filtering
- ✅ Updated `_getTotalRevenue()` to support date filtering on `paid_on`
- ✅ Updated `_getAverageOrderValue()` to support date filtering

### 2. `lib/features/dashboard/screens/dashboard_screen.dart`
**Changes**:
- ✅ Added `_selectedTimePeriod` state variable
- ✅ Added time period dropdown in Business Overview header
- ✅ Added `_loadDashboardDataWithFilter()` method
- ✅ Styled dropdown to match app theme
- ✅ Integrated dropdown with existing refresh mechanism

---

## Benefits

1. **Accurate Revenue** - Now correctly sums all payment collections
2. **Flexible Reporting** - View statistics for any time period
3. **Better Insights** - Compare today vs this week vs all time
4. **User-Friendly** - Easy dropdown interface
5. **Performance** - Efficient database queries with date filtering
6. **Consistent UI** - Dropdown matches app theme and design

---

## Future Enhancements (Optional)

1. **Custom Date Range** - Allow users to select specific start/end dates
2. **Comparison View** - Show % change vs previous period
3. **Export Reports** - Generate PDF/CSV for selected time period
4. **Saved Filters** - Remember user's preferred time period
5. **Chart Visualizations** - Add graphs for revenue trends over time
6. **Multiple Currencies** - Support for different payment methods breakdown

---

## Summary

✅ **Revenue calculation fixed** - Uses correct payment table query  
✅ **Time period filter added** - Dropdown with 5 options  
✅ **All statistics filtered** - Customers, orders, revenue, etc.  
✅ **Payment-based revenue** - Correctly references payment collections  
✅ **Date-aware filtering** - Proper date range calculations  
✅ **Clean UI integration** - Seamless dropdown in header  
✅ **Error-free implementation** - All compile errors resolved  
✅ **Ready for testing** - Hot restart to see changes  

**Total Revenue Formula**: `SUM(payment.amount WHERE is_deleted = 0 AND paid_on IN date_range)`
