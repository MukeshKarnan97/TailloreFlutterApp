# Foreign Key Relationships & Screen Analysis

## 📊 Complete Foreign Key Mapping

### Database Foreign Key Relationships

---

## 1. CUSTOMER TABLE
**Parent**: `tailor`  
**Foreign Key**: `tailor_id` → `tailor.unique_id`  
**Cascade**: ON DELETE CASCADE

```sql
FOREIGN KEY (tailor_id) REFERENCES tailor (unique_id) ON DELETE CASCADE
```

### Relationship:
```
tailor (1) ──< (N) customer
```

**Meaning**: 
- Each customer belongs to ONE tailor
- When a tailor is deleted, ALL their customers are deleted

### Screens Using This Relationship:

#### ✅ Direct Usage (Customer-Tailor Link):
1. **`add_customer_screen.dart`**
   - Purpose: Create new customer
   - Usage: Requires `tailorId` when inserting customer
   - Method: `insertCustomer()` or `insertCustomerWithoutForeignKeyCheck()`
   - **Status**: ⚠️ Uses FK bypass method (needs review)

2. **`view_customers_screen.dart`**
   - Purpose: List all customers for a tailor
   - Query: `getCustomersByTailorId(tailorId)`
   - **Status**: ✅ Properly uses FK relationship

3. **`customers_main_screen.dart`**
   - Purpose: Main customer management
   - Query: `getCustomersByTailorId(tailorId)`
   - **Status**: ✅ Properly uses FK relationship

4. **`customer_details_screen.dart`**
   - Purpose: View customer details
   - Usage: Displays customer info + validates tailor ownership
   - **Status**: ✅ Properly uses FK relationship

5. **`customer_profile_screen.dart`**
   - Purpose: Customer profile with stats
   - Recommended: Use `getCustomerWithStats(customerId)`
   - **Status**: ⏳ Can be optimized with new method

6. **`edit_customer_screen.dart`**
   - Purpose: Edit customer information
   - Usage: Updates customer, maintains tailor_id
   - **Status**: ✅ Properly uses FK relationship

---

## 2. MEASUREMENT TABLE
**Parent**: `customer`  
**Foreign Key**: `customer_id` → `customer.unique_id`  
**Cascade**: ON DELETE CASCADE

```sql
FOREIGN KEY (customer_id) REFERENCES customer (unique_id) ON DELETE CASCADE
```

### Relationship:
```
customer (1) ──< (N) measurement
```

**Meaning**:
- Each measurement belongs to ONE customer
- When a customer is deleted, ALL their measurements are deleted

### Screens Using This Relationship:

#### ✅ Direct Usage (Measurement-Customer Link):
1. **`customer_details_screen.dart`**
   - Purpose: View customer with measurements
   - Query: `getMeasurementsByCustomerId(customerId)`
   - Display: Shows all measurements for customer
   - **Status**: ✅ Properly uses FK relationship

2. **`add_order_screen.dart`**
   - Purpose: Create order (uses measurements)
   - Query: `getMeasurementsByCustomerId(customerId)`
   - Usage: Selects measurement when creating order
   - **Status**: ⏳ Should also save `measurement_id` in order

3. **`customer_profile_screen.dart`**
   - Purpose: Customer profile
   - Query: `getMeasurementsByCustomerId(customerId)`
   - Recommended: Use `getCustomerWithStats()` for count
   - **Status**: ⏳ Can be optimized

---

## 3. ORDERS TABLE
**Parents**: `customer`, `tailor`, ~~`measurement`~~ (NEW)  
**Foreign Keys**:
- `customer_id` → `customer.unique_id` (CASCADE)
- `tailor_id` → `tailor.unique_id` (CASCADE)
- `measurement_id` → `measurement.unique_id` ✨ **NEW** (No cascade yet)

```sql
FOREIGN KEY (customer_id) REFERENCES customer (unique_id) ON DELETE CASCADE,
FOREIGN KEY (tailor_id) REFERENCES tailor (unique_id) ON DELETE CASCADE
-- NEW (not enforced as FK yet, just reference):
-- measurement_id → measurement.unique_id
```

### Relationship:
```
customer (1) ──< (N) orders
tailor (1) ──< (N) orders
measurement (1) ──< (N) orders ✨ NEW
```

