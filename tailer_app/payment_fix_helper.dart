import 'package:flutter/material.dart';
import 'lib/data/services/local_db_service.dart';

/// Quick fix function to add missing payment record for order ORDZTM56YW
/// This can be called from the app during development to fix the data issue
Future<void> fixMissingPaymentRecord() async {
  try {
    print('🔧 Fixing missing payment record for order ORDZTM56YW...');
    
    final databaseService = LocalDatabaseService();
    
    // Check if order exists
    final orderResult = await databaseService.select(
      'orders',
      where: 'id = ?',
      whereArgs: ['ORDZTM56YW'],
      limit: 1,
    );
    
    if (orderResult.isEmpty) {
      print('❌ Order ORDZTM56YW not found in database');
      return;
    }
    
    final order = orderResult.first;
    print('✅ Found order: ${order['id']}');
    print('   Total: ₹${order['total_amount']}');
    print('   Advance Paid: ₹${order['advance_paid']}');
    print('   Balance: ₹${order['balance_amount']}');
    
    // Check existing payments
    final existingPayments = await databaseService.select(
      'payment',
      where: 'order_id = ? AND is_deleted = 0',
      whereArgs: ['ORDZTM56YW'],
    );
    
    print('Current payments for order: ${existingPayments.length}');
    
    if (existingPayments.isEmpty && order['advance_paid'] > 0) {
      // Create payment record for the advance amount
      final paymentId = 'PAY${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final currentTime = DateTime.now().toIso8601String();
      
      final paymentData = {
        'id': paymentId,
        'unique_id': paymentId,
        'order_id': 'ORDZTM56YW',
        'amount': order['advance_paid'],
        'method': 'advance',
        'notes': 'Advance payment - Fixed missing record',
        'created_at': currentTime,
        'updated_at': currentTime,
        'is_deleted': 0,
      };
      
      await databaseService.insert(
        'payment',
        paymentData,
      );
      
      print('✅ Payment record created successfully!');
      print('   ID: $paymentId');
      print('   Amount: ₹${order['advance_paid']}');
      print('   Method: advance');
      
      // Verify the fix
      final verifyPayments = await databaseService.select(
        'payment',
        where: 'order_id = ? AND is_deleted = 0',
        whereArgs: ['ORDZTM56YW'],
      );
      
      print('✅ Verification: ${verifyPayments.length} payment(s) now exist for order ORDZTM56YW');
      print('🎉 PDF generation should now show payment details!');
      
    } else if (existingPayments.isNotEmpty) {
      print('✅ Payment records already exist for this order');
      for (final payment in existingPayments) {
        print('   - ${payment['id']}: ₹${payment['amount']} (${payment['method']})');
      }
    } else {
      print('ℹ️ No advance payment to fix (advance_paid = 0)');
    }
    
  } catch (e) {
    print('❌ Error fixing payment record: $e');
  }
}

/// Widget to test the payment fix
class PaymentFixWidget extends StatelessWidget {
  const PaymentFixWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Fix Tool'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Missing Payment Record Fix',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'This will add a missing payment record for order ORDZTM56YW',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                try {
                  await fixMissingPaymentRecord();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment record fix completed! Check console for details.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Fix Missing Payment Record'),
            ),
          ],
        ),
      ),
    );
  }
}