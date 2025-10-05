import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

void main() async {
  try {
    print('🔍 QUICK FOREIGN KEY INVESTIGATION FOR ORDZTM56YW');
    
    // Try to use the mobile database approach
    sqflite.databaseFactory = sqflite.databaseFactory;
    
    // Use sqflite's getDatabasesPath equivalent for desktop
    final appDocDir = '${Platform.resolvedExecutable.replaceAll('\\', '/').split('/').sublist(0, Platform.resolvedExecutable.split('\\').length - 1).join('/')}/data';
    final dbPath = join(appDocDir, 'tailor_app.db');
    
    print('📁 Trying database path: $dbPath');
    
    // Also try the ffi approach as fallback
    sqfliteFfiInit();
    final db = await openDatabase(
      dbPath,
      readOnly: true, // Don't modify, just read
      singleInstance: false,
    );
    
    print('✅ Database opened successfully');
    
    // Quick check for the order
    final orderCheck = await db.rawQuery(
      "SELECT unique_id, customer_name FROM orders WHERE unique_id = 'ORDZTM56YW' LIMIT 1"
    );
    
    if (orderCheck.isNotEmpty) {
      print('✅ Order ORDZTM56YW found: ${orderCheck.first}');
      
      // Check payments
      final paymentCheck = await db.rawQuery(
        "SELECT COUNT(*) as count FROM payment WHERE order_id = 'ORDZTM56YW' AND is_deleted = 0"
      );
      print('💰 Existing payments count: ${paymentCheck.first['count']}');
      
    } else {
      print('❌ Order ORDZTM56YW not found');
      
      // Show first few orders
      final sampleOrders = await db.rawQuery("SELECT unique_id FROM orders LIMIT 5");
      print('Sample order IDs:');
      for (final order in sampleOrders) {
        print('  - ${order['unique_id']}');
      }
    }
    
    await db.close();
    print('🏁 Quick check completed');
    
  } catch (e) {
    print('❌ Error: $e');
    
    // Try alternative database locations
    print('\n🔍 Trying alternative locations...');
    
    final altPaths = [
      'tailor_app.db',
      'data/tailor_app.db',
      '../data/tailor_app.db',
    ];
    
    for (final altPath in altPaths) {
      try {
        print('Checking: $altPath');
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        
        final db = await openDatabase(altPath, readOnly: true);
        final result = await db.rawQuery("SELECT COUNT(*) as count FROM orders");
        print('✅ Found database at $altPath with ${result.first['count']} orders');
        await db.close();
        break;
      } catch (e2) {
        print('  ❌ Not found: ${e2.toString().split('\n').first}');
      }
    }
  }
}