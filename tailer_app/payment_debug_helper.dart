// Quick fix for ORDZTM56YW payment insertion issue
// This file contains enhanced error handling and validation for payment insertion

import '../lib/data/models/payment_model.dart';
import '../lib/data/enums/payment_method.dart';
import '../lib/data/services/local_db_service.dart';
import '../lib/core/utils/logger.dart';

/// Enhanced payment insertion with detailed debugging
Future<bool> debugAddPayment(String orderId, double amount, PaymentMethod method, String notes) async {
  final dbService = LocalDatabaseService();
  
  try {
    print('🔍 DEBUG: Starting payment insertion for order: "$orderId"');
    
    // Step 1: Verify the order exists with exact match
    final db = await dbService.database;
    final orderCheck = await db.rawQuery(
      'SELECT unique_id, customer_name, total_amount FROM orders WHERE unique_id = ? AND is_deleted = 0',
      [orderId]
    );
    
    if (orderCheck.isEmpty) {
      print('❌ ERROR: Order "$orderId" not found in database');
      
      // Find similar orders for debugging
      final similarOrders = await db.rawQuery(
        'SELECT unique_id FROM orders WHERE unique_id LIKE ? AND is_deleted = 0 LIMIT 5',
        ['%${orderId.substring(orderId.length > 5 ? orderId.length - 5 : 0)}%']
      );
      
      print('Similar order IDs found:');
      for (final order in similarOrders) {
        print('  - "${order['unique_id']}"');
      }
      
      return false;
    }
    
    print('✅ Order found: ${orderCheck.first}');
    final exactOrderId = orderCheck.first['unique_id'] as String;
    
    // Step 2: Check existing payments
    final existingPayments = await db.rawQuery(
      'SELECT unique_id, amount FROM payment WHERE order_id = ? AND is_deleted = 0',
      [exactOrderId]
    );
    print('📋 Existing payments: ${existingPayments.length}');
    
    // Step 3: Create payment with exact order ID from database
    final payment = Payment.create(
      orderId: exactOrderId, // Use the exact ID from database
      amount: amount,
      method: method,
      notes: notes,
    );
    
    print('💰 Creating payment: ${payment.uniqueId} for ₹$amount');
    
    // Step 4: Insert with detailed error handling
    final result = await dbService.addPayment(payment);
    
    if (result) {
      print('✅ Payment inserted successfully');
      
      // Verify insertion
      final verifyPayment = await db.rawQuery(
        'SELECT unique_id, amount, method FROM payment WHERE unique_id = ?',
        [payment.uniqueId]
      );
      
      if (verifyPayment.isNotEmpty) {
        print('✅ Payment verified: ${verifyPayment.first}');
      } else {
        print('⚠️ Payment not found after insertion - possible rollback');
      }
    } else {
      print('❌ Payment insertion failed');
    }
    
    return result;
    
  } catch (e, stackTrace) {
    print('💥 EXCEPTION during payment insertion: $e');
    print('Stack trace: $stackTrace');
    
    // Additional debugging for foreign key errors
    if (e.toString().contains('FOREIGN KEY constraint failed')) {
      print('\n🔍 FOREIGN KEY DEBUGGING:');
      
      try {
        final db = await dbService.database;
        
        // Check foreign key enforcement
        final fkStatus = await db.rawQuery('PRAGMA foreign_keys');
        print('Foreign keys enabled: $fkStatus');
        
        // Check the exact constraint
        final fkList = await db.rawQuery('PRAGMA foreign_key_list(payment)');
        print('Payment table foreign keys:');
        for (final fk in fkList) {
          print('  ${fk['from']} -> ${fk['table']}.${fk['to']}');
        }
        
        // Check if order exists with different casing or whitespace
        final flexibleOrderCheck = await db.rawQuery(
          'SELECT unique_id FROM orders WHERE TRIM(UPPER(unique_id)) = TRIM(UPPER(?)) AND is_deleted = 0',
          [orderId]
        );
        print('Flexible order search result: $flexibleOrderCheck');
        
      } catch (debugError) {
        print('Error during debugging: $debugError');
      }
    }
    
    return false;
  }
}

/// Wrapper function for easy testing
void main() async {
  print('🧪 Testing payment insertion for ORDZTM56YW');
  
  final result = await debugAddPayment(
    'ORDZTM56YW',
    20.0,
    PaymentMethod.cash,
    'Debug test payment'
  );
  
  print('Test result: ${result ? 'SUCCESS' : 'FAILED'}');
}