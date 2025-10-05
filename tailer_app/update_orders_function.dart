// Direct Database Update Script for Payment Collection
// This script will update orders to make them appear in payment collection screen
// Run this by adding it to main.dart temporarily or as a separate function

import 'package:tailer_app/data/services/local_db_service.dart';

Future<void> updateOrdersForPaymentCollection() async {
  print('🔄 Starting order updates for payment collection...');
  
  try {
    final dbService = LocalDatabaseService();
    
    // Get all orders
    final orders = await dbService.select('orders', where: 'is_deleted = 0');
    print('📊 Found ${orders.length} total orders');
    
    // Find orders that need updating (excluding the 2 reference orders)
    final excludeIds = ['ORDLQD6QU5', 'ORD70OC1ME'];
    final ordersToUpdate = orders.where((order) {
      final orderId = order['unique_id'] as String;
      final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
      final advancePaid = (order['advance_paid'] as num?)?.toDouble() ?? 0.0;
      final status = (order['status'] as String?)?.toLowerCase() ?? '';
      
      // Skip excluded orders and completed/delivered orders
      return !excludeIds.contains(orderId) && 
             status != 'completed' && 
             status != 'delivered' &&
             totalAmount > 0;
    }).toList();
    
    print('🎯 Found ${ordersToUpdate.length} orders to update');
    
    int updateCount = 0;
    for (int i = 0; i < ordersToUpdate.length && i < 10; i++) {
      final order = ordersToUpdate[i];
      final orderId = order['unique_id'] as String;
      final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
      
      // Calculate new advance payment (varying percentages)
      double paymentPercentage;
      switch (i % 4) {
        case 0: paymentPercentage = 0.30; break; // 30% paid
        case 1: paymentPercentage = 0.50; break; // 50% paid  
        case 2: paymentPercentage = 0.70; break; // 70% paid
        case 3: paymentPercentage = 0.40; break; // 40% paid
        default: paymentPercentage = 0.60; break;
      }
      
      final newAdvancePaid = totalAmount * paymentPercentage;
      final newBalanceAmount = totalAmount - newAdvancePaid;
      
      // Update the order
      await dbService.update(
        'orders',
        {
          'advance_paid': newAdvancePaid,
          'balance_amount': newBalanceAmount, 
          'payment_status': newAdvancePaid > 0 ? 'partial' : 'pending',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'unique_id = ?',
        whereArgs: [orderId],
      );
      
      print('✅ Updated $orderId: Total=₹${totalAmount.toStringAsFixed(0)}, '
            'Paid=₹${newAdvancePaid.toStringAsFixed(0)} (${(paymentPercentage*100).toStringAsFixed(0)}%), '
            'Balance=₹${newBalanceAmount.toStringAsFixed(0)}');
      
      updateCount++;
    }
    
    // Verify results
    final updatedOrders = await dbService.select('orders', where: 'is_deleted = 0');
    final pendingPaymentOrders = updatedOrders.where((order) {
      final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
      final advancePaid = (order['advance_paid'] as num?)?.toDouble() ?? 0.0;
      final status = (order['status'] as String?)?.toLowerCase() ?? '';
      return totalAmount > advancePaid && 
             status != 'completed' && 
             status != 'delivered';
    }).length;
    
    print('🎉 Update complete!');
    print('📈 Result: $pendingPaymentOrders orders now have pending payments');
    print('💡 Updated $updateCount orders (kept ORDLQD6QU5 and ORD70OC1ME unchanged)');
    print('🔄 Payment collection screen should now show more orders');
    
  } catch (e, stackTrace) {
    print('❌ Error updating orders: $e');
    print('Stack trace: $stackTrace');
  }
}

// To use this function, add it to your app and call it once:
// 1. Add the function above to your main.dart or a utility file
// 2. Call updateOrdersForPaymentCollection() once from main() or a debug button
// 3. Restart the app to see the updated orders in payment collection screen