**Meaning**:
- Each order belongs to ONE customer, ONE tailor, and optionally ONE measurement
- When customer is deleted, their orders are deleted
- When tailor is deleted, their orders are deleted
- When measurement is deleted, order keeps measurement_id (no cascade)

### Screens Using This Relationship:

#### ✅ Order-Customer-Tailor Relationship:

1. **`orders_main_screen.dart`** ⚠️ **CRITICAL - N+1 PROBLEM**
   - Purpose: Main orders dashboard
   - Current Query Pattern:
     ```dart
     // ❌ N+1 Problem:
     getOrdersByTailorId(tailorId)
     for each order:
       getCustomerByUniqueId(order.customerId) // N queries!
       getPaymentsByOrderId(order.uniqueId)    // N queries!
     ```
   - **Status**: 🔴 **NEEDS UPDATE**
   - **Solution**: Use `getOrdersWithFullDetails(tailorId: tailorId)`

2. **`pending_orders_screen.dart`** ⚠️ **N+1 PROBLEM**
   - Purpose: Show pending orders
   - Current Query: `getOrdersByStatus(tailorId, 'pending')`
   - Problem: Loops through orders to get customer details
   - **Status**: 🔴 **NEEDS UPDATE**
   - **Solution**: Use `getOrdersWithFullDetails(tailorId: tailorId, status: 'pending')`

3. **`in_progress_orders_screen.dart`** ⚠️ **N+1 PROBLEM**
   - Purpose: Show in-progress orders
   - Current Query: `getOrdersByStatus(tailorId, 'in_progress')`
   - Problem: Same N+1 issue
   - **Status**: 🔴 **NEEDS UPDATE**
   - **Solution**: Use `getOrdersWithFullDetails(tailorId: tailorId, status: 'in_progress')`

4. **`ready_orders_screen.dart`** ⚠️ **N+1 PROBLEM**
   - Purpose: Show ready orders
   - Current Query: `getOrdersByStatus(tailorId, 'ready')`
   - **Status**: 🔴 **NEEDS UPDATE**
   - **Solution**: Use `getOrdersWithFullDetails(tailorId: tailorId, status: 'ready')`

5. **`completed_orders_screen.dart`** ⚠️ **N+1 PROBLEM**
   - Purpose: Show completed/delivered orders
   - Current Query: `getOrdersByStatus(tailorId, 'delivered')`
   - **Status**: 🔴 **NEEDS UPDATE**
   - **Solution**: Use `getOrdersWithFullDetails(tailorId: tailorId, status: 'delivered')`

6. **`order_detail_screen.dart`**
   - Purpose: Show single order details
   - Current: Gets order, then customer, then payments separately
   - **Status**: 🔴 **NEEDS UPDATE**
   - **Solution**: Use `getOrdersWithFullDetails()` with limit 1

7. **`order_list_screen.dart`**
   - Purpose: Generic order list
   - **Status**: 🔴 **NEEDS UPDATE**
   - **Solution**: Use `getOrdersWithFullDetails()`

8. **`add_order_screen.dart`**
   - Purpose: Create new order
   - FK Usage:
     - Requires `customerId` (must exist in customer table)
     - Requires `tailorId` (must exist in tailor table)
     - Should save `measurementId` ✨ **NEW**
   - Method: `insertOrder()` or `insertOrderWithoutTailorForeignKeyCheck()`
   - **Status**: ⚠️ **NEEDS UPDATE** - Should include measurementId

9. **`customer_details_screen.dart`**
   - Purpose: View customer with their orders
   - Query: `getOrdersByCustomerId(customerId)`
   - **Status**: ⏳ Can use `getOrdersWithFullDetails(customerId: ...)`

10. **`dashboard_screen.dart`**
    - Purpose: Dashboard with order stats
    - Query: `getTailorDashboard(tailorId)`
    - **Status**: ✅ Uses optimized dashboard query

---

## 4. PAYMENT TABLE
**Parent**: `orders`  
**Foreign Key**: `order_id` → `orders.unique_id`  
**Cascade**: ON DELETE CASCADE

```sql
FOREIGN KEY (order_id) REFERENCES orders (unique_id) ON DELETE CASCADE
```

### Relationship:
```
orders (1) ──< (N) payment
```

**Meaning**:
- Each payment belongs to ONE order
- When an order is deleted, ALL its payments are deleted

### Screens Using This Relationship:

#### ✅ Payment-Order Relationship:

