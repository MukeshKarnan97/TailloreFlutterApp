-- SQL Script to Fix Payment Table CHECK Constraint Issue
-- This script removes the CHECK constraint that's preventing payment saves

BEGIN TRANSACTION;

-- Step 1: Check if the current payment table has a CHECK constraint
-- You can verify this by running: .schema payment

-- Step 2: Create backup table with existing data
CREATE TABLE payment_backup AS SELECT * FROM payment;

-- Step 3: Drop the existing payment table
DROP TABLE payment;

-- Step 4: Create new payment table without CHECK constraint
CREATE TABLE payment (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    unique_id TEXT NOT NULL UNIQUE,
    order_id TEXT NOT NULL,
    customer_id TEXT NOT NULL,
    amount REAL NOT NULL,
    payment_type TEXT NOT NULL DEFAULT 'partial',
    method TEXT NOT NULL,
    transaction_id TEXT,
    notes TEXT,
    paid_on DATETIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_deleted INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (order_id) REFERENCES orders (unique_id),
    FOREIGN KEY (customer_id) REFERENCES customer (unique_id)
);

-- Step 5: Restore data from backup
INSERT INTO payment SELECT * FROM payment_backup;

-- Step 6: Clean up backup table
DROP TABLE payment_backup;

-- Step 7: Test payment insertion (this should work now)
INSERT INTO payment (
    unique_id, 
    order_id, 
    customer_id, 
    amount, 
    payment_type, 
    method, 
    notes, 
    paid_on
) VALUES (
    'TEST_' || datetime('now', 'unixepoch'),
    'TEST_ORDER',
    'TEST_CUSTOMER', 
    100.0,
    'partial',
    'cash',
    'Test payment after constraint fix',
    datetime('now')
);

-- Step 8: Verify the test payment was inserted
SELECT COUNT(*) as payment_count FROM payment WHERE unique_id LIKE 'TEST_%';

-- Step 9: Clean up test payment
DELETE FROM payment WHERE unique_id LIKE 'TEST_%';

-- Step 10: Show final payment count
SELECT COUNT(*) as total_payments FROM payment;

COMMIT;

-- Display success message
SELECT 'Payment table CHECK constraint has been successfully removed!' as result;