import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

/// Script to update orders to make them appear in payment collection screen
/// This script will modify some orders to have pending payments
void main() async {
  // Initialize sqflite for desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  try {
    print('🔄 Starting order updates for payment collection...');
    
    // Get database path
    final databasePath = join(Directory.current.path, 'build', 'app', 'outputs', 'flutter-apk');
    final dbPath = join(databasePath, 'tailor_app.db');
    
    // Try alternative path
    final altPath = join(Directory.current.path, 'tailor_app.db');
    
    String finalPath = dbPath;
    if (!await File(dbPath).exists()) {
      if (await File(altPath).exists()) {
        finalPath = altPath;
      } else {
        print('❌ Database file not found. Please ensure the app has been run first.');
        print('Tried paths:');
        print('  - $dbPath');
        print('  - $altPath');
        return;
      }
    }
    
    print('📍 Using database: $finalPath');
    
    // Open database
    final db = await openDatabase(finalPath);
    
    // Get all orders
    final orders = await db.query('orders', where: 'is_deleted = 0');
    print('📊 Found ${orders.length} total orders');
    
    // Find orders that are fully paid (these won't show in payment collection)
    final fullyPaidOrders = orders.where((order) {
      final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
      final advancePaid = (order['advance_paid'] as num?)?.toDouble() ?? 0.0;
      return totalAmount <= advancePaid;
    }).toList();
    
    print('💰 Found ${fullyPaidOrders.length} fully paid orders that need payment balance');
    
    if (fullyPaidOrders.length < 2) {
      print('⚠️  Not enough fully paid orders found. Creating payment balances for active orders...');
      
      // Get orders that are not completed/delivered
      final activeOrders = orders.where((order) {
        final status = (order['status'] as String?)?.toLowerCase() ?? '';
        return status != 'completed' && status != 'delivered';
      }).toList();
      
      print('🔄 Found ${activeOrders.length} active orders');
      
      // Update first 10 orders to have pending payments (excluding the 2 existing ones)
      int updateCount = 0;
      final excludeIds = ['ORDLQD6QU5', 'ORD70OC1ME']; // Keep these 2 unchanged
      
      for (final order in activeOrders) {
        if (updateCount >= 10) break;
        
        final orderId = order['unique_id'] as String?;
        if (excludeIds.contains(orderId)) {
          print('⏭️  Skipping $orderId (keeping unchanged)');
          continue;
        }
        
        final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
        
        // Set advance paid to 50-80% of total (so there's still balance to collect)
        final advancePaid = totalAmount * (0.5 + (updateCount * 0.03)); // Varying percentages
        final balanceAmount = totalAmount - advancePaid;
        
        await db.update(
          'orders',
          {
            'advance_paid': advancePaid,
            'balance_amount': balanceAmount,
            'payment_status': 'partial',
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'unique_id = ?',
          whereArgs: [orderId],
        );
        
        print('✅ Updated $orderId: Total=₹${totalAmount.toStringAsFixed(0)}, '
              'Paid=₹${advancePaid.toStringAsFixed(0)}, '
              'Balance=₹${balanceAmount.toStringAsFixed(0)}');
        
        updateCount++;
      }
      
      print('🎉 Successfully updated $updateCount orders!');
      print('💡 These orders will now appear in payment collection screen');
      
    } else {
      // Update some fully paid orders to have pending payments
      int updateCount = 0;
      final excludeIds = ['ORDLQD6QU5', 'ORD70OC1ME']; // Keep these 2 unchanged
      
      for (final order in fullyPaidOrders) {
        if (updateCount >= 8) break;
        
        final orderId = order['unique_id'] as String?;
        if (excludeIds.contains(orderId)) {
          print('⏭️  Skipping $orderId (keeping unchanged)');
          continue;
        }
        
        final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
        
        // Reduce advance paid to create pending payment
        final advancePaid = totalAmount * (0.6 + (updateCount * 0.05)); // 60-95% paid
        final balanceAmount = totalAmount - advancePaid;
        
        await db.update(
          'orders',
          {
            'advance_paid': advancePaid,
            'balance_amount': balanceAmount,
            'payment_status': 'partial',
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'unique_id = ?',
          whereArgs: [orderId],
        );
        
        print('✅ Updated $orderId: Total=₹${totalAmount.toStringAsFixed(0)}, '
              'Paid=₹${advancePaid.toStringAsFixed(0)}, '
              'Balance=₹${balanceAmount.toStringAsFixed(0)}');
        
        updateCount++;
      }
      
      print('🎉 Successfully updated $updateCount orders!');
    }
    
    // Verify the changes
    final updatedOrders = await db.query('orders', where: 'is_deleted = 0');
    final ordersWithPendingPayments = updatedOrders.where((order) {
      final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
      final advancePaid = (order['advance_paid'] as num?)?.toDouble() ?? 0.0;
      return totalAmount > advancePaid;
    }).length;
    
    print('📈 Result: $ordersWithPendingPayments orders now have pending payments');
    print('🔄 Please restart the app to see the changes in payment collection screen');
    
    await db.close();
    
  } catch (e) {
    print('❌ Error: $e');
  }
}