1. **`payment_collection_screen.dart`** ⚠️ **CRITICAL - N+1 PROBLEM**
   - Purpose: Collect payments for pending orders
   - Current Pattern:
     ```dart
     // ❌ N+1 Problem:
     getOrdersByStatus('pending')
     for each order:
       getCustomerByUniqueId(order.customerId)  // N queries!
       getPaymentsByOrderId(order.uniqueId)     // N queries!
       calculate balance manually
     ```
   - **Status**: 🔴 **NEEDS UPDATE**
   - **Solution**: Use `getOrdersWithPendingPayments(tailorId: tailorId)`
   - **Benefit**: Returns orders WITH customer details, total_paid, remaining_balance

2. **`payment_history_screen.dart`** ⚠️ **CRITICAL - N+1 PROBLEM**
   - Purpose: Show all payments
   - Current Pattern:
     ```dart
     // ❌ N+1 Problem:
     getPayments()
     for each payment:
       getOrderByUniqueId(payment.orderId)      // N queries!
       getCustomerByUniqueId(order.customerId)  // N queries!
     ```
   - **Status**: 🔴 **NEEDS UPDATE**
   - **Solution**: Use `getPaymentHistoryWithDetails(tailorId: tailorId)`
   - **Benefit**: Single JOIN query with order and customer details

3. **`order_payment_history_screen.dart`** ⚠️ **N+1 PROBLEM**
   - Purpose: Show payments for specific order
   - Current: `getPaymentsByOrderId(orderId)`
   - Also gets: Order details, customer details separately
   - **Status**: 🔴 **NEEDS UPDATE**
   - **Solution**: Use `getPaymentHistoryWithDetails(orderId: ...)`

4. **`order_detail_screen.dart`**
   - Purpose: Show order with payment info
   - Query: `getPaymentsByOrderId(orderId)` + customer info
   - **Status**: 🔴 **NEEDS UPDATE**
   - **Solution**: Use `getOrdersWithFullDetails()` (includes payment count and total)

5. **`payment_reports_screen.dart`**
   - Purpose: Payment analytics and reports
   - **Status**: ⏳ **CAN BE OPTIMIZED**
   - **Solution**: Use `getPaymentAnalyticsData()`
   - **Benefit**: Pre-calculated totals, grouping by method, date ranges

---

## 5. AUTH_SESSIONS TABLE
**Parent**: `users`  
**Foreign Key**: `user_id` → `users.id`  
**Cascade**: ON DELETE CASCADE

```sql
FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
```

### Relationship:
```
users (1) ──< (N) auth_sessions
```

**Meaning**:
- Each session belongs to ONE user
- When user is deleted, all their sessions are deleted

### Screens Using This Relationship:

1. **`signin_screen.dart`**
   - Purpose: User login
   - Creates: auth_session record after successful login
   - **Status**: ✅ Properly uses FK relationship

2. **Authentication Service** (not a screen)
   - Manages: Session creation, validation, cleanup
   - **Status**: ✅ Properly uses FK relationship

---

## 6. USER_PREFERENCES TABLE
**Parent**: `users`  
**Foreign Key**: `user_id` → `users.id`  
**Cascade**: ON DELETE CASCADE

```sql
FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
```

### Relationship:
```
users (1) ──> (1) user_preferences
```

**Meaning**:
- Each user has ONE preferences record
- When user is deleted, their preferences are deleted

### Screens Using This Relationship:

1. **`settings_screen.dart`**
   - Purpose: User settings management
   - Query: `getUserPreferences(userId)`
   - Update: `updateUserPreferences(userId, ...)`
   - **Status**: ✅ Properly uses FK relationship

2. **`theme_selection_screen.dart`**
   - Purpose: Theme preferences
   - Update: `updateUserPreferences(userId, {'theme_mode': ...})`
   - **Status**: ✅ Properly uses FK relationship

3. **`language_selection_screen.dart`**
   - Purpose: Language preferences
   - Update: `updateUserPreferences(userId, {'language': ...})`
   - **Status**: ✅ Properly uses FK relationship

4. **`notification_settings_screen.dart`**
   - Purpose: Notification preferences
   - Update: `updateUserPreferences(userId, {'notifications_enabled': ...})`
   - **Status**: ✅ Properly uses FK relationship

---

## 7. LOGIN_HISTORY TABLE
**Parent**: `users`  
**Foreign Key**: `user_id` → `users.id`  
**Cascade**: ON DELETE CASCADE

