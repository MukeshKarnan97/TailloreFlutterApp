import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  print('=== SIMPLE DB CHECK ===');
  
  // Get database path
  final databasesPath = await getDatabasesPath();
  final path = join(databasesPath, 'tailor_app.db');
  print('Database path: $path');
  
  // Open database
  final db = await openDatabase(path);
  
  // Check if order exists
  final orders = await db.query('orders', where: 'unique_id = ?', whereArgs: ['ORDZTM56YW']);
  print('Order ORDZTM56YW exists: ${orders.isNotEmpty}');
  
  if (orders.isNotEmpty) {
    print('Order: ${orders.first}');
  }
  
  // Check existing payments for this order
  final payments = await db.query('payment', where: 'order_id = ?', whereArgs: ['ORDZTM56YW']);
  print('Existing payments for ORDZTM56YW: ${payments.length}');
  
  // Check foreign key constraints
  final fkList = await db.rawQuery('PRAGMA foreign_key_list(payment)');
  print('Foreign key constraints on payment:');
  for (var fk in fkList) {
    print('  $fk');
  }
  
  // Check if foreign keys are enabled
  final fkEnabled = await db.rawQuery('PRAGMA foreign_keys');
  print('Foreign keys enabled: $fkEnabled');
  
  // Test insert manually
  try {
    await db.insert('payment', {
      'id': 'TEST123',
      'unique_id': 'TEST123', 
      'order_id': 'ORDZTM56YW',
      'amount': 50.0,
      'method': 'cash',
      'notes': 'test',
      'paid_on': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'is_deleted': 0,
    });
    print('✅ Manual insert successful');
    
    // Clean up
    await db.delete('payment', where: 'id = ?', whereArgs: ['TEST123']);
  } catch (e) {
    print('❌ Manual insert failed: $e');
  }
  
  await db.close();
}