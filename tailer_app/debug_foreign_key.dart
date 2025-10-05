import 'lib/data/services/local_db_service.dart';

void main() async {
  final db = LocalDatabaseService();
  
  print('=== FOREIGN KEY DEBUGGING ===');
  
  // 1. Check if order exists
  final orders = await db.select('orders', where: 'unique_id = ?', whereArgs: ['ORDZTM56YW']);
  print('Order ORDZTM56YW exists: ${orders.isNotEmpty}');
  if (orders.isNotEmpty) {
    print('Order details: ${orders.first}');
  }
  
  // 2. Check foreign key constraints
  final database = await db.database;
  final foreignKeys = await database.rawQuery('PRAGMA foreign_key_list(payment)');
  print('\nForeign key constraints on payment table:');
  for (var fk in foreignKeys) {
    print('  $fk');
  }
  
  // 3. Check if foreign keys are enabled
  final fkEnabled = await database.rawQuery('PRAGMA foreign_keys');
  print('\nForeign keys enabled: $fkEnabled');
  
  // 4. Try direct insertion with debugging
  print('\n=== TESTING DIRECT INSERTION ===');
  try {
    final testPaymentId = 'TEST_PAYMENT_${DateTime.now().millisecondsSinceEpoch}';
    await database.rawInsert('''
      INSERT INTO payment (id, unique_id, order_id, amount, method, notes, paid_on, created_at, updated_at, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      testPaymentId,
      testPaymentId,
      'ORDZTM56YW',
      100.0,
      'cash',
      'Test payment',
      DateTime.now().toIso8601String(),
      DateTime.now().toIso8601String(),
      DateTime.now().toIso8601String(),
      0
    ]);
    print('✅ Direct insertion successful!');
    
    // Clean up
    await database.rawDelete('DELETE FROM payment WHERE id = ?', [testPaymentId]);
  } catch (e) {
    print('❌ Direct insertion failed: $e');
  }
  
  // 5. Check orders table structure
  final orderSchema = await database.rawQuery('PRAGMA table_info(orders)');
  print('\nOrders table structure:');
  for (var col in orderSchema) {
    print('  $col');
  }
  
  // 6. Check payment table structure  
  final paymentSchema = await database.rawQuery('PRAGMA table_info(payment)');
  print('\nPayment table structure:');
  for (var col in paymentSchema) {
    print('  $col');
  }
}