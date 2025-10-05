import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  try {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    // Common Windows Flutter database paths
    final possiblePaths = [
      join(Directory.current.path, 'tailor_app.db'),
      join(Directory.current.path, '.dart_tool', 'chrome-device', 'Default', 'databases', 'tailor_app.db'),
      join(Platform.environment['APPDATA'] ?? '', 'tailor_app', 'tailor_app.db'),
      join(Platform.environment['LOCALAPPDATA'] ?? '', 'tailor_app', 'tailor_app.db'),
    ];
    
    String? databasePath;
    for (final path in possiblePaths) {
      print('Checking: $path');
      if (await File(path).exists()) {
        databasePath = path;
        print('✅ Database found at: $path');
        break;
      }
    }
    
    if (databasePath == null) {
      print('❌ Database file not found in any of the expected locations');
      // Try to find any .db files
      print('\nSearching for .db files...');
      final files = await Directory.current.list(recursive: true).where((entity) => 
        entity is File && entity.path.endsWith('.db')).toList();
      for (final file in files) {
        print('Found: ${file.path}');
      }
      return;
    }
    
    // Open database
    final db = await openDatabase(databasePath);
    
    // Check if foreign keys are enabled
    final pragmaResult = await db.rawQuery('PRAGMA foreign_keys');
    print('Foreign keys status: $pragmaResult');
    
    // Check orders table structure
    print('\n=== ORDERS TABLE SCHEMA ===');
    final ordersSchema = await db.rawQuery('PRAGMA table_info(orders)');
    for (final column in ordersSchema) {
      print('Column: ${column['name']}, Type: ${column['type']}, NotNull: ${column['notnull']}, PK: ${column['pk']}');
    }
    
    // Check payments table structure
    print('\n=== PAYMENTS TABLE SCHEMA ===');
    final paymentsSchema = await db.rawQuery('PRAGMA table_info(payments)');
    for (final column in paymentsSchema) {
      print('Column: ${column['name']}, Type: ${column['type']}, NotNull: ${column['notnull']}, PK: ${column['pk']}');
    }
    
    // Check foreign key constraints
    print('\n=== FOREIGN KEY CONSTRAINTS ===');
    final foreignKeys = await db.rawQuery('PRAGMA foreign_key_list(payments)');
    for (final fk in foreignKeys) {
      print('FK: ${fk['from']} -> ${fk['table']}.${fk['to']}');
    }
    
    // Check if order ORDZTM56YW exists
    print('\n=== ORDER ORDZTM56YW CHECK ===');
    final orderCheck = await db.rawQuery(
      'SELECT unique_id, customer_name, total_amount, advance_paid FROM orders WHERE unique_id = ?',
      ['ORDZTM56YW']
    );
    if (orderCheck.isNotEmpty) {
      print('Order found: $orderCheck');
    } else {
      print('Order ORDZTM56YW NOT FOUND in orders table');
    }
    
    // Check existing payments for this order
    print('\n=== EXISTING PAYMENTS FOR ORDZTM56YW ===');
    final existingPayments = await db.rawQuery(
      'SELECT * FROM payments WHERE order_id = ? AND is_deleted = 0',
      ['ORDZTM56YW']
    );
    print('Existing payments: $existingPayments');
    
    // Try to understand why foreign key fails - check exact unique_id values
    print('\n=== ALL ORDER IDs ===');
    final allOrderIds = await db.rawQuery('SELECT unique_id FROM orders LIMIT 10');
    for (final order in allOrderIds) {
      print('Order ID: "${order['unique_id']}" (length: ${order['unique_id'].toString().length})');
    }
    
    await db.close();
    print('\nDatabase check completed successfully!');
    
  } catch (e) {
    print('Error: $e');
  }
}