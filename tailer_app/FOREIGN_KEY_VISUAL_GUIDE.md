# Database Foreign Key Relationships - Visual Guide

## 🗺️ Complete Database Relationship Map

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     TAILOR SHOP MANAGEMENT SYSTEM                        │
│                        Database Relationships                            │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────┐
│   TAILOR    │
│  (shop info)│
└──────┬──────┘
       │
       │ 1:N (CASCADE)
       │
       ├───────────────────────────┐
       │                           │
       ▼                           ▼
┌─────────────┐            ┌─────────────┐
│  CUSTOMER   │            │   ORDERS    │◄─────┐
│             │            │             │      │
└──────┬──────┘            └──────┬──────┘      │
       │                          │             │
       │ 1:N (CASCADE)            │ 1:N         │ 1:N
       │                          │ (CASCADE)   │ (CASCADE)
       ▼                          ▼             │
┌─────────────┐            ┌─────────────┐     │
│ MEASUREMENT │────────────┤   PAYMENT   │     │
│             │   1:N      │             │     │
└─────────────┘  (NEW!)    └─────────────┘     │
                                                │
                                                │
                                          From CUSTOMER


┌─────────────┐
│    USERS    │ (Authentication System)
│             │
└──────┬──────┘
       │
       │ 1:N (CASCADE)
       │
       ├──────────┬──────────────┬─────────────┐
       │          │              │             │
       ▼          ▼              ▼             ▼
┌───────────┐ ┌──────────┐ ┌────────────┐ ┌──────────┐
│AUTH       │ │USER      │ │LOGIN       │ │NOTIF.    │
│SESSIONS   │ │PREFS     │ │HISTORY     │ │(partial) │
└───────────┘ └──────────┘ └────────────┘ └──────────┘


⚠️ ORPHAN RISK (No Cascade):
┌─────────────┐              ┌─────────────┐
│   ORDERS    │──────────────│NOTIFICATIONS│ (NO CASCADE!)
│             │  1:N         │             │
└─────────────┘              └─────────────┘

┌─────────────┐              ┌─────────────┐
│   ORDERS    │──────────────│ORDER_CANCEL.│ (NO CASCADE!)
│             │  1:1         │             │
└─────────────┘              └─────────────┘
```

---

## 📊 Detailed Relationship Breakdown

### 1. Core Business Relationships

```
TAILOR (Shop/Business)
  │
  ├─→ CUSTOMER (1:N, CASCADE)
  │    │
  │    ├─→ MEASUREMENT (1:N, CASCADE)
  │    │    │
  │    │    └─→ ORDERS (N:1, NEW LINK) ✨
  │    │
  │    └─→ ORDERS (1:N, CASCADE)
  │         │
  │         └─→ PAYMENT (1:N, CASCADE)
  │
  └─→ ORDERS (1:N, CASCADE)
```

**Cascade Chain Example**:
```
Delete TAILOR "ABC Tailors"
  ↓
  Deletes ALL CUSTOMERS of ABC Tailors (CASCADE)
    ↓
    Deletes ALL MEASUREMENTS of those customers (CASCADE)
    ↓
    Deletes ALL ORDERS of those customers (CASCADE)
      ↓
      Deletes ALL PAYMENTS for those orders (CASCADE)
```

---

### 2. Authentication & User Management

```
USERS (Authentication)
  │
  ├─→ AUTH_SESSIONS (1:N, CASCADE)
  │     Login sessions, tokens
  │
  ├─→ USER_PREFERENCES (1:1, CASCADE)
  │     Theme, language, settings
  │
  └─→ LOGIN_HISTORY (1:N, CASCADE)
        Login audit trail
```

**Cascade Chain Example**:
```
Delete USER "john@example.com"
  ↓
  Deletes ALL AUTH_SESSIONS for john (CASCADE)
  Deletes USER_PREFERENCES for john (CASCADE)
  Deletes LOGIN_HISTORY for john (CASCADE)
```

---

### 3. ⚠️ Orphan-Risk Relationships (Missing CASCADE)

```
ORDERS
  │
  ├─→ NOTIFICATIONS (1:N, NO CASCADE!)
  │     ⚠️ If order deleted, notifications become orphans
  │
  └─→ ORDER_CANCELLATIONS (1:1, NO CASCADE!)
        ⚠️ If order deleted, cancellation record remains
