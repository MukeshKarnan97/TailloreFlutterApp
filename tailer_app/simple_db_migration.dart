import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

void main() async {
  print('Starting Database Migration...');
  
  // Get database path
  final databasePath = await getDatabasesPath();
  final dbPath = path.join(databasePath, 'tailor_app.db');
  
  print('Database path: $dbPath');
  
  if (!await File(dbPath).exists()) {
    print('Database file does not exist at $dbPath');
    return;
  }
  
  try {
    final db = await openDatabase(dbPath);
    
    // Check current version
    final version = await db.getVersion();
    print('Current database version: $version');
    
    // Check which tables exist
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table';"
    );
    
    print('Existing tables:');
    for (final table in tables) {
      print('  - ${table['name']}');
    }
    
    // Check if order_cancellations table exists
    final orderCancellationsExists = tables.any(
      (table) => table['name'] == 'order_cancellations'
    );
    
    // Check if notifications table exists
    final notificationsExists = tables.any(
      (table) => table['name'] == 'notifications'
    );
    
    print('order_cancellations table exists: $orderCancellationsExists');
    print('notifications table exists: $notificationsExists');
    
    // Create missing tables
    if (!orderCancellationsExists) {
      print('Creating order_cancellations table...');
      await db.execute('''
        CREATE TABLE order_cancellations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_id INTEGER NOT NULL,
          reason TEXT NOT NULL,
          description TEXT,
          cancelled_by TEXT NOT NULL,
          cancelled_at TEXT NOT NULL,
          refund_status TEXT DEFAULT 'pending',
          refund_amount REAL,
          FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
        )
      ''');
      print('order_cancellations table created successfully!');
    } else {
      print('order_cancellations table already exists');
    }
    
    if (!notificationsExists) {
      print('Creating notifications table...');
      await db.execute('''
        CREATE TABLE notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          data TEXT,
          is_read INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          user_id TEXT
        )
      ''');
      print('notifications table created successfully!');
    } else {
      print('notifications table already exists');
    }
    
    // Create indexes
    if (!orderCancellationsExists) {
      print('Creating indexes for order_cancellations...');
      await db.execute('''
        CREATE INDEX idx_order_cancellations_order_id ON order_cancellations(order_id)
      ''');
      await db.execute('''
        CREATE INDEX idx_order_cancellations_cancelled_at ON order_cancellations(cancelled_at)
      ''');
    }
    
    if (!notificationsExists) {
      print('Creating indexes for notifications...');
      await db.execute('''
        CREATE INDEX idx_notifications_type ON notifications(type)
      ''');
      await db.execute('''
        CREATE INDEX idx_notifications_is_read ON notifications(is_read)
      ''');
      await db.execute('''
        CREATE INDEX idx_notifications_created_at ON notifications(created_at)
      ''');
    }
    
    // Update database version to 6
    await db.setVersion(6);
    print('Database version updated to 6');
    
    // Verify the migration
    final newVersion = await db.getVersion();
    final newTables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table';"
    );
    
    print('\nMigration completed!');
    print('New database version: $newVersion');
    print('All tables:');
    for (final table in newTables) {
      print('  - ${table['name']}');
    }
    
    await db.close();
    print('Database migration successful!');
    
  } catch (e) {
    print('Error during migration: $e');
  }
}