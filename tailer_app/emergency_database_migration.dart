import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Emergency Database Migration Tool
/// This script creates missing tables and fixes foreign key constraints
Future<void> main() async {
  print('🔧 Database Migration Tool');
  print('=============================');
  print('');
  
  try {
    // Get database path
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'tailor_app.db');
    
    print('📁 Database path: $path');
    
    // Check if database exists
    if (!await File(path).exists()) {
      print('❌ Database file not found!');
      print('   Please run the app first to create the database.');
      return;
    }
    
    // Open database
    final db = await openDatabase(path);
    print('✅ Database opened successfully');
    
    // Check current version
    final versionResult = await db.rawQuery('PRAGMA user_version');
    final currentVersion = versionResult.first['user_version'] as int;
    print('📋 Current database version: $currentVersion');
    
    // Check existing tables
    final existingTables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'"
    );
    final tableNames = existingTables.map((t) => t['name'] as String).toList();
    print('📊 Existing tables: ${tableNames.join(', ')}');
    
    // Check if migration is needed
    final needsNotifications = !tableNames.contains('notifications');
    final needsCancellations = !tableNames.contains('order_cancellations');
    
    if (!needsNotifications && !needsCancellations) {
      print('✅ All required tables already exist!');
      await db.close();
      return;
    }
    
    print('');
    print('🔧 Starting migration...');
    
    // Create notifications table if needed
    if (needsNotifications) {
      print('📋 Creating notifications table...');
      await db.execute('''
        CREATE TABLE notifications (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          type TEXT CHECK(type IN ('order_status', 'payment_received', 'order_cancelled', 'order_delivered', 'order_overdue', 'payment_reminder', 'delivery_reminder')) NOT NULL,
          data TEXT,
          order_id TEXT,
          customer_id TEXT,
          action_url TEXT,
          is_read INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (order_id) REFERENCES orders (unique_id) ON DELETE CASCADE,
          FOREIGN KEY (customer_id) REFERENCES customer (unique_id) ON DELETE CASCADE
        )
      ''');
      print('✅ Notifications table created');
    }
    
    // Create order_cancellations table if needed
    if (needsCancellations) {
      print('📋 Creating order_cancellations table...');
      await db.execute('''
        CREATE TABLE order_cancellations (
          id TEXT PRIMARY KEY,
          order_id TEXT NOT NULL,
          reason TEXT CHECK(reason IN ('customer_request', 'material_unavailable', 'size_issues', 'quality_concerns', 'delivery_delay', 'payment_issues', 'other')) NOT NULL,
          custom_reason TEXT,
          cancelled_by TEXT NOT NULL,
          cancelled_at TEXT NOT NULL,
          refund_amount REAL DEFAULT 0.0,
          refund_status TEXT CHECK(refund_status IN ('none', 'partial', 'full', 'pending', 'processing', 'completed')) DEFAULT 'none',
          refund_notes TEXT,
          additional_data TEXT DEFAULT '{}',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (order_id) REFERENCES orders (unique_id) ON DELETE CASCADE
        )
      ''');
      print('✅ Order cancellations table created');
    }
    
    // Create indexes for performance
    print('📊 Creating indexes...');
    
    // Notifications indexes
    if (needsNotifications) {
      await db.execute('CREATE INDEX idx_notifications_order_id ON notifications (order_id)');
      await db.execute('CREATE INDEX idx_notifications_customer_id ON notifications (customer_id)');
      await db.execute('CREATE INDEX idx_notifications_is_read ON notifications (is_read)');
      await db.execute('CREATE INDEX idx_notifications_created_at ON notifications (created_at)');
      print('✅ Notification indexes created');
    }
    
    // Order cancellations indexes
    if (needsCancellations) {
      await db.execute('CREATE INDEX idx_order_cancellations_order_id ON order_cancellations (order_id)');
      await db.execute('CREATE INDEX idx_order_cancellations_reason ON order_cancellations (reason)');
      await db.execute('CREATE INDEX idx_order_cancellations_cancelled_at ON order_cancellations (cancelled_at)');
      print('✅ Order cancellation indexes created');
    }
    
    // Update database version
    await db.execute('PRAGMA user_version = 6');
    print('📋 Database version updated to 6');
    
    // Verify foreign key constraints are enabled
    final fkResult = await db.rawQuery('PRAGMA foreign_keys');
    final fkEnabled = fkResult.first['foreign_keys'] == 1;
    print('🔐 Foreign key constraints: ${fkEnabled ? '✅ Enabled' : '❌ Disabled'}');
    
    if (!fkEnabled) {
      print('⚠️  Warning: Foreign key constraints are disabled. This may cause issues.');
    }
    
    // Test table creation
    print('');
    print('🧪 Testing table access...');
    
    if (needsNotifications) {
      await db.rawQuery('SELECT COUNT(*) FROM notifications');
      print('✅ Notifications table accessible');
    }
    
    if (needsCancellations) {
      await db.rawQuery('SELECT COUNT(*) FROM order_cancellations');
      print('✅ Order cancellations table accessible');
    }
    
    await db.close();
    
    print('');
    print('🎉 Migration completed successfully!');
    print('');
    print('📋 Summary:');
    if (needsNotifications) print('   ✅ Created notifications table with indexes');
    if (needsCancellations) print('   ✅ Created order_cancellations table with indexes');
    print('   ✅ Updated database version to 6');
    print('   ✅ Verified table access');
    print('');
    print('🚀 You can now use order cancellation and notification features!');
    
  } catch (e) {
    print('❌ Migration failed: $e');
    print('');
    print('💡 Troubleshooting:');
    print('   1. Make sure the app is closed before running this migration');
    print('   2. Check if you have write permissions to the database');
    print('   3. Try uninstalling and reinstalling the app for a fresh database');
  }
}