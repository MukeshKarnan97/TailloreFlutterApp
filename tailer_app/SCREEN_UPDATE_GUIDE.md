# Screen Update Guide - Database Integration

## 🎯 Overview

This guide shows exactly what needs to be updated in each screen to use the new optimized database queries.

---

## 📋 Files Requiring Updates

### ✅ Database Layer (COMPLETED)
- ✅ `lib/data/services/local_db_service.dart` - Added 5 optimized query methods
- ✅ `lib/data/models/order_model.dart` - Added `measurementId` field

### ⏳ Screen Layer (PENDING)

#### Orders Screens
1. **OrdersMainScreen** - `lib/features/orders/screens/orders_main_screen.dart`
2. **OrderListScreen** - `lib/features/orders/screens/order_list_screen.dart`
3. **OrderDetailScreen** - `lib/features/orders/screens/order_detail_screen.dart`

#### Payment Screens
4. **PaymentCollectionScreen** - Search for payment collection related files
5. **PaymentHistoryScreen** - `lib/features/payments/screens/*`
6. **OrderPaymentHistoryScreen** - `lib/features/payments/screens/order_payment_history_screen.dart`

---

## 🔄 Migration Pattern

### Pattern 1: Orders List Screen

**File**: `orders_main_screen.dart` or similar

#### Before (N+1 Problem):
```dart
// ❌ BAD: Multiple database queries in loop
Future<void> _loadOrders() async {
  final orders = await _db.getOrdersByTailorId(tailorId);
  
  List<OrderWithDetails> ordersWithDetails = [];
  for (var orderMap in orders) {
    // This creates N+1 queries!
    final customer = await _db.getCustomerByUniqueId(orderMap['customer_id']); 
    final payments = await _db.getPaymentsByOrderId(orderMap['unique_id']);
    
    ordersWithDetails.add(OrderWithDetails(
      order: Order.fromMap(orderMap),
      customerName: customer?['name'],
      totalPaid: payments.fold(0.0, (sum, p) => sum + p.amount),
    ));
  }
  
  setState(() {
    _orders = ordersWithDetails;
  });
}
```

#### After (Optimized):
```dart
// ✅ GOOD: Single JOIN query
Future<void> _loadOrders() async {
  final ordersWithDetails = await _db.getOrdersWithFullDetails(
    tailorId: tailorId,
    limit: 100, // Optional pagination
  );
  
  setState(() {
    _orders = ordersWithDetails.map((data) => OrderWithDetails(
      order: Order.fromMap(data),
      customerName: data['customer_name'],
      customerPhone: data['customer_phone'],
      totalPaid: (data['total_paid'] as num?)?.toDouble() ?? 0.0,
      paymentCount: data['payment_count'] as int,
      // Measurement data also available if needed:
      measurementDressType: data['measurement_dress_type'],
      measurementData: data['measurement_data'],
    )).toList();
  });
}
```

**Benefits**:
- 1 query instead of N+1 queries
- 10-20x faster
- All related data in single call

---

### Pattern 2: Payment Collection Screen

**File**: Search for payment collection screen

#### Before:
```dart
// ❌ BAD: Multiple queries + manual calculations
Future<void> _loadPendingPayments() async {
  final allOrders = await _db.getOrdersByStatus(tailorId, 'pending');
  
  List<OrderPaymentInfo> pendingList = [];
  for (var orderMap in allOrders) {
    final order = Order.fromMap(orderMap);
    final customer = await _db.getCustomerByUniqueId(order.customerId);
    final payments = await _db.getPaymentsByOrderId(order.uniqueId);
    
    final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount);
    final balance = order.totalAmount - totalPaid;
    
    if (balance > 0) {
      pendingList.add(OrderPaymentInfo(
        order: order,
        customer: customer,
        totalPaid: totalPaid,
        balance: balance,
      ));
    }
  }
  
  setState(() {
    _pendingPayments = pendingList;
  });
}
```

#### After:
```dart
// ✅ GOOD: Optimized method with built-in calculations
Future<void> _loadPendingPayments() async {
  final pendingPayments = await _db.getOrdersWithPendingPayments(
    tailorId: tailorId,
  );
  
  setState(() {
    _pendingPayments = pendingPayments.map((data) => OrderPaymentInfo(
      order: Order.fromMap(data),
      customerName: data['customer_name'],
      customerPhone: data['customer_phone'],
      totalPaid: (data['total_paid'] as num?)?.toDouble() ?? 0.0,
      balance: (data['remaining_balance'] as num?)?.toDouble() ?? 0.0,
    )).toList();
  });
}
```

