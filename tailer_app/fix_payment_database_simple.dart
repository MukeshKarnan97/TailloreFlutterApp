import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

/// Simple standalone script to fix payment table database constraint issues
/// This script will directly access the SQLite database and fix the CHECK constraint
Future<void> main() async {
  print('🔧 Payment Database Fix Tool');
  print('================================\n');

  try {
    // Get the database path - matching the app's path structure
    final String databasesPath = await getDatabasesPath();
    final String dbPath = path.join(databasesPath, 'tailor_app.db');
    
    print('📁 Database path: $dbPath');
    
    // Check if database exists
    if (!await File(dbPath).exists()) {
      print('❌ Database file not found at: $dbPath');
      print('   Make sure the app has been run at least once to create the database.');
      return;
    }
    
    print('✅ Database file found');
    
    // Open database
    final Database db = await openDatabase(dbPath);
    print('🔌 Connected to database');
    
    // Step 1: Get current payment table schema
    print('\n📋 Checking current payment table schema...');
    final List<Map<String, dynamic>> tableInfo = await db.rawQuery(
      "SELECT sql FROM sqlite_master WHERE type='table' AND name='payment'"
    );
    
    if (tableInfo.isEmpty) {
      print('❌ Payment table not found');
      await db.close();
      return;
    }
    
    final String currentSchema = tableInfo.first['sql'] as String;
    print('Current schema:');
    print('   $currentSchema');
    
    // Check if CHECK constraint exists
    if (currentSchema.contains('CHECK(method IN')) {
      print('⚠️  Found CHECK constraint - this is causing payment save failures');
      
      // Step 2: Backup existing payment data
      print('\n💾 Backing up existing payment data...');
      final List<Map<String, dynamic>> existingPayments = await db.query('payment');
      print('   Backed up ${existingPayments.length} payment records');
      
      // Step 3: Drop the existing table
      print('\n🗑️  Dropping existing payment table...');
      await db.execute('DROP TABLE payment');
      print('   ✅ Table dropped');
      
      // Step 4: Create new table without CHECK constraint
      print('\n🔨 Creating new payment table without CHECK constraint...');
      await db.execute('''
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
        )
      ''');
      print('   ✅ New table created without CHECK constraint');
      
      // Step 5: Restore backed up data
      if (existingPayments.isNotEmpty) {
        print('\n📤 Restoring payment data...');
        for (final payment in existingPayments) {
          await db.insert('payment', payment);
        }
        print('   ✅ Restored ${existingPayments.length} payment records');
      }
      
      // Step 6: Test payment insertion
      print('\n🧪 Testing payment insertion...');
      try {
        final testPaymentId = 'TEST_${DateTime.now().millisecondsSinceEpoch}';
        await db.insert('payment', {
          'unique_id': testPaymentId,
          'order_id': 'TEST_ORDER',
          'customer_id': 'TEST_CUSTOMER',
          'amount': 100.0,
          'payment_type': 'partial',
          'method': 'cash',
          'notes': 'Test payment',
          'paid_on': DateTime.now().toIso8601String(),
        });
        
        // Verify insertion
        final testResult = await db.query('payment', where: 'unique_id = ?', whereArgs: [testPaymentId]);
        if (testResult.isNotEmpty) {
          print('   ✅ Test payment inserted successfully');
          
          // Clean up test payment
          await db.delete('payment', where: 'unique_id = ?', whereArgs: [testPaymentId]);
          print('   🧹 Test payment cleaned up');
        } else {
          print('   ❌ Test payment insertion failed');
        }
      } catch (e) {
        print('   ❌ Test payment insertion failed: $e');
      }
      
    } else {
      print('✅ No CHECK constraint found - table schema is correct');
    }
    
    // Step 7: Show final table schema
    print('\n📋 Final payment table schema:');
    final List<Map<String, dynamic>> finalTableInfo = await db.rawQuery(
      "SELECT sql FROM sqlite_master WHERE type='table' AND name='payment'"
    );
    
    if (finalTableInfo.isNotEmpty) {
      final String finalSchema = finalTableInfo.first['sql'] as String;
      print('   $finalSchema');
    }
    
    // Step 8: Show payment count
    final List<Map<String, dynamic>> countResult = await db.rawQuery('SELECT COUNT(*) as count FROM payment');
    final int paymentCount = countResult.first['count'] as int;
    print('\n📊 Total payments in database: $paymentCount');
    
    await db.close();
    print('\n✅ Database fix completed successfully!');
    print('🎉 Payment collection should now work properly.');
    
  } catch (e, stackTrace) {
    print('❌ Error fixing database: $e');
    print('Stack trace: $stackTrace');
  }
}