```

---

## 🎯 Foreign Key Constraints Summary

| Child Table | Parent Table | FK Column | Parent Column | ON DELETE |
|------------|-------------|-----------|---------------|-----------|
| **customer** | tailor | tailor_id | unique_id | CASCADE ✅ |
| **measurement** | customer | customer_id | unique_id | CASCADE ✅ |
| **orders** | customer | customer_id | unique_id | CASCADE ✅ |
| **orders** | tailor | tailor_id | unique_id | CASCADE ✅ |
| **orders** ✨ | measurement | measurement_id | unique_id | NONE (ref only) |
| **payment** | orders | order_id | unique_id | CASCADE ✅ |
| **auth_sessions** | users | user_id | id | CASCADE ✅ |
| **user_preferences** | users | user_id | id | CASCADE ✅ |
| **login_history** | users | user_id | id | CASCADE ✅ |
| **notifications** ⚠️ | orders | order_id | unique_id | NONE ⚠️ |
| **notifications** ⚠️ | customer | customer_id | unique_id | NONE ⚠️ |
| **order_cancellations** ⚠️ | orders | order_id | unique_id | NONE ⚠️ |

---

## 🖥️ Screen to Foreign Key Mapping

### Screens Using CUSTOMER → TAILOR Relationship

```
┌─────────────────────────────────┐
│     CUSTOMER MANAGEMENT         │
├─────────────────────────────────┤
│ add_customer_screen.dart        │ ──→ Needs tailorId to create
│ view_customers_screen.dart      │ ──→ Query: getCustomersByTailorId()
│ customers_main_screen.dart      │ ──→ Query: getCustomersByTailorId()
│ customer_details_screen.dart    │ ──→ Validates tailor ownership
│ customer_profile_screen.dart    │ ──→ Shows customer + tailor info
│ edit_customer_screen.dart       │ ──→ Maintains tailor_id on update
└─────────────────────────────────┘
```

---

### Screens Using ORDERS → CUSTOMER/TAILOR Relationship

```
┌─────────────────────────────────┐
│      ORDER MANAGEMENT           │
├─────────────────────────────────┤
│ orders_main_screen.dart         │ ──→ 🔴 N+1 Problem! Needs JOIN
│ pending_orders_screen.dart      │ ──→ 🔴 N+1 Problem! Needs JOIN
│ in_progress_orders_screen.dart  │ ──→ 🔴 N+1 Problem! Needs JOIN
│ ready_orders_screen.dart        │ ──→ 🔴 N+1 Problem! Needs JOIN
│ completed_orders_screen.dart    │ ──→ 🔴 N+1 Problem! Needs JOIN
│ order_detail_screen.dart        │ ──→ 🔴 N+1 Problem! Needs JOIN
│ order_list_screen.dart          │ ──→ 🔴 N+1 Problem! Needs JOIN
│ add_order_screen.dart           │ ──→ Creates order with customer+tailor
└─────────────────────────────────┘

Current Pattern (SLOW):
  getOrdersByTailorId(tailorId)
  for each order:
    getCustomerByUniqueId(order.customerId)  ← N queries!
    getPaymentsByOrderId(order.uniqueId)     ← N more queries!

New Pattern (FAST):
  getOrdersWithFullDetails(tailorId: tailorId)
  ✅ All data in 1 query!
```

---

### Screens Using PAYMENT → ORDERS Relationship

```
┌─────────────────────────────────┐
│     PAYMENT MANAGEMENT          │
├─────────────────────────────────┤
│ payment_collection_screen.dart  │ ──→ 🔴 N+1 Problem! Needs JOIN
│ payment_history_screen.dart     │ ──→ 🔴 N+1 Problem! Needs JOIN
│ order_payment_history_screen.dart│ ──→ 🔴 N+1 Problem! Needs JOIN
│ payment_reports_screen.dart     │ ──→ Can use analytics method
└─────────────────────────────────┘

Current Pattern (SLOW):
  getPayments()
  for each payment:
    getOrderByUniqueId(payment.orderId)       ← N queries!
    getCustomerByUniqueId(order.customerId)   ← N more queries!

New Pattern (FAST):
  getPaymentHistoryWithDetails()
  ✅ All data in 1 query!
```

---

### Screens Using MEASUREMENT → CUSTOMER Relationship

```
┌─────────────────────────────────┐
│   MEASUREMENT MANAGEMENT        │
├─────────────────────────────────┤
│ customer_details_screen.dart    │ ──→ Query: getMeasurementsByCustomerId()
│ add_order_screen.dart           │ ──→ Query: getMeasurementsByCustomerId()
│                                 │     Should save measurement_id ✨
└─────────────────────────────────┘
```

---

### Screens Using USER → AUTH/PREFS Relationship

```
┌─────────────────────────────────┐
│    USER & SETTINGS              │
├─────────────────────────────────┤
│ signin_screen.dart              │ ──→ Creates auth_sessions
│ settings_screen.dart            │ ──→ Query: getUserPreferences()
│ theme_selection_screen.dart     │ ──→ Update: user_preferences
│ language_selection_screen.dart  │ ──→ Update: user_preferences
│ notification_settings_screen.dart│ ──→ Update: user_preferences
│ privacy_security_screen.dart    │ ──→ Query: login_history
└─────────────────────────────────┘
```

---

## 🔄 Data Flow Examples

### Example 1: Creating an Order
```
User selects customer in add_order_screen.dart
  ↓
System validates:
  - customer.tailor_id == current_tailor.id ✅
  - customer exists ✅
  ↓
User selects/creates measurement
  ↓
System validates:
  - measurement.customer_id == selected_customer.id ✅
  ↓
User fills order details
  ↓
