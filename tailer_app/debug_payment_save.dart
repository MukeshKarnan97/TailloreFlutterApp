import 'dart:io';
import 'package:flutter/material.dart';
import 'lib/data/services/local_db_service.dart';
import 'lib/data/models/payment_model.dart';
import 'lib/data/enums/payment_method.dart';

/// Debug script to test payment saving functionality
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔍 Debug Payment Save Test');
  print('=' * 40);
  
  try {
    final dbService = LocalDatabaseService();
    await dbService.database;
    
    print('✅ Database connection established');
    
    // Check existing payments before test
    final db = await dbService.database;
    final existingPayments = await db.query('payment', where: 'is_deleted = 0');
    print('📊 Existing payments in database: ${existingPayments.length}');
    
    // Check if we have any orders to test with
    final orders = await db.query('orders', where: 'is_deleted = 0', limit: 1);
    if (orders.isEmpty) {
      print('❌ No orders found! Cannot test payment save without orders.');
      print('💡 Please create some orders first through the app.');
      exit(1);
    }
    
    final testOrderId = orders.first['unique_id'] as String;
    print('🎯 Testing with order: $testOrderId');
    
    // Create a test payment
    final testPayment = Payment.create(
      orderId: testOrderId,
      amount: 100.0,
      method: PaymentMethod.cash,
      notes: 'Debug test payment',
    );
    
    print('💳 Created test payment object: ${testPayment.uniqueId}');
    print('📝 Payment details:');
    print('   - Order ID: ${testPayment.orderId}');
    print('   - Amount: ₹${testPayment.amount}');
    print('   - Method: ${testPayment.method.displayName}');
    print('   - Notes: ${testPayment.notes}');
    
    // Try to save the payment
    print('\n🔄 Attempting to save payment...');
    final saveResult = await dbService.addPayment(testPayment);
    print('💾 Save result: $saveResult');
    
    if (saveResult) {
      print('✅ Payment saved successfully!');
      
      // Verify the payment was actually saved
      final savedPayments = await db.query(
        'payment', 
        where: 'unique_id = ? AND is_deleted = 0',
        whereArgs: [testPayment.uniqueId]
      );
      
      if (savedPayments.isNotEmpty) {
        print('✅ Payment verified in database!');
        print('📋 Saved payment data: ${savedPayments.first}');
        
        // Test payment retrieval through service
        final retrievedPayments = await dbService.getPaymentsByOrderId(testOrderId);
        print('🔍 Retrieved ${retrievedPayments.length} payments for order $testOrderId');
        
        // Test getting all payments
        final allPayments = await dbService.getPayments();
        print('📊 Total payments in database: ${allPayments.length}');
        
        // Clean up test payment
        await db.delete('payment', where: 'unique_id = ?', whereArgs: [testPayment.uniqueId]);
        print('🧹 Cleaned up test payment');
        
      } else {
        print('❌ ERROR: Payment was not found in database after save!');
        print('🚨 This indicates a database save issue.');
      }
      
    } else {
      print('❌ ERROR: Payment save failed!');
      print('🚨 Check LocalDatabaseService.addPayment() method.');
    }
    
    // Final summary
    final finalPayments = await db.query('payment', where: 'is_deleted = 0');
    print('\n📊 Final payment count: ${finalPayments.length}');
    print('✅ Debug test completed!');
    
  } catch (e, stackTrace) {
    print('❌ Debug test failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}