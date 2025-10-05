import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'lib/data/services/local_db_service.dart';
import 'lib/data/models/payment_model.dart';
import 'lib/data/enums/payment_method.dart';

/// Test script to create payment records for existing orders
/// Run this with: dart create_payment_test_data.dart
class PaymentTestData {
  static const String TAILOR_ID = 'admin1@gmail.com';
  
  /// Sample payment notes and transaction references
  static const List<String> SAMPLE_NOTES = [
    'First advance payment',
    'Final payment completion',
    'Partial payment - remaining balance',
    'Rush order payment',
    'Wedding order advance',
    'Custom fitting charges',
    'Delivery payment',
    'Material cost payment',
    'Labor charges',
    'Express service payment',
    'Alteration charges',
    'Premium fabric charges',
  ];

  static const List<String> UPI_REFS = [
    'UPI/335467890123/Payment/HDFC',
    'UPI/445567890234/Payment/ICICI', 
    'UPI/555667890345/Payment/SBI',
    'UPI/665767890456/Payment/AXIS',
    'UPI/775867890567/Payment/KOTAK',
  ];

  static const List<String> CARD_REFS = [
    'CARD****1234/AUTH/123456',
    'CARD****5678/AUTH/234567',
    'CARD****9012/AUTH/345678',
    'CARD****3456/AUTH/456789',
    'CARD****7890/AUTH/567890',
  ];

  static const List<String> BANK_REFS = [
    'NEFT/HDFC/N123456789',
    'RTGS/ICICI/R234567890',
    'IMPS/SBI/I345678901',
    'NEFT/AXIS/N456789012',
    'RTGS/KOTAK/R567890123',
  ];

