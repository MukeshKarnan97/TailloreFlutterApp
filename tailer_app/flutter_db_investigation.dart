import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Quick database investigation script for ORDZTM56YW issue
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('=== INVESTIGATING ORDZTM56YW FOREIGN KEY ISSUE ===');
    
    // Use the same method as the app
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'tailor_app.db');
    print('Database path: $path');
    
    // Open database
    final db = await openDatabase(path);
    
    // Check if foreign keys are enabled
    final pragmaResult = await db.rawQuery('PRAGMA foreign_keys');
    print('Foreign keys status: $pragmaResult');
    
    // Check orders table structure
    print('\n=== ORDERS TABLE SCHEMA ===');
    final ordersSchema = await db.rawQuery('PRAGMA table_info(orders)');
    for (final column in ordersSchema) {
      print('Column: ${column['name']}, Type: ${column['type']}, NotNull: ${column['notnull']}, PK: ${column['pk']}');
    }
    
    // Check if order ORDZTM56YW exists
    print('\n=== ORDER ORDZTM56YW CHECK ===');
    final orderCheck = await db.rawQuery(
      'SELECT unique_id, customer_name, total_amount, advance_paid FROM orders WHERE unique_id = ?',
      ['ORDZTM56YW']
    );
    if (orderCheck.isNotEmpty) {
      print('Order found: $orderCheck');
      
      // Let's check the exact data types and values
      final orderData = orderCheck.first;
      print('unique_id type: ${orderData['unique_id'].runtimeType}');
      print('unique_id value: "${orderData['unique_id']}"');
      print('unique_id length: ${orderData['unique_id'].toString().length}');
    } else {
      print('❌ Order ORDZTM56YW NOT FOUND in orders table');
    }
    
    // Check foreign key constraints
    print('\n=== FOREIGN KEY CONSTRAINTS ===');
    final foreignKeys = await db.rawQuery('PRAGMA foreign_key_list(payments)');
    for (final fk in foreignKeys) {
      print('FK: payments.${fk['from']} -> ${fk['table']}.${fk['to']}');
    }
    
    // Test if we can insert a payment with a different order_id that exists
    print('\n=== TESTING FOREIGN KEY CONSTRAINT ===');
    final allOrders = await db.rawQuery('SELECT unique_id FROM orders LIMIT 5');
    print('Available order IDs:');
    for (final order in allOrders) {
      print('  "${order['unique_id']}" (${order['unique_id'].runtimeType})');
    }
    
    // Try to understand the constraint by checking the exact constraint definition
    print('\n=== PAYMENTS TABLE SCHEMA ===');
    final paymentsSchema = await db.rawQuery('PRAGMA table_info(payments)');
    for (final column in paymentsSchema) {
      print('Column: ${column['name']}, Type: ${column['type']}, NotNull: ${column['notnull']}, PK: ${column['pk']}');
    }
    
    // Check the table creation SQL
    print('\n=== TABLE CREATION SQL ===');
    final sqlInfo = await db.rawQuery("SELECT sql FROM sqlite_master WHERE type='table' AND name='payments'");
    if (sqlInfo.isNotEmpty) {
      print('Payments table SQL: ${sqlInfo.first['sql']}');
    }
    
    await db.close();
    print('\n✅ Database investigation completed successfully!');
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  }
}