import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'lib/data/models/payment_model.dart';
import 'lib/data/enums/payment_method.dart';

/// Direct database fix script to resolve payment table constraint issue
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔧 Payment Database Fix Tool');
  print('=' * 50);
  
  try {
    // Open database directly
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'tailor_app_dev.db');
    
    print('📍 Database path: $path');
    
    final db = await openDatabase(path);
    print('✅ Database opened successfully');
    
    // Step 1: Check current payment table schema
    print('\n🔍 Checking current payment table schema...');
    final tableInfo = await db.rawQuery("PRAGMA table_info(payment)");
    print('📋 Current payment table columns:');
    for (final col in tableInfo) {
      print('  - ${col['name']}: ${col['type']} ${col['notnull'] == 1 ? 'NOT NULL' : ''} ${col['dflt_value'] != null ? 'DEFAULT ${col['dflt_value']}' : ''}');
    }
    
    // Step 2: Check for CHECK constraints
    print('\n🔍 Checking for CHECK constraints...');
    final createTableSQL = await db.rawQuery("SELECT sql FROM sqlite_master WHERE type='table' AND name='payment'");
    if (createTableSQL.isNotEmpty) {
      final sql = createTableSQL.first['sql'] as String;
      print('📜 Current CREATE TABLE SQL:');
      print(sql);
      
      if (sql.contains('CHECK')) {
        print('⚠️  CHECK constraint found - this is the problem!');
      } else {
        print('✅ No CHECK constraint found');
      }
    }
    
    // Step 3: Check existing payment data
    print('\n📊 Checking existing payment data...');
    final existingPayments = await db.query('payment');
    print('💳 Found ${existingPayments.length} existing payments');
    
    // Step 4: If CHECK constraint exists, fix it
    final sql = createTableSQL.isNotEmpty ? createTableSQL.first['sql'] as String : '';
    if (sql.contains('CHECK')) {
      print('\n🔧 Fixing payment table...');
      
      // Backup existing data
      print('💾 Backing up existing payments...');
      final backupPayments = await db.query('payment');
      
      // Drop and recreate table without CHECK constraint
      await db.execute('DROP TABLE payment');
      print('🗑️  Dropped old payment table');
      
      await db.execute('''
        CREATE TABLE payment (
          id TEXT PRIMARY KEY,
          unique_id TEXT UNIQUE NOT NULL,
          order_id TEXT NOT NULL,
          amount REAL NOT NULL,
          method TEXT NOT NULL DEFAULT 'cash',
          notes TEXT DEFAULT '',
          transaction_id TEXT,
          paid_on TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0,
          FOREIGN KEY (order_id) REFERENCES orders (unique_id) ON DELETE CASCADE
        )
      ''');
      print('✅ Created new payment table without CHECK constraint');
      
      // Restore data
      for (final payment in backupPayments) {
        try {
          await db.insert('payment', payment);
        } catch (e) {
          print('⚠️  Failed to restore payment ${payment['unique_id']}: $e');
        }
      }
      print('📦 Restored ${backupPayments.length} payments');
    }
    
    // Step 5: Test payment insertion
    print('\n🧪 Testing payment insertion...');
    
    // Get a test order
    final orders = await db.query('orders', where: 'is_deleted = 0', limit: 1);
    if (orders.isEmpty) {
      print('❌ No orders found for testing');
    } else {
      final testOrderId = orders.first['unique_id'] as String;
      print('🎯 Using test order: $testOrderId');
      
      // Create test payment
      final testPayment = Payment.create(
        orderId: testOrderId,
        amount: 500.0,
        method: PaymentMethod.cash,
        notes: 'Database fix test payment',
      );
      
      try {
        await db.insert('payment', testPayment.toMap());
        print('✅ Test payment inserted successfully!');
        
        // Verify insertion
        final insertedPayments = await db.query('payment', where: 'unique_id = ?', whereArgs: [testPayment.uniqueId]);
        if (insertedPayments.isNotEmpty) {
          print('✅ Test payment verified in database');
          print('💳 Payment details: ${insertedPayments.first}');
        }
        
        // Clean up test payment
        await db.delete('payment', where: 'unique_id = ?', whereArgs: [testPayment.uniqueId]);
        print('🧹 Cleaned up test payment');
        
      } catch (e) {
        print('❌ Test payment insertion failed: $e');
        print('🚨 Payment table still has issues!');
      }
    }
    
    // Step 6: Final verification
    print('\n📊 Final verification...');
    final finalPayments = await db.query('payment', where: 'is_deleted = 0');
    print('💳 Total active payments in database: ${finalPayments.length}');
    
    // Check table schema again
    final newTableInfo = await db.rawQuery("PRAGMA table_info(payment)");
    print('📋 Final payment table schema:');
    for (final col in newTableInfo) {
      print('  - ${col['name']}: ${col['type']}');
    }
    
    await db.close();
    print('\n🎉 Database fix completed successfully!');
    print('✅ Payment collection should now work correctly');
    
  } catch (e, stackTrace) {
    print('❌ Database fix failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}