**Benefits**:
- Filters pending payments in database (faster)
- Calculates totals in SQL (more efficient)
- Sorted by delivery date automatically

---

### Pattern 3: Payment History Screen

**File**: `payment_history_screen.dart` or similar

#### Before:
```dart
// ❌ BAD: Separate queries for payments, orders, customers
Future<void> _loadPaymentHistory() async {
  final payments = await _db.getPayments(limit: 50);
  
  List<PaymentWithDetails> paymentList = [];
  for (var payment in payments) {
    final order = await _db.getOrderByUniqueId(payment.orderId);
    if (order != null) {
      final customer = await _db.getCustomerByUniqueId(order['customer_id']);
      
      paymentList.add(PaymentWithDetails(
        payment: payment,
        orderInfo: order,
        customerName: customer?['name'],
      ));
    }
  }
  
  setState(() {
    _payments = paymentList;
  });
}
```

#### After:
```dart
// ✅ GOOD: Single query with all details
Future<void> _loadPaymentHistory({
  DateTime? startDate,
  DateTime? endDate,
  String? method,
}) async {
  final paymentHistory = await _db.getPaymentHistoryWithDetails(
    tailorId: tailorId,
    method: method,
    startDate: startDate,
    endDate: endDate,
    limit: 50,
  );
  
  setState(() {
    _payments = paymentHistory.map((data) => PaymentWithDetails(
      payment: Payment.fromMap(data),
      customerName: data['customer_name'],
      customerPhone: data['customer_phone'],
      orderUniqueId: data['order_unique_id'],
      serviceType: data['service_type'],
      orderTotal: (data['order_total'] as num?)?.toDouble(),
      orderStatus: data['order_status'],
    )).toList();
  });
}
```

**Benefits**:
- Supports filtering (date range, method, customer)
- All data in single query
- Pagination support

---

### Pattern 4: Customer Profile/Stats

**File**: Customer detail or profile screen

#### Before:
```dart
// ❌ BAD: Multiple queries to get customer stats
Future<void> _loadCustomerStats(String customerId) async {
  final customer = await _db.getCustomerByUniqueId(customerId);
  final orders = await _db.getOrdersByCustomerId(customerId);
  final measurements = await _db.getMeasurementsByCustomerId(customerId);
  
  double totalRevenue = 0;
  double pendingBalance = 0;
  int paymentCount = 0;
  
  for (var order in orders) {
    totalRevenue += (order['total_amount'] as num).toDouble();
    pendingBalance += (order['balance_amount'] as num).toDouble();
    
    final payments = await _db.getPaymentsByOrderId(order['unique_id']);
    paymentCount += payments.length;
  }
  
  setState(() {
    _customer = customer;
    _totalOrders = orders.length;
    _totalRevenue = totalRevenue;
    _pendingBalance = pendingBalance;
    _totalMeasurements = measurements.length;
    _totalPayments = paymentCount;
  });
}
```

#### After:
```dart
// ✅ GOOD: Single query with aggregated stats
Future<void> _loadCustomerStats(String customerId) async {
  final customerStats = await _db.getCustomerWithStats(customerId);
  
  if (customerStats == null) {
    // Handle customer not found
    return;
  }
  
  setState(() {
    // Basic info
    _customer = Customer.fromMap(customerStats);
    
    // Order stats (from single query!)
    _totalOrders = customerStats['total_orders'] as int;
    _pendingOrders = customerStats['pending_orders'] as int;
    _inProgressOrders = customerStats['in_progress_orders'] as int;
    _readyOrders = customerStats['ready_orders'] as int;
    _deliveredOrders = customerStats['delivered_orders'] as int;
    
    // Financial stats
    _totalRevenue = (customerStats['total_revenue'] as num).toDouble();
    _totalAdvance = (customerStats['total_advance'] as num).toDouble();
    _pendingBalance = (customerStats['pending_balance'] as num).toDouble();
    
    // Other stats
    _totalMeasurements = customerStats['total_measurements'] as int;
    _totalPayments = customerStats['total_payments'] as int;
  });
}
```

**Benefits**:
- All stats calculated in database (faster)
- Single query instead of N+1
- More comprehensive data

---

### Pattern 5: Dashboard/Analytics

**File**: Dashboard or analytics screen

