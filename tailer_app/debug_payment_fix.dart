import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Debug script to investigate and fix ORDZTM56YW payment insertion issue
/// Run this with: flutter run debug_payment_fix.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('🔍 INVESTIGATING ORDZTM56YW FOREIGN KEY ISSUE');
    
    // Open database using the same method as the app
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'tailor_app.db');
    
    print('📁 Database path: $path');
    
    final db = await openDatabase(path);
    
    // 1. Check if foreign keys are enabled
    print('\n🔐 Checking foreign key enforcement...');
    final fkEnabled = await db.rawQuery('PRAGMA foreign_keys');
    print('Foreign keys enabled: $fkEnabled');
    
    // 2. Check if order ORDZTM56YW exists (exact match)
    print('\n📋 Checking order ORDZTM56YW...');
    final orderResult = await db.rawQuery(
      "SELECT unique_id, customer_name, total_amount, advance_paid FROM orders WHERE unique_id = 'ORDZTM56YW'"
    );
    
    if (orderResult.isEmpty) {
      print('❌ Order ORDZTM56YW NOT FOUND');
      
      // Find similar orders
      print('\nSearching for similar order IDs...');
      final similarOrders = await db.rawQuery(
        "SELECT unique_id FROM orders WHERE unique_id LIKE '%ORDZTM56YW%' OR unique_id LIKE '%ORD%' ORDER BY unique_id"
      );
      
      print('Similar orders found: ${similarOrders.length}');
      for (final order in similarOrders.take(10)) {
        print('  - ${order['unique_id']}');
      }
      
      await db.close();
      print('\n❌ Cannot proceed: Order ORDZTM56YW does not exist in the database');
      return;
    }
    
    print('✅ Order found: ${orderResult.first}');
    final orderData = orderResult.first;
    final orderId = orderData['unique_id'] as String;
    
    // 3. Check existing payments for this order
    print('\n💰 Checking existing payments...');
    final existingPayments = await db.rawQuery(
      "SELECT unique_id, amount, method, paid_on FROM payment WHERE order_id = ? AND is_deleted = 0",
      [orderId]
    );
    print('Existing payments: ${existingPayments.length}');
    for (final payment in existingPayments) {
      print('  - ${payment['unique_id']}: ₹${payment['amount']} via ${payment['method']}');
    }
    
    // 4. Try to insert a test payment
    print('\n🧪 Testing payment insertion...');
    
    final testPaymentId = 'PAYTEST${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final now = DateTime.now().toIso8601String();
    
    try {
      await db.transaction((txn) async {
        final result = await txn.rawInsert('''
          INSERT INTO payment (
            id, unique_id, order_id, amount, method, notes, 
            paid_on, created_at, updated_at, is_deleted
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
          testPaymentId,
          testPaymentId,
          orderId, // Use the exact order_id from database
          20.0,
          'cash',
          'Test payment for debugging',
          now,
          now,
          now,
          0
        ]);
        
        print('✅ Test payment inserted successfully with ID: $result');
        
        // Verify the payment was inserted
        final verifyResult = await txn.rawQuery(
          "SELECT * FROM payment WHERE unique_id = ?",
          [testPaymentId]
        );
        
        if (verifyResult.isNotEmpty) {
          print('✅ Payment verified in database: ${verifyResult.first}');
        } else {
          print('❌ Payment not found after insertion');
        }
        
        // Clean up test payment
        await txn.rawDelete("DELETE FROM payment WHERE unique_id = ?", [testPaymentId]);
        print('🧹 Test payment cleaned up');
      });
      
      print('\n✅ SUCCESS: Foreign key constraint is working correctly!');
      print('The issue might be with the app logic, not the database constraint.');
      
    } catch (e) {
      print('\n❌ FOREIGN KEY CONSTRAINT ERROR: $e');
      
      // Additional debugging
      print('\n🔍 Additional investigation...');
      
      // Check the exact foreign key definition
      final fkList = await db.rawQuery("PRAGMA foreign_key_list(payment)");
      print('Foreign key constraints on payment table:');
      for (final fk in fkList) {
        print('  - ${fk['from']} -> ${fk['table']}.${fk['to']}');
      }
      
      // Check if there are any data type mismatches
      final orderSchema = await db.rawQuery("PRAGMA table_info(orders)");
      final paymentSchema = await db.rawQuery("PRAGMA table_info(payment)");
      
      print('\nOrder table unique_id column:');
      for (final col in orderSchema.where((c) => c['name'] == 'unique_id')) {
        print('  Type: ${col['type']}, NotNull: ${col['notnull']}');
      }
      
      print('\nPayment table order_id column:');
      for (final col in paymentSchema.where((c) => c['name'] == 'order_id')) {
        print('  Type: ${col['type']}, NotNull: ${col['notnull']}');
      }
    }
    
    await db.close();
    print('\n🏁 Investigation completed');
    
  } catch (e, stackTrace) {
    print('💥 Error during investigation: $e');
    print('Stack trace: $stackTrace');
  }
}