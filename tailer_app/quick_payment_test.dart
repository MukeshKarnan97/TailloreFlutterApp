import 'package:flutter/material.dart';
import 'lib/data/services/local_db_service.dart';

/// Quick script to add a payment to an existing order for testing
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔥 Adding Test Payment Data...');
  
  final dbService = LocalDatabaseService();
  
  // Wait for database to initialize
  await dbService.database;
  
  // First, let's see what orders exist
  print('📋 Checking existing orders...');
  final orders = await dbService.select('orders', limit: 5);
  
  if (orders.isEmpty) {
    print('❌ No orders found. Please create some orders first.');
    return;
  }
  
  print('📦 Found ${orders.length} orders:');
  for (var order in orders) {
    print('  - Order ID: ${order['id']}, Unique ID: ${order['unique_id']}, Amount: ₹${order['total_amount']}');
  }
  
  // Take the first order and add some payments
  final firstOrder = orders.first;
  final orderId = firstOrder['unique_id'];
  final totalAmount = double.tryParse(firstOrder['total_amount']?.toString() ?? '0') ?? 0.0;
  
  print('💰 Adding payments to order: $orderId (Total: ₹$totalAmount)');
  
  // Add multiple payments
  final payments = [
    {
      'order_id': orderId,
      'amount': (totalAmount * 0.5).toStringAsFixed(2), // 50% advance
      'method': 'Cash',
      'status': 'Completed',
      'paid_on': DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
      'notes': 'Advance payment for order',
      'transaction_id': 'TXN001${DateTime.now().millisecondsSinceEpoch}',
      'is_deleted': 0,
      'created_at': DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
      'updated_at': DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
    },
    {
      'order_id': orderId,
      'amount': (totalAmount * 0.3).toStringAsFixed(2), // 30% partial
      'method': 'UPI',
      'status': 'Completed',
      'paid_on': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
      'notes': 'Partial payment via UPI',
      'transaction_id': 'UPI002${DateTime.now().millisecondsSinceEpoch}',
      'is_deleted': 0,
      'created_at': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
      'updated_at': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
    },
  ];
  
  int insertedCount = 0;
  for (var payment in payments) {
    try {
      final paymentId = await dbService.insert('payment', payment);
      print('✅ Inserted payment: ID=$paymentId, Amount=₹${payment['amount']}, Method=${payment['method']}');
      insertedCount++;
    } catch (e) {
      print('❌ Failed to insert payment: $e');
    }
  }
  
  print('🎉 Successfully added $insertedCount payments to order $orderId');
  print('💡 Remaining balance: ₹${(totalAmount * 0.2).toStringAsFixed(2)} (20%)');
  
  // Verify payments were inserted
  print('🔍 Verifying payments...');
  final insertedPayments = await dbService.select(
    'payment',
    where: 'order_id = ? AND is_deleted = 0',
    whereArgs: [orderId],
  );
  
  print('✅ Found ${insertedPayments.length} payments for order $orderId:');
  for (var payment in insertedPayments) {
    print('  - Payment ID: ${payment['id']}, Amount: ₹${payment['amount']}, Method: ${payment['method']}, Date: ${payment['paid_on']}');
  }
  
  print('🎯 Now test the receipt generation in the app!');
}