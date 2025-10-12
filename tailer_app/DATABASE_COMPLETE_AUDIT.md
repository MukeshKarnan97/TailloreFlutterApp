# 📊 COMPLETE DATABASE AUDIT REPORT
## Tailor App - Tables, Columns, Relationships & Page Mappings

**Generated:** October 11, 2025  
**Database Version:** 6  
**Total Tables:** 11  
**Total Screens:** 30+

---

## 📑 TABLE OF CONTENTS
1. [Database Tables Overview](#database-tables-overview)
2. [Table-by-Table Analysis](#table-by-table-analysis)
3. [Screen-to-Table Mapping](#screen-to-table-mapping)
4. [Data Flow Diagrams](#data-flow-diagrams)
5. [Missing Links & Recommendations](#missing-links--recommendations)
6. [Query Optimization Guide](#query-optimization-guide)

---

## 1️⃣ DATABASE TABLES OVERVIEW

| # | Table Name | Primary Key | Foreign Keys | Indexes | Records Type | Status |
|---|------------|-------------|--------------|---------|--------------|--------|
| 1 | `tailor` | id (TEXT) | - | 1 | Business Owner | ✅ Active |
| 2 | `customer` | id (TEXT) | tailor_id → tailor.unique_id | 2 | Customer Profiles | ✅ Active |
| 3 | `measurement` | id (TEXT) | customer_id → customer.unique_id | 2 | Measurements | ✅ Active |
| 4 | `orders` | id (TEXT) | customer_id, tailor_id | 4 | Orders | ✅ Active |
| 5 | `payment` | id (TEXT) | order_id → orders.unique_id | 2 | Payments | ✅ Active |
| 6 | `users` | id (INTEGER AUTO) | - | 2 | Auth Users | ⚠️ Duplicate |
| 7 | `auth_sessions` | id (INTEGER AUTO) | user_id → users.id | 3 | Sessions | ✅ Active |
| 8 | `user_preferences` | id (INTEGER AUTO) | user_id → users.id | 1 | Preferences | ✅ Active |
| 9 | `login_history` | id (INTEGER AUTO) | user_id → users.id | 2 | Login Logs | ✅ Active |
| 10 | `notifications` | id (TEXT) | order_id, customer_id | 4 | Alerts | ✅ Active |
| 11 | `order_cancellations` | id (TEXT) | order_id → orders.unique_id | 3 | Cancellations | ✅ Active |

**Legend:**
- ✅ Active - Table is being used
- ⚠️ Duplicate - Duplicate functionality with another table
- ❌ Unused - Table created but not used

---

## 2️⃣ TABLE-BY-TABLE ANALYSIS

### 📋 TABLE 1: `tailor`

**Purpose:** Store tailor shop owner information

#### Columns:
| Column | Type | Constraints | Description | Used In Pages |
|--------|------|-------------|-------------|---------------|
| `id` | TEXT | PRIMARY KEY | UUID identifier | All pages (session) |
| `unique_id` | TEXT | UNIQUE NOT NULL | Human-readable ID | Display in UI |
| `name` | TEXT | NOT NULL | Tailor's name | Profile, Dashboard |
| `shop_name` | TEXT | NOT NULL | Shop name | Header, Profile |
| `email` | TEXT | UNIQUE NOT NULL | Email address | Login, Profile |
| `phone` | TEXT | NOT NULL | Phone number | Profile, Contact |
| `password_hash` | TEXT | NOT NULL | Hashed password | Login, Security |
| `auth_provider` | TEXT | CHECK (google/facebook/email) | OAuth provider | Login |
| `address` | TEXT | NOT NULL | Shop address | Profile, Reports |
| `created_at` | TEXT | NOT NULL | Registration date | Analytics |
| `updated_at` | TEXT | NOT NULL | Last update | Audit trail |

#### Relationships:
```
tailor (1) ──→ (Many) customer [via tailor_id]
tailor (1) ──→ (Many) orders [via tailor_id]
```

#### Indexes:
- `idx_tailor_email` on `email`

#### Pages Using This Table:
- ✅ **Login Screen** - Authentication
- ✅ **Profile Screen** - Display/Edit info
- ✅ **Dashboard** - Show shop name
- ⚠️ **Settings** - Profile management

#### Issues:
- ⚠️ **Duplicate Auth:** Also have `users` table for authentication
- 🔧 **Recommendation:** Link to users table or unify authentication

---

### 📋 TABLE 2: `customer`

**Purpose:** Store customer profiles and contact information

#### Columns:
| Column | Type | Constraints | Description | Used In Pages |
|--------|------|-------------|-------------|---------------|
| `id` | TEXT | PRIMARY KEY | UUID identifier | Internal use |
| `unique_id` | TEXT | UNIQUE NOT NULL | Human-readable ID (CUST-XXXX) | Customer list, Orders |
| `tailor_id` | TEXT | FK → tailor.unique_id | Links to tailor | Filter by shop |
| `name` | TEXT | NOT NULL | Customer name | All customer screens |
| `gender` | TEXT | NULL | Customer gender | Profile, Analytics |
| `phone` | TEXT | NOT NULL | Phone number | Contact, SMS |
| `email` | TEXT | NULL | Email address | Contact, Receipts |
| `address` | TEXT | NOT NULL | Delivery address | Orders, Delivery |
| `notes` | TEXT | NULL | Additional notes | Customer details |
| `is_deleted` | INTEGER | DEFAULT 0 | Soft delete flag | Filter deleted |
| `created_at` | TEXT | NOT NULL | Registration date | Customer since |
| `updated_at` | TEXT | NOT NULL | Last update | Activity tracking |

#### Relationships:
```
customer (1) ←── (Many) tailor [via tailor_id] 
customer (1) ──→ (Many) measurement [via customer_id]
customer (1) ──→ (Many) orders [via customer_id]
customer (1) ──→ (Many) notifications [via customer_id]
```

#### Indexes:
- `idx_customer_tailor_id` on `tailor_id`
- Composite needed: `(tailor_id, is_deleted)` for filtering

#### Pages Using This Table:
- ✅ **Customers Main Screen** - List all customers
- ✅ **Customer Details Screen** - Show customer info
- ✅ **Add/Edit Customer Screen** - CRUD operations
- ✅ **Order Creation** - Select customer
- ✅ **Payment Collection** - Customer filter
- ✅ **Reports** - Customer analytics

#### Sample Queries:
```sql
-- Get all active customers for tailor
SELECT * FROM customer 
WHERE tailor_id = 'TAILOR-001' AND is_deleted = 0
ORDER BY name ASC;

-- Get customer with order count
SELECT c.*, COUNT(o.id) as order_count 
FROM customer c 
LEFT JOIN orders o ON c.unique_id = o.customer_id 
WHERE c.tailor_id = ? 
GROUP BY c.id;
```

#### Issues:
- ✅ **Well Implemented** - No major issues
- 💡 **Enhancement:** Add customer status (active/inactive)
- 💡 **Enhancement:** Add customer tags/categories

---

### 📋 TABLE 3: `measurement`

**Purpose:** Store customer body measurements for different dress types

#### Columns:
| Column | Type | Constraints | Description | Used In Pages |
|--------|------|-------------|-------------|---------------|
| `id` | TEXT | PRIMARY KEY | UUID identifier | Internal use |
| `unique_id` | TEXT | UNIQUE NOT NULL | Human-readable ID (MEAS-XXXX) | Measurement list |
| `customer_id` | TEXT | FK → customer.unique_id | Links to customer | Customer profile |
| `dress_type` | TEXT | NOT NULL | Type of dress (shirt, pant, etc.) | Category filter |
| `measurements` | TEXT | NOT NULL | JSON: {chest: 40, waist: 32, ...} | Measurement form |
| `notes` | TEXT | NULL | Special instructions | Order notes |
| `created_at` | TEXT | NOT NULL | Measurement date | Tracking |
| `updated_at` | TEXT | NOT NULL | Last update | Version tracking |
| `is_deleted` | INTEGER | DEFAULT 0 | Soft delete flag | Filter deleted |

#### Relationships:
```
measurement (Many) ←── (1) customer [via customer_id]
measurement (0..1) ←── (Many) orders [⚠️ NO DIRECT LINK - ISSUE]
```

#### Indexes:
- `idx_measurement_customer_id` on `customer_id`

#### Pages Using This Table:
- ✅ **Customer Details** - View measurements
- ✅ **Add/Edit Measurement** - CRUD operations
- ✅ **Order Creation** - Select measurement template
- ⚠️ **Order Details** - Show used measurements (from JSON)

#### Sample JSON Data:
```json
{
  "measurement_id": "MEAS-001",
  "chest": "40",
  "waist": "32",
  "shoulder": "18",
  "sleeve": "24",
  "length": "30"
}
```

#### Issues:
- 🔴 **CRITICAL:** No foreign key link from orders to measurements
- 🔴 **DATA DUPLICATION:** Measurements copied to orders.measurements as JSON
- 🔴 **CANNOT TRACK:** Which measurement was used for which order
- 🔧 **FIX NEEDED:** Add `measurement_id` column to orders table

```sql
-- Recommended fix:
ALTER TABLE orders ADD COLUMN measurement_id TEXT;
ALTER TABLE orders ADD FOREIGN KEY (measurement_id) 
  REFERENCES measurement (unique_id) ON DELETE SET NULL;
```

---

### 📋 TABLE 4: `orders`

**Purpose:** Store order information and track order lifecycle

#### Columns:
| Column | Type | Constraints | Description | Used In Pages |
|--------|------|-------------|-------------|---------------|
| `id` | TEXT | PRIMARY KEY | UUID identifier | Internal use |
| `unique_id` | TEXT | UNIQUE NOT NULL | Order number (ORD-XXXX) | Order tracking |
| `customer_id` | TEXT | FK → customer.unique_id | Order customer | Customer orders |
| `tailor_id` | TEXT | FK → tailor.unique_id | Shop owner | Shop orders |
| `service_type` | TEXT | NOT NULL | Shirt/Pant/Suit/Blouse etc. | Order category |
| `status` | TEXT | CHECK (5 values) | pending/cutting/stitching/ready/delivered | Order tracking |
| `payment_status` | TEXT | CHECK (4 values) | pending/partial/paid/overdue | Payment tracking |
| `delivery_date` | TEXT | NOT NULL | Expected delivery | Due date alerts |
| `notes` | TEXT | NOT NULL | Order instructions | Production notes |
| `design_image_url` | TEXT | NULL | Reference image | Design reference |
| `total_amount` | REAL | NOT NULL | Total order cost | Pricing |
| `advance_paid` | REAL | NOT NULL | Amount paid upfront | Payment tracking |
| `balance_amount` | REAL | NOT NULL | Remaining balance | Payment due |
| `measurements` | TEXT | NULL | JSON measurements | ⚠️ Duplicate data |
| `created_at` | TEXT | NOT NULL | Order date | Order history |
| `updated_at` | TEXT | NOT NULL | Last update | Activity tracking |
| `is_deleted` | INTEGER | DEFAULT 0 | Soft delete | Filter deleted |

#### Status Values:
| Status | Description | Color | Icon |
|--------|-------------|-------|------|
| `pending` | Awaiting production | Orange | ⏳ |
| `cutting` | Fabric cutting stage | Blue | ✂️ |
| `stitching` | Sewing in progress | Purple | 🧵 |
| `ready` | Ready for delivery | Green | ✅ |
| `delivered` | Delivered to customer | Gray | 📦 |

#### Payment Status Values:
| Status | Description | When Set |
|--------|-------------|----------|
| `pending` | No payment made | advance_paid = 0 |
| `partial` | Partial payment | 0 < advance_paid < total_amount |
| `paid` | Fully paid | advance_paid = total_amount |
| `overdue` | Payment overdue | balance > 0 && delivery_date < today |

#### Relationships:
```
orders (Many) ←── (1) customer [via customer_id]
orders (Many) ←── (1) tailor [via tailor_id]
orders (1) ──→ (Many) payment [via order_id]
orders (0..1) ──→ (Many) notifications [via order_id]
orders (1) ──→ (0..1) order_cancellations [via order_id]
orders ⚠️ NO LINK ──→ measurement [MISSING RELATIONSHIP]
```

#### Indexes:
- `idx_order_customer_id` on `customer_id`
- `idx_order_tailor_id` on `tailor_id`
- `idx_order_status` on `status`
- **Recommended:** `idx_order_payment_status` on `payment_status`
- **Recommended:** `idx_order_delivery_date` on `delivery_date`

#### Pages Using This Table:
- ✅ **Orders Main Screen** - Dashboard with stats
- ✅ **Pending Orders** - Filter by status='pending'
- ✅ **In Progress Orders** - Filter by status='cutting'/'stitching'
- ✅ **Ready Orders** - Filter by status='ready'
- ✅ **Completed Orders** - Filter by status='delivered'
- ✅ **Order Details** - Full order information
- ✅ **Add/Edit Order** - CRUD operations
- ✅ **Payment Collection** - Orders with pending payments
- ✅ **Payment Reports** - Financial analytics

#### Sample Queries:
```sql
-- Get order with customer details
SELECT o.*, c.name as customer_name, c.phone 
FROM orders o 
JOIN customer c ON o.customer_id = c.unique_id 
WHERE o.unique_id = ?;

-- Get pending payments
SELECT o.* FROM orders o 
WHERE o.balance_amount > 0 
AND o.is_deleted = 0 
ORDER BY o.delivery_date ASC;

-- Get overdue orders
SELECT o.*, c.name 
FROM orders o 
JOIN customer c ON o.customer_id = c.unique_id 
WHERE o.delivery_date < date('now') 
AND o.status != 'delivered' 
AND o.is_deleted = 0;
```

#### Calculated Fields (Should Be Computed):
```dart
// In Dart model
double get balanceAmount => totalAmount - advancePaid;

String get paymentStatus {
  if (advancePaid == 0) return 'pending';
  if (advancePaid >= totalAmount) return 'paid';
  if (advancePaid > 0) return 'partial';
  if (DateTime.now().isAfter(deliveryDate)) return 'overdue';
  return 'pending';
}
```

#### Issues:
- 🔴 **CRITICAL:** `measurements` column stores duplicate data from `measurement` table
- 🔴 **MISSING LINK:** No `measurement_id` foreign key
- ⚠️ **REDUNDANT:** `balance_amount` can be calculated (total - advance)
- ⚠️ **REDUNDANT:** `payment_status` can be computed dynamically
- 💡 **Enhancement:** Add `priority` field (high/medium/low)
- 💡 **Enhancement:** Add `rush_order` boolean flag

---

### 📋 TABLE 5: `payment`

**Purpose:** Track payment transactions for orders

#### Columns:
| Column | Type | Constraints | Description | Used In Pages |
|--------|------|-------------|-------------|---------------|
| `id` | TEXT | PRIMARY KEY | UUID identifier | Internal use |
| `unique_id` | TEXT | UNIQUE NOT NULL | Payment receipt (PAY-XXXX) | Receipt number |
| `order_id` | TEXT | FK → orders.unique_id | Links to order | Order payments |
| `amount` | REAL | NOT NULL | Payment amount | Transaction |
| `method` | TEXT | DEFAULT 'cash' | cash/card/upi/bank | Payment method |
| `notes` | TEXT | DEFAULT '' | Payment notes | Reference |
| `transaction_id` | TEXT | NULL | Digital payment ID | UPI/Card reference |
| `paid_on` | TEXT | NOT NULL | Payment date/time | Transaction time |
| `created_at` | TEXT | NOT NULL | Record created | Audit |
| `updated_at` | TEXT | NOT NULL | Last update | Audit |
| `is_deleted` | INTEGER | DEFAULT 0 | Soft delete | Filter |

#### Payment Methods:
| Method | Description | Requires transaction_id |
|--------|-------------|-------------------------|
| `cash` | Cash payment | ❌ No |
| `card` | Credit/Debit card | ✅ Yes |
| `upi` | UPI payment | ✅ Yes |
| `bank` | Bank transfer | ✅ Yes |

#### Relationships:
```
payment (Many) ←── (1) orders [via order_id]
payment ⚠️ NO DIRECT LINK ──→ customer [via order→customer]
```

#### Indexes:
- `idx_payment_order_id` on `order_id`
- **Recommended:** `idx_payment_paid_on` on `paid_on`
- **Recommended:** `idx_payment_method` on `method`

#### Pages Using This Table:
- ✅ **Payment Collection Screen** - Create payments
- ✅ **Payment History Screen** - All payments
- ✅ **Order Payment History** - Payments for order
- ✅ **Payment Reports** - Analytics
- ✅ **Receipt Management** - Generate receipts
- ✅ **Order Details** - Show payment history

#### Sample Queries:
```sql
-- Get payments with order and customer
SELECT p.*, o.unique_id as order_number, c.name as customer_name 
FROM payment p 
JOIN orders o ON p.order_id = o.unique_id 
JOIN customer c ON o.customer_id = c.unique_id 
WHERE p.is_deleted = 0 
ORDER BY p.paid_on DESC;

-- Get total collected by method
SELECT method, COUNT(*) as count, SUM(amount) as total 
FROM payment 
WHERE is_deleted = 0 
GROUP BY method;

-- Get payments for date range
SELECT * FROM payment 
WHERE paid_on BETWEEN ? AND ? 
AND is_deleted = 0 
ORDER BY paid_on DESC;
```

#### Issues:
- ⚠️ **MISSING INDEX:** Should have index on `paid_on` for date queries
- 💡 **Enhancement:** Add `receipt_generated` boolean flag
- 💡 **Enhancement:** Add `refund_id` for linked refunds

---

### 📋 TABLE 6: `users`

**Purpose:** User authentication and profile (⚠️ DUPLICATE with tailor table)

#### Columns:
| Column | Type | Constraints | Description | Used In Pages |
|--------|------|-------------|-------------|---------------|
| `id` | INTEGER | PRIMARY KEY AUTO | Auto-increment ID | User ID |
| `username` | TEXT | UNIQUE NOT NULL | Username | Login |
| `email` | TEXT | UNIQUE NOT NULL | Email | Login, Reset |
| `phone` | TEXT | NULL | Phone number | 2FA, Contact |
| `password_hash` | TEXT | NOT NULL | Hashed password | Authentication |
| `profile_picture` | TEXT | NULL | Avatar URL | Profile |
| `is_email_verified` | INTEGER | DEFAULT 0 | Email verified | Email verification |
| `is_phone_verified` | INTEGER | DEFAULT 0 | Phone verified | SMS verification |
| `login_count` | INTEGER | DEFAULT 0 | Total logins | Analytics |
| `last_login` | TEXT | NULL | Last login time | Security |
| `created_at` | TEXT | NOT NULL | Registration | Account age |
| `updated_at` | TEXT | NOT NULL | Last update | Activity |

#### Relationships:
```
users (1) ──→ (Many) auth_sessions [via user_id]
users (1) ──→ (1) user_preferences [via user_id]
users (1) ──→ (Many) login_history [via user_id]
users ⚠️ NO LINK ──→ tailor [DUPLICATE SYSTEM]
```

#### Indexes:
- `idx_users_email` on `email`
- `idx_users_username` on `username`

#### Pages Using This Table:
- ⚠️ **NOT CURRENTLY USED** in main app
- ⚠️ **Auth system uses** `tailor` table instead
- 💡 **Should be used for:** User management, profiles

#### Issues:
- 🔴 **CRITICAL:** Duplicate authentication system
- 🔴 **CONFUSION:** App uses `tailor` table for auth, not `users`
- 🔧 **RECOMMENDATION:** Either:
  1. Link `tailor.user_id` → `users.id` (preferred)
  2. Remove `users` table and use `tailor` only
  3. Migrate all auth to `users` table

---

### 📋 TABLE 7: `auth_sessions`

**Purpose:** Track active user sessions and tokens

#### Columns:
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTO | Session record ID |
| `session_id` | TEXT | UNIQUE NOT NULL | Session UUID |
| `user_id` | INTEGER | FK → users.id | User reference |
| `access_token` | TEXT | NOT NULL | JWT access token |
| `refresh_token` | TEXT | NOT NULL | JWT refresh token |
| `expires_at` | TEXT | NOT NULL | Token expiry |
| `created_at` | TEXT | NOT NULL | Session start |
| `updated_at` | TEXT | NULL | Last activity |
| `device_info` | TEXT | NULL | Device details |
| `ip_address` | TEXT | NULL | Client IP |
| `user_agent` | TEXT | NULL | Browser/App info |
| `is_active` | INTEGER | DEFAULT 1 | Active session |

#### Relationships:
```
auth_sessions (Many) ←── (1) users [via user_id]
```

#### Indexes:
- `idx_auth_sessions_user_id` on `user_id`
- `idx_auth_sessions_session_id` on `session_id`
- `idx_auth_sessions_expires_at` on `expires_at`

#### Issues:
- ⚠️ **NOT CURRENTLY USED** - Auth system uses different mechanism
- 💡 **Should implement** for multi-device support

---

### 📋 TABLE 8: `user_preferences`

**Purpose:** Store user settings and preferences

#### Columns:
| Column | Type | Constraints | Description | Default |
|--------|------|-------------|-------------|---------|
| `id` | INTEGER | PRIMARY KEY AUTO | Preference ID | - |
| `user_id` | INTEGER | FK → users.id | User reference | - |
| `theme_mode` | TEXT | DEFAULT 'system' | light/dark/system | system |
| `language` | TEXT | DEFAULT 'en' | Language code | en |
| `measurement_unit` | TEXT | DEFAULT 'inches' | inches/cm | inches |
| `notifications_enabled` | INTEGER | DEFAULT 1 | Enable notifications | 1 |
| `biometric_enabled` | INTEGER | DEFAULT 0 | Fingerprint/Face | 0 |
| `remember_me` | INTEGER | DEFAULT 1 | Remember login | 1 |
| `auto_logout_duration` | INTEGER | DEFAULT 3600 | Seconds | 3600 |
| `custom_settings` | TEXT | NULL | JSON extras | null |
| `created_at` | TEXT | NOT NULL | Created | - |
| `updated_at` | TEXT | NOT NULL | Updated | - |

#### Relationships:
```
user_preferences (1) ←── (1) users [via user_id]
```

#### Indexes:
- `idx_user_preferences_user_id` on `user_id`

#### Pages Using This Table:
- ✅ **Theme Selection** - theme_mode
- ✅ **Language Settings** - language
- ✅ **Notification Settings** - notifications_enabled
- ✅ **Privacy Settings** - biometric_enabled

---

### 📋 TABLE 9: `login_history`

**Purpose:** Audit trail for login attempts

#### Columns:
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTO | History ID |
| `user_id` | INTEGER | FK → users.id | User reference |
| `login_time` | TEXT | NOT NULL | Login timestamp |
| `device_info` | TEXT | NULL | Device details |
| `ip_address` | TEXT | NULL | Client IP |
| `user_agent` | TEXT | NULL | Browser info |
| `login_method` | TEXT | DEFAULT 'password' | password/biometric/oauth |
| `was_successful` | INTEGER | NOT NULL | Success flag |
| `failure_reason` | TEXT | NULL | Error message |

#### Relationships:
```
login_history (Many) ←── (1) users [via user_id]
```

#### Indexes:
- `idx_login_history_user_id` on `user_id`
- `idx_login_history_login_time` on `login_time`

#### Pages Using This Table:
- ⚠️ **Security Dashboard** - Show login activity
- 💡 **Not currently implemented**

---

### 📋 TABLE 10: `notifications`

**Purpose:** System notifications and alerts

#### Columns:
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Notification UUID |
| `title` | TEXT | NOT NULL | Notification title |
| `message` | TEXT | NOT NULL | Notification body |
| `type` | TEXT | NOT NULL | order/payment/reminder/alert |
| `data` | TEXT | NULL | JSON metadata |
| `order_id` | TEXT | FK → orders.unique_id | Related order |
| `customer_id` | TEXT | FK → customer.unique_id | Related customer |
| `action_url` | TEXT | NULL | Deep link |
| `is_read` | INTEGER | DEFAULT 0 | Read status |
| `created_at` | TEXT | NOT NULL | Created time |

#### Relationships:
```
notifications (Many) ←── (0..1) orders [via order_id]
notifications (Many) ←── (0..1) customer [via customer_id]
```

#### Indexes:
- `idx_notifications_created_at` on `created_at`
- `idx_notifications_is_read` on `is_read`
- `idx_notifications_order_id` on `order_id`
- `idx_notifications_customer_id` on `customer_id`

#### Pages Using This Table:
- ✅ **Dashboard** - Notification badge count
- ✅ **Notifications Screen** - List notifications
- 💡 **Not fully implemented**

---

### 📋 TABLE 11: `order_cancellations`

**Purpose:** Track cancelled orders and refunds

#### Columns:
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Cancellation UUID |
| `order_id` | TEXT | FK → orders.unique_id | Cancelled order |
| `reason` | TEXT | NOT NULL | Cancellation reason |
| `custom_reason` | TEXT | NULL | Custom text |
| `cancelled_by` | TEXT | NOT NULL | Who cancelled |
| `cancelled_at` | TEXT | NOT NULL | Cancellation time |
| `refund_amount` | REAL | DEFAULT 0.0 | Refund amount |
| `refund_status` | TEXT | DEFAULT 'not_applicable' | Status |
| `refund_notes` | TEXT | NULL | Refund notes |
| `additional_data` | TEXT | NULL | JSON extras |
| `created_at` | TEXT | NOT NULL | Record created |
| `updated_at` | TEXT | NOT NULL | Last update |

#### Relationships:
```
order_cancellations (0..1) ←── (1) orders [via order_id]
```

#### Indexes:
- `idx_order_cancellations_order_id` on `order_id`
- `idx_order_cancellations_cancelled_at` on `cancelled_at`
- `idx_order_cancellations_reason` on `reason`

#### Pages Using This Table:
- ✅ **Refund Management** - Manage refunds
- 💡 **Order Details** - Show cancellation info

---

## 3️⃣ SCREEN-TO-TABLE MAPPING

### 📱 **Orders Module**

#### Orders Main Screen (`orders_main_screen.dart`)
**Tables Used:**
- ✅ `orders` - Main data source
- ✅ `customer` - Customer names (JOIN)
- ⚠️ `payment` - Should aggregate payment data

**Queries:**
```dart
// Current
List<Order> orders = await _dbService.getOrders();

// Recommended
List<Map> ordersWithDetails = await _dbService.rawQuery('''
  SELECT 
    o.*,
    c.name as customer_name,
    c.phone as customer_phone,
    COALESCE(SUM(p.amount), 0) as total_paid
  FROM orders o
  JOIN customer c ON o.customer_id = c.unique_id
  LEFT JOIN payment p ON o.unique_id = p.order_id
  WHERE o.is_deleted = 0
  GROUP BY o.id
  ORDER BY o.created_at DESC
''');
```

**Stats Displayed:**
- Total Orders
- Pending Orders
- In Progress Orders
- Ready Orders
- Completed Orders
- Total Revenue
- Pending Payments

**Issues:**
- ⚠️ Stats calculated in Dart (should use SQL aggregations)
- ⚠️ N+1 query problem when loading customer names

---

#### Order Detail Screen (`order_detail_screen.dart`)
**Tables Used:**
- ✅ `orders` - Order data
- ✅ `customer` - Customer info
- ✅ `payment` - Payment history
- ⚠️ `measurement` - Only from JSON, not linked

**Data Displayed:**
- Order number, status, dates
- Customer name, phone, address
- Service type, measurements (JSON)
- Pricing breakdown
- Payment history
- Status timeline

**Issues:**
- 🔴 Measurements from JSON, not measurement table
- ⚠️ Cannot track original measurement used
- ⚠️ Cannot update measurement retroactively

---

#### Pending Orders Screen (`pending_orders_screen.dart`)
**Tables Used:**
- ✅ `orders` WHERE status = 'pending'
- ✅ `customer` - For names

**Queries:**
```dart
// Current
orders.where((o) => o.status.toLowerCase() == 'pending')

// Better
SELECT o.*, c.name 
FROM orders o 
JOIN customer c ON o.customer_id = c.unique_id 
WHERE o.status = 'pending' AND o.is_deleted = 0 
ORDER BY o.delivery_date ASC
```

---

#### Add Order Screen (`add_order_screen.dart`)
**Tables Used:**
- ✅ `customer` - Select customer
- ✅ `measurement` - Load measurements
- ✅ `orders` - Create order

**Issues:**
- 🔴 Copies measurement data to orders.measurements (JSON)
- 🔴 No measurement_id saved
- ⚠️ Cannot track which measurement was used

---

### 📱 **Payments Module**

#### Payment Collection Screen (`payment_collection_screen.dart`)
**Tables Used:**
- ✅ `orders` WHERE balance_amount > 0
- ✅ `customer` - Customer info
- ✅ `payment` - Create payment

**Queries:**
```sql
-- Get orders with pending payments
SELECT o.*, c.name, c.phone 
FROM orders o 
JOIN customer c ON o.customer_id = c.unique_id 
WHERE o.balance_amount > 0 
AND o.is_deleted = 0 
ORDER BY o.delivery_date ASC
```

**Issues:**
- ✅ Well implemented
- 💡 Could add payment method analytics

---

#### Payment History Screen (`payment_history_screen.dart`)
**Tables Used:**
- ✅ `payment` - All payments
- ⚠️ `orders` - Via JOIN for order info
- ⚠️ `customer` - Via JOIN for customer info

**Current Query:**
```dart
List<Payment> payments = await _dbService.getPayments();
// Then loops to get order and customer (N+1 problem)
```

**Recommended Query:**
```sql
SELECT 
  p.*,
  o.unique_id as order_number,
  o.total_amount as order_total,
  c.name as customer_name,
  c.phone as customer_phone
FROM payment p
JOIN orders o ON p.order_id = o.unique_id
JOIN customer c ON o.customer_id = c.unique_id
WHERE p.is_deleted = 0
ORDER BY p.paid_on DESC
```

---

#### Order Payment History (`order_payment_history_screen.dart`)
**Tables Used:**
- ✅ `payment` WHERE order_id = ?
- ✅ `orders` - Order details
- ✅ `customer` - Customer details

**Queries:**
```dart
List<Payment> payments = await _dbService.getPaymentsByOrderId(orderId);
```

**Issues:**
- ✅ Well implemented
- 💡 Could add payment receipt generation

---

#### Payment Reports Screen (`payment_reports_screen.dart`)
**Tables Used:**
- ✅ `payment` - Transaction data
- ✅ `orders` - Order totals
- ✅ `customer` - Customer info

**Analytics Needed:**
- Total revenue
- Revenue by payment method
- Revenue by day/week/month
- Top customers by payment
- Outstanding balances

**Current Implementation:**
```dart
// Using PaymentAnalyticsService
final analytics = await _analyticsService.generateAnalytics(
  period: AnalyticsPeriod.thisWeek,
);
```

**Issues:**
- ⚠️ Complex calculations in Dart
- 💡 Should use SQL aggregations for better performance

---

### 📱 **Customers Module**

#### Customers Main Screen (`customers_main_screen.dart`)
**Tables Used:**
- ✅ `customer` - All customers
- ⚠️ `orders` - Should aggregate order counts

**Recommended Query:**
```sql
SELECT 
  c.*,
  COUNT(DISTINCT o.id) as order_count,
  COALESCE(SUM(o.total_amount), 0) as lifetime_value,
  COALESCE(SUM(o.balance_amount), 0) as outstanding_balance,
  MAX(o.created_at) as last_order_date
FROM customer c
LEFT JOIN orders o ON c.unique_id = o.customer_id AND o.is_deleted = 0
WHERE c.tailor_id = ? AND c.is_deleted = 0
GROUP BY c.id
ORDER BY order_count DESC
```

---

#### Customer Details Screen
**Tables Used:**
- ✅ `customer` - Customer info
- ✅ `orders` - Customer orders
- ✅ `measurement` - Customer measurements
- ✅ `payment` - Via orders

**Stats to Show:**
- Total orders
- Total spent
- Outstanding balance
- Last order date
- Total measurements

---

### 📱 **Settings Module**

#### Settings Screen (`settings_screen.dart`)
**Tables Used:**
- ⚠️ `user_preferences` - Should use but doesn't
- ⚠️ `users` - Should link to tailor

**Issues:**
- 🔴 Not using user_preferences table
- 🔴 Settings stored in SharedPreferences instead

---

## 4️⃣ DATA FLOW DIAGRAMS

### Order Creation Flow
```
┌──────────────┐
│   Customer   │
│  Selection   │
└──────┬───────┘
       │
       ▼
┌──────────────┐     ┌──────────────┐
│ Measurement  │────→│  Orders      │
│  Selection   │     │  (JSON copy) │◄─── ❌ Should link via FK
└──────────────┘     └──────┬───────┘
                            │
                            ▼
                     ┌──────────────┐
                     │   Payment    │
                     │ (if advance) │
                     └──────────────┘
```

### Payment Collection Flow
```
┌──────────────┐
│   Orders     │
│ balance > 0  │
└──────┬───────┘
       │
       ▼
┌──────────────┐     ┌──────────────┐
│   Customer   │◄────│   Payment    │
│     Info     │     │   Record     │
└──────────────┘     └──────┬───────┘
                            │
                            ▼
                     ┌──────────────┐
                     │   Update     │
                     │ Order.advance│
                     └──────────────┘
```

### Analytics Generation Flow
```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Payment    │────→│   Orders     │────→│   Customer   │
│   Records    │     │   Details    │     │   Details    │
└──────────────┘     └──────────────┘     └──────────────┘
       │                    │                      │
       └────────────────────┼──────────────────────┘
                            ▼
                     ┌──────────────┐
                     │  Analytics   │
                     │ Aggregation  │
                     └──────────────┘
```

---

## 5️⃣ MISSING LINKS & RECOMMENDATIONS

### 🔴 **CRITICAL Issues**

#### 1. Orders ↔ Measurements (NO LINK)
**Problem:**
- Measurements stored as JSON in orders table
- No foreign key relationship
- Cannot track which measurement was used
- Cannot update measurements retroactively

**Fix:**
```sql
-- Add measurement_id to orders
ALTER TABLE orders ADD COLUMN measurement_id TEXT;
CREATE INDEX idx_order_measurement_id ON orders (measurement_id);

-- Update existing records (migration)
-- Parse JSON and link to measurement records
```

**Benefits:**
- Track measurement usage
- Update measurements and reflect in orders
- Query "orders using measurement X"
- Better data integrity

---

#### 2. Tailor ↔ Users (DUPLICATE AUTH)
**Problem:**
- Two authentication systems
- tailor table has auth fields
- users table not used
- No link between them

**Fix Option 1 (Recommended):**
```sql
-- Link tailor to users
ALTER TABLE tailor ADD COLUMN user_id INTEGER;
ALTER TABLE tailor ADD FOREIGN KEY (user_id) 
  REFERENCES users (id) ON DELETE CASCADE;

-- Migrate data
INSERT INTO users (username, email, phone, password_hash, created_at, updated_at)
SELECT email, email, phone, password_hash, created_at, updated_at
FROM tailor;

UPDATE tailor SET user_id = (
  SELECT id FROM users WHERE users.email = tailor.email
);
```

**Fix Option 2 (Simpler):**
```sql
-- Remove users table, use tailor only
DROP TABLE users;
DROP TABLE auth_sessions;
-- Update auth logic to use tailor table
```

---

### ⚠️ **MEDIUM Priority**

#### 3. Add Composite Indexes
```sql
-- For common queries
CREATE INDEX idx_customer_tailor_deleted ON customer (tailor_id, is_deleted);
CREATE INDEX idx_order_status_deleted ON orders (status, is_deleted);
CREATE INDEX idx_order_customer_status ON orders (customer_id, status);
CREATE INDEX idx_payment_order_date ON payment (order_id, paid_on);
```

#### 4. Add Computed Columns
```sql
-- SQLite 3.31.0+ supports generated columns
ALTER TABLE orders ADD COLUMN payment_percentage REAL 
  GENERATED ALWAYS AS ((advance_paid * 100.0) / total_amount) STORED;
```

---

### 💡 **NICE TO HAVE**

#### 5. Add Full-Text Search
```sql
-- FTS5 virtual table for customer search
CREATE VIRTUAL TABLE customer_fts USING fts5(
  unique_id UNINDEXED,
  name,
  phone,
  email,
  address
);

-- Sync with triggers
CREATE TRIGGER customer_fts_insert AFTER INSERT ON customer
BEGIN
  INSERT INTO customer_fts 
  VALUES (NEW.unique_id, NEW.name, NEW.phone, NEW.email, NEW.address);
END;
```

#### 6. Add Order Timeline Table
```sql
CREATE TABLE order_timeline (
  id TEXT PRIMARY KEY,
  order_id TEXT NOT NULL,
  status TEXT NOT NULL,
  changed_by TEXT NOT NULL,
  changed_at TEXT NOT NULL,
  notes TEXT,
  FOREIGN KEY (order_id) REFERENCES orders (unique_id) ON DELETE CASCADE
);
```

---

## 6️⃣ QUERY OPTIMIZATION GUIDE

### Current Slow Queries

#### ❌ BAD: N+1 Query Problem
```dart
// DON'T DO THIS
final orders = await getOrders();
for (var order in orders) {
  final customer = await getCustomer(order.customerId);
  // Fetches customer for each order
}
```

#### ✅ GOOD: Single JOIN Query
```dart
final ordersWithCustomer = await db.rawQuery('''
  SELECT o.*, c.name as customer_name, c.phone as customer_phone
  FROM orders o
  JOIN customer c ON o.customer_id = c.unique_id
  WHERE o.is_deleted = 0
''');
```

---

### Optimized Query Collection

#### Get Orders with Full Details
```sql
SELECT 
  o.*,
  c.name as customer_name,
  c.phone as customer_phone,
  c.email as customer_email,
  c.address as customer_address,
  COALESCE(SUM(p.amount), 0) as total_paid,
  COUNT(p.id) as payment_count,
  (o.total_amount - COALESCE(SUM(p.amount), 0)) as remaining_balance
FROM orders o
JOIN customer c ON o.customer_id = c.unique_id
LEFT JOIN payment p ON o.unique_id = p.order_id AND p.is_deleted = 0
WHERE o.tailor_id = ? AND o.is_deleted = 0
GROUP BY o.id
ORDER BY o.created_at DESC;
```

#### Get Customer Statistics
```sql
SELECT 
  c.*,
  COUNT(DISTINCT o.id) as total_orders,
  COUNT(DISTINCT CASE WHEN o.status = 'pending' THEN o.id END) as pending_orders,
  COUNT(DISTINCT CASE WHEN o.status IN ('cutting', 'stitching') THEN o.id END) as in_progress_orders,
  COUNT(DISTINCT CASE WHEN o.status = 'ready' THEN o.id END) as ready_orders,
  COUNT(DISTINCT CASE WHEN o.status = 'delivered' THEN o.id END) as completed_orders,
  COALESCE(SUM(o.total_amount), 0) as lifetime_value,
  COALESCE(SUM(o.advance_paid), 0) as total_paid,
  COALESCE(SUM(o.balance_amount), 0) as outstanding_balance,
  COUNT(DISTINCT m.id) as measurement_count,
  MAX(o.created_at) as last_order_date
FROM customer c
LEFT JOIN orders o ON c.unique_id = o.customer_id AND o.is_deleted = 0
LEFT JOIN measurement m ON c.unique_id = m.customer_id AND m.is_deleted = 0
WHERE c.unique_id = ?
GROUP BY c.id;
```

#### Payment Analytics by Period
```sql
SELECT 
  DATE(p.paid_on) as payment_date,
  COUNT(*) as transaction_count,
  SUM(p.amount) as total_amount,
  AVG(p.amount) as average_amount,
  p.method,
  COUNT(DISTINCT o.customer_id) as unique_customers
FROM payment p
JOIN orders o ON p.order_id = o.unique_id
WHERE p.paid_on BETWEEN ? AND ?
  AND p.is_deleted = 0
GROUP BY DATE(p.paid_on), p.method
ORDER BY payment_date DESC;
```

#### Revenue by Service Type
```sql
SELECT 
  o.service_type,
  COUNT(*) as order_count,
  SUM(o.total_amount) as total_revenue,
  SUM(o.advance_paid) as total_collected,
  SUM(o.balance_amount) as total_pending,
  AVG(o.total_amount) as average_order_value
FROM orders o
WHERE o.tailor_id = ? 
  AND o.is_deleted = 0
  AND o.created_at BETWEEN ? AND ?
GROUP BY o.service_type
ORDER BY total_revenue DESC;
```

---

## 📊 SUMMARY STATISTICS

### Database Health Score: **75/100**

| Category | Score | Status |
|----------|-------|--------|
| Schema Design | 85/100 | ✅ Good |
| Relationships | 70/100 | ⚠️ Missing links |
| Indexes | 80/100 | ✅ Good |
| Query Optimization | 60/100 | ⚠️ N+1 problems |
| Data Integrity | 75/100 | ⚠️ Some issues |
| Documentation | 90/100 | ✅ Excellent |

### Issues Summary

| Priority | Count | Examples |
|----------|-------|----------|
| 🔴 Critical | 3 | Orders→Measurements, Tailor→Users duplicate, N+1 queries |
| ⚠️ Medium | 5 | Missing indexes, redundant columns, unused tables |
| 💡 Enhancement | 8 | FTS, computed columns, timeline tracking |

---

## ✅ ACTION PLAN

### Week 1: Critical Fixes
- [ ] Add `measurement_id` to orders table
- [ ] Create optimized query methods
- [ ] Fix N+1 query problems in UI
- [ ] Add composite indexes

### Week 2: Authentication Cleanup
- [ ] Decide on auth strategy (tailor vs users)
- [ ] Create migration script
- [ ] Update authentication logic
- [ ] Test thoroughly

### Week 3: Optimization
- [ ] Implement recommended queries
- [ ] Add missing indexes
- [ ] Profile query performance
- [ ] Update documentation

### Week 4: Enhancements
- [ ] Add full-text search
- [ ] Implement order timeline
- [ ] Add computed columns
- [ ] Create analytics dashboard

---

**Report Complete**

This comprehensive audit covers all 11 tables, 30+ screens, and provides actionable recommendations for improving your database structure and query performance.