```sql
FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
```

### Relationship:
```
users (1) ──< (N) login_history
```

**Meaning**:
- Each login record belongs to ONE user
- When user is deleted, their login history is deleted

### Screens Using This Relationship:

1. **`privacy_security_screen.dart`**
   - Purpose: Show login history for security
   - Query: Get login_history by user_id
   - **Status**: ✅ Properly uses FK relationship (if implemented)

2. **Authentication Service**
   - Logs: Every login attempt
   - **Status**: ✅ Properly uses FK relationship

---

## 8. NOTIFICATIONS TABLE
**Parents**: `orders`, `customer`  
**Foreign Keys**:
- `order_id` → `orders.unique_id` (NO CASCADE)
- `customer_id` → `customer.unique_id` (NO CASCADE)

```sql
FOREIGN KEY (order_id) REFERENCES orders (unique_id),
FOREIGN KEY (customer_id) REFERENCES customer (unique_id)
```

### Relationship:
```
orders (1) ──< (N) notifications
customer (1) ──< (N) notifications
```

**Meaning**:
- Each notification relates to ONE order and/or ONE customer
- When order/customer is deleted, notification remains (orphaned)
- ⚠️ **ISSUE**: Should probably have ON DELETE SET NULL or CASCADE

### Screens Using This Relationship:

1. **Notification System** (if implemented)
   - Shows: Notifications related to orders/customers
   - **Status**: ⚠️ FK exists but may create orphaned records

---

## 9. ORDER_CANCELLATIONS TABLE
**Parent**: `orders`  
**Foreign Key**: `order_id` → `orders.unique_id` (NO CASCADE)

```sql
FOREIGN KEY (order_id) REFERENCES orders (unique_id)
```

### Relationship:
```
orders (1) ──> (1) order_cancellations
```

**Meaning**:
- Each cancellation record relates to ONE order
- When order is deleted, cancellation record remains (orphaned)
- ⚠️ **ISSUE**: Should probably have ON DELETE CASCADE

### Screens Using This Relationship:

1. **`order_detail_screen.dart`**
   - Shows: Cancellation info if order is cancelled
   - **Status**: ✅ Uses FK to link cancellation to order

2. **Order Cancellation Dialog/Widget**
   - Creates: Cancellation record when order is cancelled
   - **Status**: ✅ Properly uses FK relationship

---

## 🔍 Summary of Foreign Key Relationships

### Cascade Deletion Chains:

```
tailor (deleted)
  └─> customer (CASCADE deleted)
      ├─> measurement (CASCADE deleted)
      └─> orders (CASCADE deleted)
          └─> payment (CASCADE deleted)

users (deleted)
  ├─> auth_sessions (CASCADE deleted)
  ├─> user_preferences (CASCADE deleted)
  └─> login_history (CASCADE deleted)
```

### ⚠️ Orphan Risk (NO CASCADE):
```
orders (deleted)
  ├─> notifications (ORPHANED - remains in database)
  └─> order_cancellations (ORPHANED - remains in database)
```

---

## 🚨 Critical Issues Identified

### 1. N+1 Query Problems (HIGH PRIORITY)

**Affected Screens** (11 screens):
- ✅ `orders_main_screen.dart`
- ✅ `pending_orders_screen.dart`
- ✅ `in_progress_orders_screen.dart`
- ✅ `ready_orders_screen.dart`
- ✅ `completed_orders_screen.dart`
- ✅ `order_detail_screen.dart`
- ✅ `order_list_screen.dart`
- ✅ `payment_collection_screen.dart`
- ✅ `payment_history_screen.dart`
- ✅ `order_payment_history_screen.dart`
- ✅ `customer_details_screen.dart` (partial)

**Problem**: These screens loop through results and make additional queries
**Impact**: 10-20x slower than necessary
**Solution**: Use new optimized methods with JOINs

---

### 2. Missing Cascade Deletes (MEDIUM PRIORITY)

**Affected Tables**:
- `notifications.order_id` - Should CASCADE or SET NULL
- `notifications.customer_id` - Should CASCADE or SET NULL
- `order_cancellations.order_id` - Should CASCADE

**Problem**: Deleting orders/customers leaves orphaned records
**Impact**: Database bloat, referential integrity issues
**Solution**: Add proper CASCADE or SET NULL constraints

---

### 3. Foreign Key Bypass Methods (MEDIUM PRIORITY)

