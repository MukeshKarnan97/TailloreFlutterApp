-- SQL Script to Update Orders for Payment Collection
-- This will make more orders appear in the payment collection screen
-- by creating pending payment balances

-- Keep the existing 2 orders unchanged (ORDLQD6QU5 and ORD70OC1ME)
-- Update other orders to have pending payments

-- First, let's see what we have
SELECT 
    unique_id,
    status,
    total_amount,
    advance_paid,
    (total_amount - advance_paid) as balance,
    payment_status,
    CASE 
        WHEN total_amount <= advance_paid THEN 'Fully Paid'
        WHEN advance_paid > 0 THEN 'Partial Payment'
        ELSE 'No Payment'
    END as payment_category
FROM orders 
WHERE is_deleted = 0
ORDER BY created_at DESC;

-- Update orders to create pending payments (excluding the 2 existing ones)
-- Set advance_paid to 70% of total_amount for most orders

UPDATE orders 
SET 
    advance_paid = ROUND(total_amount * 0.70, 2),
    balance_amount = ROUND(total_amount * 0.30, 2),
    payment_status = 'partial',
    updated_at = datetime('now')
WHERE 
    is_deleted = 0 
    AND unique_id NOT IN ('ORDLQD6QU5', 'ORD70OC1ME')
    AND status IN ('pending', 'cutting', 'stitching', 'ready');

-- Update some orders to have different payment percentages for variety
UPDATE orders 
SET 
    advance_paid = ROUND(total_amount * 0.50, 2),
    balance_amount = ROUND(total_amount * 0.50, 2),
    payment_status = 'partial',
    updated_at = datetime('now')
WHERE 
    is_deleted = 0 
    AND unique_id NOT IN ('ORDLQD6QU5', 'ORD70OC1ME')
    AND status = 'pending'
    AND ROWID % 2 = 0; -- Every other pending order

-- Update some orders to have minimal payment for variety  
UPDATE orders 
SET 
    advance_paid = ROUND(total_amount * 0.30, 2),
    balance_amount = ROUND(total_amount * 0.70, 2),
    payment_status = 'partial',
    updated_at = datetime('now')
WHERE 
    is_deleted = 0 
    AND unique_id NOT IN ('ORDLQD6QU5', 'ORD70OC1ME')
    AND status = 'cutting'
    AND ROWID % 3 = 0; -- Every third cutting order

-- Verify the changes
SELECT 
    'After Update' as stage,
    COUNT(*) as total_orders,
    COUNT(CASE WHEN total_amount > advance_paid THEN 1 END) as orders_with_pending_payments,
    COUNT(CASE WHEN total_amount <= advance_paid THEN 1 END) as fully_paid_orders
FROM orders 
WHERE is_deleted = 0;

-- Show updated orders that should now appear in payment collection
SELECT 
    unique_id,
    status,
    total_amount,
    advance_paid,
    (total_amount - advance_paid) as pending_amount,
    payment_status
FROM orders 
WHERE 
    is_deleted = 0 
    AND total_amount > advance_paid
ORDER BY created_at DESC;