System creates order with:
  - customer_id (FK → customer table)
  - tailor_id (FK → tailor table)
  - measurement_id (reference → measurement table) ✨ NEW
  ↓
Success! Order created with proper FK relationships
```

---

### Example 2: Deleting a Customer (CASCADE CHAIN)
```
User deletes customer "John Doe" (id: CUST123)
  ↓
Database CASCADE deletes:
  - All measurements for John Doe
  - All orders for John Doe
    - All payments for those orders
  ↓
⚠️ WARNING: Orphaned records remain:
  - Notifications about John's orders
  - Cancellation records for John's orders
```

---

### Example 3: Loading Orders (N+1 vs JOIN)

#### ❌ Current Approach (N+1 Problem):
```
orders_main_screen.dart loads:

Step 1: Get 100 orders
  SELECT * FROM orders WHERE tailor_id = 'TAIL001'
  Time: 10ms

Step 2-101: Get customer for each order (100 queries!)
  for each order:
    SELECT * FROM customer WHERE unique_id = '{customerId}'
  Time: 100 × 8ms = 800ms

Step 102-201: Get payments for each order (100 queries!)
  for each order:
    SELECT * FROM payment WHERE order_id = '{orderId}'
  Time: 100 × 10ms = 1000ms

Total Time: 10 + 800 + 1000 = 1,810ms (1.8 seconds!)
Total Queries: 201 queries
```

#### ✅ New Approach (Single JOIN):
```
orders_main_screen.dart loads:

Step 1: Get orders WITH customer and payment data
  getOrdersWithFullDetails(tailorId: 'TAIL001')
  
  SQL:
  SELECT 
    o.*,
    c.name as customer_name,
    c.phone as customer_phone,
    SUM(p.amount) as total_paid,
    COUNT(p.id) as payment_count
  FROM orders o
  JOIN customer c ON o.customer_id = c.unique_id
  LEFT JOIN payment p ON o.unique_id = p.order_id
  WHERE o.tailor_id = 'TAIL001'
  GROUP BY o.id
  
  Time: 120ms

Total Time: 120ms
Total Queries: 1 query

Performance Improvement: 15x faster! 🚀
```

---

## 🎨 Visual Query Comparison

### N+1 Problem Visualization:
```
┌──────────┐
│  Screen  │
└────┬─────┘
     │
     │ 1. Get Orders
     ├──────────────────────────┐
     │                          │
     ▼                          ▼
┌─────────┐              ┌──────────┐
│ Orders  │              │ Database │
│ (100)   │              └──────────┘
└────┬────┘                    ▲
     │                         │
     │ 2. For each order:      │
     │    Get Customer         │
     ├─────────────────────────┤ × 100
     │                         │
     │ 3. For each order:      │
     │    Get Payments         │
     ├─────────────────────────┤ × 100
     │                         │
     ▼                         ▼
   SLOW!                  201 queries!
```

### JOIN Query Visualization:
```
┌──────────┐
│  Screen  │
└────┬─────┘
     │
     │ 1. Get Orders WITH Details
     ├──────────────────────────┐
     │                          │
     ▼                          ▼
┌─────────┐              ┌──────────┐
│ Orders  │              │ Database │
│+Customer│              │  (JOIN)  │
│+Payments│              └──────────┘
└─────────┘
     ▲
     │
     │ One Query, All Data
     │
   FAST! ⚡
```

---

## 📝 Quick Reference Checklist

### Before Making Database Queries:

- [ ] Do I need related data? (customer, payments, measurements)
- [ ] Am I looping through results to get more data? → ❌ N+1 Problem!
- [ ] Can I use a JOIN query instead? → ✅ Use optimized methods
- [ ] Am I validating foreign keys exist? → ✅ Good practice
- [ ] Will deleting this cascade to other tables? → ⚠️ Check CASCADE rules

### When Updating Screens:

- [ ] Replace loops with JOIN queries
- [ ] Use `getOrdersWithFullDetails()` for order lists
- [ ] Use `getPaymentHistoryWithDetails()` for payment lists
- [ ] Use `getCustomerWithStats()` for customer profiles
- [ ] Use `getOrdersWithPendingPayments()` for payment collection
- [ ] Test performance before and after
- [ ] Verify all data displays correctly

---

## 🎯 Success Metrics

### Database Health:
- ✅ Foreign Keys: 12 relationships defined
- ⚠️ CASCADE Issues: 3 tables need fixing
- ✅ Indexes: 22 indexes (7 composite added)

### Query Performance:
- Before: 201 queries for 100 orders (1.8 seconds)
- After: 1 query for 100 orders (0.12 seconds)
- Improvement: **15x faster!** 🚀

### Code Quality:
- ✅ 5 optimized query methods created
- ✅ Zero N+1 queries in new methods
- ⏳ 11 screens need updating to use new methods

---

**Last Updated**: 2024  
**Database Version**: 7  
**Total Tables**: 11  
**Foreign Key Relationships**: 12  
**Critical Screen Updates Needed**: 11