**Methods Using FK Bypass**:
- `insertCustomerWithoutForeignKeyCheck()`
- `insertOrderWithoutTailorForeignKeyCheck()`

**Problem**: Used during development, should be removed in production
**Impact**: Can create invalid references
**Solution**: 
- Ensure proper tailor/user exists before creating customers/orders
- Remove bypass methods or mark as deprecated

---

### 4. Missing measurement_id Usage (MEDIUM PRIORITY)

**Affected Screen**:
- `add_order_screen.dart`

**Problem**: Orders created without linking to measurement table
**Current**: Stores measurements as JSON
**New**: Should save `measurement_id` reference
**Impact**: Can't use JOIN queries efficiently
**Solution**: Update order creation to include `measurementId`

---

## 📋 Screen Update Priority Matrix

### 🔴 HIGH PRIORITY (Performance Critical):
1. **orders_main_screen.dart** - Most used screen
2. **payment_collection_screen.dart** - Heavy queries
3. **payment_history_screen.dart** - Heavy queries
4. **pending_orders_screen.dart** - Frequently accessed

### 🟡 MEDIUM PRIORITY:
5. **order_detail_screen.dart** - Moderate usage
6. **in_progress_orders_screen.dart** - Moderate usage
7. **ready_orders_screen.dart** - Moderate usage
8. **completed_orders_screen.dart** - Moderate usage
9. **add_order_screen.dart** - Add measurementId support

### 🟢 LOW PRIORITY (Nice to Have):
10. **customer_details_screen.dart** - Already works, can optimize
11. **customer_profile_screen.dart** - Can use getCustomerWithStats()
12. **payment_reports_screen.dart** - Can use getPaymentAnalyticsData()

---

## 🎯 Recommended Action Plan

### Week 1: Critical Performance Fixes
- [ ] Update `orders_main_screen.dart` → Use `getOrdersWithFullDetails()`
- [ ] Update `payment_collection_screen.dart` → Use `getOrdersWithPendingPayments()`
- [ ] Update `payment_history_screen.dart` → Use `getPaymentHistoryWithDetails()`
- [ ] Test performance improvements

### Week 2: Order Screen Updates
- [ ] Update `pending_orders_screen.dart`
- [ ] Update `in_progress_orders_screen.dart`
- [ ] Update `ready_orders_screen.dart`
- [ ] Update `completed_orders_screen.dart`
- [ ] Update `order_detail_screen.dart`

### Week 3: Remaining Optimizations
- [ ] Update `add_order_screen.dart` - Add measurementId
- [ ] Update `customer_profile_screen.dart` - Use getCustomerWithStats()
- [ ] Update `payment_reports_screen.dart` - Use analytics method

### Week 4: Database Cleanup
- [ ] Fix CASCADE issues on notifications and order_cancellations
- [ ] Remove or deprecate FK bypass methods
- [ ] Add database tests
- [ ] Performance benchmarking

---

## 📖 FK Relationship Best Practices

### ✅ DO:
- Always use JOIN queries when accessing related data
- Use optimized methods like `getOrdersWithFullDetails()`
- Validate foreign keys exist before insertion
- Use CASCADE DELETE when child data is meaningless without parent
- Use SET NULL when orphaned records should be kept

### ❌ DON'T:
- Loop through results making N queries for related data
- Bypass foreign key constraints in production
- Store duplicate data that can be joined
- Delete parent records without considering cascades
- Leave orphaned records in database

---

## 🔗 Quick Reference: Which Method to Use

| Screen Type | Old Method (Slow) | New Method (Fast) |
|------------|-------------------|-------------------|
| Orders list | `getOrdersByTailorId()` + loop | `getOrdersWithFullDetails()` |
| Orders by status | `getOrdersByStatus()` + loop | `getOrdersWithFullDetails(status: ...)` |
| Pending payments | `getOrdersByStatus()` + calculate | `getOrdersWithPendingPayments()` |
| Payment history | `getPayments()` + loop | `getPaymentHistoryWithDetails()` |
| Customer stats | Multiple queries + loop | `getCustomerWithStats()` |
| Payment analytics | Multiple queries + calculate | `getPaymentAnalyticsData()` |

---

**Generated**: 2024  
**Database Version**: 7  
**Total FK Relationships**: 9  
**Screens Analyzed**: 40+  
**Critical Updates Needed**: 11 screens
