import 'package:flutter/material.dart';
import 'lib/data/services/local_db_service.dart';

/// Quick script to add a payment record for order ORDZTM56YW
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔥 Adding payment for order ORDZTM56YW...');
  
  final dbService = LocalDatabaseService();
  await dbService.database;
  
  // The order shows advance_paid: 300.0, so let's create a payment record for this
  final payment = {
    'id': 'PAYORD001',
    'unique_id': 'PAYORD001', 
    'order_id': 'ORDZTM56YW',
    'amount': 300.0,
    'method': 'Cash',
    'status': 'Completed',
    'paid_on': DateTime.now().subtract(Duration(days: 3)).toIso8601String(),
    'notes': 'Advance payment for shirt order',
    'transaction_id': 'TXN001ADV',
    'is_deleted': 0,
    'created_at': DateTime.now().subtract(Duration(days: 3)).toIso8601String(),
    'updated_at': DateTime.now().subtract(Duration(days: 3)).toIso8601String(),
  };
  
  try {
    final paymentId = await dbService.insert('payment', payment);
    print('✅ Successfully inserted payment: ID=$paymentId');
    print('   - Order ID: ${payment['order_id']}');
    print('   - Amount: ₹${payment['amount']}');
    print('   - Method: ${payment['method']}');
    print('   - Date: ${payment['paid_on']}');
    
    // Verify the payment was inserted
    final payments = await dbService.select(
      'payment',
      where: 'order_id = ?',
      whereArgs: ['ORDZTM56YW'],
    );
    
    print('🔍 Verification: Found ${payments.length} payments for order ORDZTM56YW');
    for (var p in payments) {
      print('   - Payment: ${p['id']}, Amount: ₹${p['amount']}, Method: ${p['method']}');
    }
    
    print('🎯 Now test the receipt generation in the app!');
    
  } catch (e) {
    print('❌ Error inserting payment: $e');
  }
}