#### Using Payment Analytics:
```dart
// ✅ Get payment analytics
Future<void> _loadAnalytics() async {
  final analytics = await _db.getPaymentAnalyticsData(
    tailorId: tailorId,
    startDate: DateTime.now().subtract(Duration(days: 30)),
    endDate: DateTime.now(),
  );
  
  setState(() {
    _totalPayments = analytics['total_count'] as int;
    _totalAmount = (analytics['total_amount'] as num).toDouble();
    
    // Payment by method
    final byMethod = analytics['by_method'] as List;
    _cashPayments = byMethod.firstWhere(
      (m) => m['method'] == 'cash',
      orElse: () => {'amount': 0.0},
    )['amount'];
    _upiPayments = byMethod.firstWhere(
      (m) => m['method'] == 'upi',
      orElse: () => {'amount': 0.0},
    )['amount'];
    
    // Recent payments
    _recentPayments = (analytics['recent_payments'] as List)
        .map((data) => Payment.fromMap(data))
        .toList();
  });
}
```

---

## 🔍 How to Find Screens to Update

### Search Patterns:

1. **Find N+1 Query Loops**:
```dart
// Search for patterns like:
for (var order in orders) {
  await _db.getCustomer...  // ❌ N+1 problem
  await _db.getPayment...   // ❌ N+1 problem
}
```

2. **Find Individual Order Queries**:
```dart
// Search for:
getOrdersByTailorId
getOrdersByStatus
getOrdersByCustomerId
// Replace with: getOrdersWithFullDetails
```

3. **Find Payment Queries**:
```dart
// Search for:
getPaymentsByOrderId
getPayments
// Replace with: getPaymentHistoryWithDetails
```

4. **Find Customer Queries**:
```dart
// Search for:
getCustomerByUniqueId (in loops)
// Replace with: JOIN queries
```

---

## ✅ Testing Checklist

After updating each screen:

- [ ] Screen loads without errors
- [ ] Data displays correctly
- [ ] Customer names shown properly
- [ ] Payment totals calculated correctly
- [ ] Filtering works (if applicable)
- [ ] Pagination works (if applicable)
- [ ] Performance improved (check logs)
- [ ] No N+1 queries in logs

---

## 📊 Performance Verification

### Before Each Update:
```dart
// Add timing logs
final stopwatch = Stopwatch()..start();
await _loadOrders(); // Old method
stopwatch.stop();
print('Load time: ${stopwatch.elapsedMilliseconds}ms');
```

### After Each Update:
```dart
final stopwatch = Stopwatch()..start();
await _loadOrders(); // New method
stopwatch.stop();
print('Load time: ${stopwatch.elapsedMilliseconds}ms');
// Should be 10-20x faster!
```

---

## 🎯 Priority Order

Update screens in this order:

1. **HIGH PRIORITY** (Most Used):
   - OrdersMainScreen
   - PaymentCollectionScreen
   
2. **MEDIUM PRIORITY**:
   - PaymentHistoryScreen
   - OrderDetailScreen
   
3. **LOW PRIORITY**:
   - Dashboard/Analytics
   - Customer Profile

---

## 🆘 Common Issues & Solutions

### Issue 1: Field Name Changes
**Problem**: Old code uses different field names

**Solution**: Map new fields to old names
```dart
final customerName = data['customer_name'] ?? data['name'];
```

### Issue 2: Null Values
**Problem**: Optional fields might be null

**Solution**: Use null-aware operators
```dart
final totalPaid = (data['total_paid'] as num?)?.toDouble() ?? 0.0;
```

### Issue 3: Type Casting
**Problem**: Database returns dynamic types

**Solution**: Explicit casting
```dart
final count = data['payment_count'] as int;
final amount = (data['total_amount'] as num).toDouble();
```

---

## 📝 Code Review Checklist

Before submitting changes:

- [ ] Removed all N+1 query loops
- [ ] Using optimized database methods
- [ ] No redundant customer/payment queries
- [ ] Error handling in place
- [ ] Null safety maintained
- [ ] Performance improved (tested)
- [ ] Code documented
- [ ] No breaking changes to UI

---

## 🎉 Expected Results

After completing all updates:

- **Query Count**: Reduced by 80-90%
- **Load Time**: 10-20x faster for most screens
- **Database I/O**: Significantly reduced
- **User Experience**: Smoother, faster app
- **Code Quality**: Cleaner, more maintainable

---

**Next Step**: Start with OrdersMainScreen - it's the most critical screen to optimize!
