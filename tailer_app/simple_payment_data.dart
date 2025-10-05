import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'lib/data/services/local_db_service.dart';
import 'lib/data/models/payment_model.dart';
import 'lib/data/enums/payment_method.dart';

/// Simple script to create payment test data
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('💳 Creating Payment Test Data...');
  
  try {
    final dbService = LocalDatabaseService();
    await dbService.database;
    
    // Get existing orders
    final db = await dbService.database;
    final orders = await db.query('orders', where: 'is_deleted = 0', limit: 10);
    
    if (orders.isEmpty) {
      print('❌ No orders found! Please create some orders first.');
      print('💡 Tip: Run the orders main screen and use "Insert Test Data"');
      exit(1);
    }
    
    print('📦 Found ${orders.length} orders');
    
    // Clear existing payments
    await db.delete('payment');
    print('🧹 Cleared existing payments');
    
    // Create realistic payment data
    final random = Random();
    
    for (final order in orders) {
      final orderId = order['unique_id'] as String;
      final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
      final advancePaid = (order['advance_paid'] as num?)?.toDouble() ?? 0.0;
      
      // Create advance payment
      if (advancePaid > 0) {
        final payment1 = Payment.create(
          orderId: orderId,
          amount: advancePaid,
          method: PaymentMethod.values[random.nextInt(PaymentMethod.values.length)],
          notes: 'Advance payment',
          paidOn: DateTime.now().subtract(Duration(days: random.nextInt(15) + 1)),
        );
        
        await dbService.addPayment(payment1);
        print('  ✅ Added advance payment: ₹$advancePaid for order $orderId');
      }
      
      // Create additional partial payments for some orders
      if (random.nextBool() && totalAmount > advancePaid) {
        final remaining = totalAmount - advancePaid;
        final partialAmount = remaining * (0.2 + random.nextDouble() * 0.5);
        
        final payment2 = Payment.create(
          orderId: orderId,
          amount: partialAmount,
          method: PaymentMethod.values[random.nextInt(PaymentMethod.values.length)],
          notes: 'Partial payment - material cost',
          paidOn: DateTime.now().subtract(Duration(days: random.nextInt(7) + 1)),
        );
        
        await dbService.addPayment(payment2);
        print('  ✅ Added partial payment: ₹${partialAmount.toStringAsFixed(2)} for order $orderId');
      }
    }
    
    // Print summary
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count, SUM(amount) as total FROM payment');
    final totalCount = totalResult.first['count'] as int;
    final totalAmountSum = (totalResult.first['total'] as num?)?.toDouble() ?? 0.0;
    
    print('\n📊 Payment Summary:');
    print('💰 Total Payments: $totalCount');
    print('💵 Total Amount: ₹${totalAmountSum.toStringAsFixed(2)}');
    print('\n✅ Payment test data created successfully!');
    print('🎯 You can now view the Payment History screen');
    
  } catch (e) {
    print('❌ Error: $e');
  }
  
  exit(0);
}