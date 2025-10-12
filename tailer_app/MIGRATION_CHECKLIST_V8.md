# ✅ DATABASE VERSION 8 - MIGRATION CHECKLIST

Print this and check off each item as you complete it.

---

## PRE-MIGRATION CHECKLIST

- [ ] Read `QUICKSTART_V8_MIGRATION.md`
- [ ] Read `DATABASE_V8_COMPLETE_SUMMARY.md` (optional but recommended)
- [ ] Understand what CASCADE does (deleting parent deletes children)
- [ ] Backup current database (optional but recommended)
- [ ] Close all running instances of the app
- [ ] Code changes committed (optional)

---

## MIGRATION EXECUTION

- [ ] Open terminal in project folder
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Run `flutter run`
- [ ] Watch console for migration logs
- [ ] Saw "Backing up X records" messages
- [ ] Saw "Step 2: Dropping old tables"
- [ ] Saw "Step 3: Creating new tables with proper FK"
- [ ] Saw "✓ Created tailor table"
- [ ] Saw "✓ Created customer table with FK CASCADE"
- [ ] Saw "✓ Created orders table with FK CASCADE and measurement_id"
- [ ] Saw "Step 4: Creating indexes"
- [ ] Saw "✓ Created all indexes"
- [ ] Saw "Step 5: Restoring data"
- [ ] Saw "✓ Restored X tailors"
- [ ] Saw "✓ Restored X customers"
- [ ] Saw "✓ Restored X orders"
- [ ] Saw "✅ MIGRATION COMPLETED SUCCESSFULLY!"
- [ ] App opened without crashing
- [ ] No error messages in console

---

## POST-MIGRATION VERIFICATION

### Database Structure
- [ ] Open database in DB viewer (optional)
- [ ] Verify `orders` table has `measurement_id` column
- [ ] Verify 29 indexes exist
- [ ] Verify data counts match pre-migration

### Functionality Tests
- [ ] App launches successfully
- [ ] Dashboard loads without errors
- [ ] Can view customer list
- [ ] Can view customer details
- [ ] Can view orders list
- [ ] Can view order details
- [ ] Can view payments list
- [ ] Can view payment history
- [ ] Can create new customer
- [ ] Can create new measurement
- [ ] Can create new order
- [ ] Can add payment
- [ ] Search functionality works
- [ ] Filter functionality works
- [ ] No FK constraint errors anywhere

### CASCADE Tests
- [ ] Create test customer
- [ ] Create test order for that customer
- [ ] Create test payment for that order
- [ ] Delete the customer
- [ ] Verify order was deleted (CASCADE)
- [ ] Verify payment was deleted (CASCADE)
- [ ] No orphaned records remain

### Performance Tests
- [ ] Orders screen loads noticeably faster
- [ ] Payment screen loads noticeably faster
- [ ] Dashboard loads faster
- [ ] No lag when scrolling large lists

---

## CODE CLEANUP

- [ ] **CRITICAL:** Edit `lib/main.dart`
- [ ] **CRITICAL:** Remove line: `await forceDatabaseMigration();`
- [ ] **CRITICAL:** Save the file
- [ ] Optional: Delete `lib/force_db_migration.dart` (no longer needed)
- [ ] Optional: Remove import in main.dart: `import 'force_db_migration.dart';`
- [ ] Run app again to verify it still works without migration call
- [ ] Commit changes

---

## DOCUMENTATION REVIEW

- [ ] Read `DATABASE_V8_SCHEMA_REFERENCE.md` for new schema details
- [ ] Read `SCREEN_UPDATE_GUIDE.md` for next steps
- [ ] Bookmark optimized query methods for future use:
  - [ ] `getOrdersWithFullDetails()`
  - [ ] `getCustomerWithStats()`
  - [ ] `getPaymentAnalyticsData()`
  - [ ] `getOrdersWithPendingPayments()`
  - [ ] `getPaymentHistoryWithDetails()`

---

## NEXT STEPS (OPTIONAL - FOR PERFORMANCE)

- [ ] Update `orders_main_screen.dart` to use `getOrdersWithFullDetails()`
- [ ] Update `pending_orders_screen.dart` to use `getOrdersWithFullDetails(status: 'pending')`
- [ ] Update `completed_orders_screen.dart` to use `getOrdersWithFullDetails(status: 'completed')`
- [ ] Update `payment_collection_screen.dart` to use `getOrdersWithPendingPayments()`
- [ ] Update `payment_history_screen.dart` to use `getPaymentHistoryWithDetails()`
- [ ] Update `customer_details_screen.dart` to use `getCustomerWithStats()`
- [ ] Update `dashboard_screen.dart` to use `getPaymentAnalyticsData()`
- [ ] Test each updated screen
- [ ] Measure performance improvement (before/after)
- [ ] See `SCREEN_UPDATE_GUIDE.md` for code examples

---

## TROUBLESHOOTING (IF NEEDED)

If migration failed, check which error occurred:

- [ ] "FOREIGN KEY constraint failed"
  - → You have orphaned records
  - → Solution: Reset database with `await LocalDatabaseService().resetDatabase();`

- [ ] "duplicate column name: measurement_id"
  - → Migration already ran
  - → Solution: Just remove migration call from main.dart

- [ ] App crashes after migration
  - → Check console for specific error
  - → Check database version: should be 8
  - → Try resetting database if needed

- [ ] Data missing after migration
  - → Check logs for "Restored X records" messages
  - → Verify backup step completed
  - → May need to restore from external backup

---

## FINAL SIGN-OFF

Migration is COMPLETE when ALL of these are checked:

- [ ] ✅ Migration ran successfully
- [ ] ✅ App works without errors
- [ ] ✅ All CRUD operations functional
- [ ] ✅ CASCADE deletes work correctly
- [ ] ✅ Performance improved
- [ ] ✅ Migration call removed from main.dart
- [ ] ✅ Code committed

---

## METRICS (Fill in after migration)

**Pre-Migration:**
- Tailors: ______
- Customers: ______
- Measurements: ______
- Orders: ______
- Payments: ______

**Post-Migration:**
- Tailors: ______ (should match)
- Customers: ______ (should match)
- Measurements: ______ (should match)
- Orders: ______ (should match)
- Payments: ______ (should match)

**Performance:**
- Orders screen load time BEFORE: ______ ms
- Orders screen load time AFTER: ______ ms
- Improvement: ______ x faster

**Database Health:**
- Version: 8
- Tables: 11
- Foreign Keys: 12 (all with CASCADE)
- Indexes: 29
- Orphan Risk: 0%
- Health Score: 100/100 ✅

---

## SIGNATURE

**Migrated by:** ______________________

**Date:** _____ / _____ / 2025

**Time:** _____ : _____

**Status:** ✅ SUCCESS / ❌ FAILED

**Notes:**
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

---

*Keep this checklist for your records*
*Database Version 8*
*Migration Date: October 11, 2025*