  static Future<void> createPaymentTestData() async {
    print('🚀 Creating Payment Test Data...');
    print('=' * 50);
    
    try {
      final dbService = LocalDatabaseService();
      
      // Initialize database
      await dbService.database;
      
      // Get all existing orders
      print('📦 Fetching existing orders...');
      final orders = await _getExistingOrders(dbService);
      
      if (orders.isEmpty) {
        print('❌ No orders found! Please run order test data first.');
        print('💡 Run: dart test_order_status_data.dart');
        return;
      }
      
      print('📋 Found ${orders.length} orders to create payments for');
      
      // Clear existing payments first
      print('🧹 Clearing existing payment data...');
      await _clearExistingPayments(dbService);
      
      // Create payments for orders
      print('💰 Creating payment records...');
      int paymentCount = 0;
      
      for (final order in orders) {
        final paymentsCreated = await _createPaymentsForOrder(dbService, order);
        paymentCount += paymentsCreated;
        
        // Add some delay to make creation times more realistic
        await Future.delayed(Duration(milliseconds: 100));
      }
      
      // Print summary
      await _printPaymentSummary(dbService);
      
      print('\n✅ Payment test data creation completed!');
      print('💳 Created $paymentCount payment records');
      print('🎯 You can now test the Payment History screen');
      print('🔐 Login with: admin1@gmail.com / Admin@123');
      
    } catch (e, stackTrace) {
      print('❌ Error creating payment test data: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Get existing orders from database
  static Future<List<Map<String, dynamic>>> _getExistingOrders(LocalDatabaseService dbService) async {
    try {
      final db = await dbService.database;
      final result = await db.query(
        'orders',
        where: 'is_deleted = 0',
        orderBy: 'created_at DESC',
      );
      return result;
    } catch (e) {
      print('❌ Error fetching orders: $e');
      return [];
    }
  }

  /// Clear existing payment data
  static Future<void> _clearExistingPayments(LocalDatabaseService dbService) async {
    try {
      final db = await dbService.database;
      await db.delete('payment');
      print('  ✅ Cleared existing payment records');
    } catch (e) {
      print('  ❌ Error clearing payments: $e');
    }
  }

  /// Create realistic payment records for an order
  static Future<int> _createPaymentsForOrder(LocalDatabaseService dbService, Map<String, dynamic> order) async {
    try {
      final String orderId = order['unique_id'];
      final double totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
      final double advancePaid = (order['advance_paid'] as num?)?.toDouble() ?? 0.0;
      final String status = order['status'] ?? 'pending';
      
      print('  📝 Creating payments for Order: $orderId (₹$totalAmount)');
      
      int paymentsCreated = 0;
      
      // Create advance payment if there is any advance paid
      if (advancePaid > 0) {
        final advancePayment = await _createSinglePayment(
          dbService,
          orderId,
          advancePaid,
          _getRandomPaymentMethod(),
          'Advance payment for order',
          _getDaysAgo(Random().nextInt(30) + 1), // 1-30 days ago
        );
        
        if (advancePayment) {
          paymentsCreated++;
          print('    ✅ Advance payment: ₹$advancePaid');
        }
      }
      
      // For completed or delivered orders, create final payment
      if ((status == 'completed' || status == 'delivered') && totalAmount > advancePaid) {
        final remainingAmount = totalAmount - advancePaid;
        final finalPayment = await _createSinglePayment(
          dbService,
          orderId,
          remainingAmount,
          _getRandomPaymentMethod(),
          'Final payment completion',
          _getDaysAgo(Random().nextInt(5) + 1), // 1-5 days ago
        );
        
        if (finalPayment) {
          paymentsCreated++;
          print('    ✅ Final payment: ₹$remainingAmount');
        }
      }
      
      // For some orders, create additional partial payments
      else if (Random().nextBool() && totalAmount > advancePaid) {
        final remainingAmount = totalAmount - advancePaid;
        if (remainingAmount > 500) {
          final partialAmount = (remainingAmount * 0.3) + (Random().nextDouble() * remainingAmount * 0.4);
          final partialPayment = await _createSinglePayment(
            dbService,
            orderId,
            partialAmount,
            _getRandomPaymentMethod(),
            'Partial payment - ${_getRandomNote()}',
            _getDaysAgo(Random().nextInt(10) + 1), // 1-10 days ago
          );
          
          if (partialPayment) {
            paymentsCreated++;
            print('    ✅ Partial payment: ₹${partialAmount.toStringAsFixed(2)}');
          }
        }
      }
      
      return paymentsCreated;
      
    } catch (e) {
      print('  ❌ Error creating payments for order: $e');
      return 0;
    }
  }

  /// Create a single payment record
  static Future<bool> _createSinglePayment(
    LocalDatabaseService dbService,
    String orderId,
    double amount,
    PaymentMethod method,
    String notes,
    DateTime paidOn,
  ) async {
    try {
      final payment = Payment.create(
        orderId: orderId,
        amount: amount,
        method: method,
        notes: notes,
        transactionId: _getTransactionId(method),
        paidOn: paidOn,
      );
      
      final success = await dbService.addPayment(payment);
      return success;
      
    } catch (e) {
      print('    ❌ Error creating payment: $e');
      return false;
    }
  }

  /// Get random payment method
  static PaymentMethod _getRandomPaymentMethod() {
    final methods = PaymentMethod.values;
    return methods[Random().nextInt(methods.length)];
  }

  /// Get random note
  static String _getRandomNote() {
    return SAMPLE_NOTES[Random().nextInt(SAMPLE_NOTES.length)];
  }

  /// Generate transaction ID based on payment method
  static String? _getTransactionId(PaymentMethod method) {
    final random = Random();
    
    switch (method) {
      case PaymentMethod.cash:
        return null; // Cash doesn't have transaction ID
        
      case PaymentMethod.upi:
        return UPI_REFS[random.nextInt(UPI_REFS.length)];
        
      case PaymentMethod.card:
        return CARD_REFS[random.nextInt(CARD_REFS.length)];
        
      case PaymentMethod.bank:
        return BANK_REFS[random.nextInt(BANK_REFS.length)];
    }
  }

  /// Get date X days ago
  static DateTime _getDaysAgo(int days) {
    return DateTime.now().subtract(Duration(days: days));
  }

  /// Print payment summary
  static Future<void> _printPaymentSummary(LocalDatabaseService dbService) async {
    try {
      print('\n📊 Payment Summary:');
      print('=' * 30);
      
      final db = await dbService.database;
      
      // Total payments
      final totalResult = await db.rawQuery('SELECT COUNT(*) as count, SUM(amount) as total FROM payment WHERE is_deleted = 0');
      final totalCount = totalResult.first['count'] as int;
      final totalAmount = (totalResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      print('💰 Total Payments: $totalCount (₹${totalAmount.toStringAsFixed(2)})');
      
      // Payment by method
      final methodResult = await db.rawQuery('''
        SELECT method, COUNT(*) as count, SUM(amount) as total 
        FROM payment 
        WHERE is_deleted = 0 
        GROUP BY method 
        ORDER BY count DESC
      ''');
      
      print('\n📈 Payment Methods:');
      for (final row in methodResult) {
        final method = row['method'] as String;
        final count = row['count'] as int;
        final amount = (row['total'] as num?)?.toDouble() ?? 0.0;
        print('  • ${method.toUpperCase()}: $count payments (₹${amount.toStringAsFixed(2)})');
      }
      
      // Recent payments
      final recentResult = await db.rawQuery('''
        SELECT p.unique_id, p.order_id, p.amount, p.method, p.paid_on
        FROM payment p
        WHERE p.is_deleted = 0
        ORDER BY p.paid_on DESC
        LIMIT 5
      ''');
      
      print('\n🕒 Recent Payments:');
      for (final row in recentResult) {
        final paymentId = row['unique_id'] as String;
        final orderId = row['order_id'] as String;
        final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
        final method = row['method'] as String;
        print('  • $paymentId: ₹${amount.toStringAsFixed(2)} via $method (Order: $orderId)');
      }
      
    } catch (e) {
      print('❌ Error getting payment summary: $e');
    }
  }
}

/// Main function to run the payment test data creation
void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  print('💳 Payment Test Data Generator');
  print('=' * 50);
  print('This will create realistic payment records for existing orders');
  print('Make sure you have orders in the database first!');
  print('');
  
  await PaymentTestData.createPaymentTestData();
  
  print('\n🎉 Payment test completed! You can now see payments in the Payment History screen.');
  exit(0);
}
