import 'package:tailer_app/data/services/local_db_service.dart';
import 'package:tailer_app/data/services/auth_service.dart';
import 'package:tailer_app/core/utils/logger.dart';

/// Migration utility to update legacy orders and customers with hardcoded tailor_id
/// to use the current authenticated user's email
class TailorIdMigration {
  static Future<void> migrateLegacyData() async {
    try {
      Logger.info('TailorIdMigration', 'Starting legacy data migration...');
      
      final authService = AuthService();
      await authService.initialize();
      
      if (authService.currentUser == null) {
        Logger.error('TailorIdMigration', 'No authenticated user found. Cannot migrate data.');
        return;
      }
      
      final userEmail = authService.currentUser!.email;
      Logger.info('TailorIdMigration', 'Migrating data to user: $userEmail');
      
      final dbService = LocalDatabaseService();
      final db = await dbService.database;
      
      // Update orders with legacy tailor_id
      final ordersUpdated = await db.rawUpdate(
        'UPDATE orders SET tailor_id = ? WHERE tailor_id = ?',
        [userEmail, 'tailor_001']
      );
      Logger.info('TailorIdMigration', 'Updated $ordersUpdated orders');
      
      // Update customers with legacy tailor_id
      final customersUpdated = await db.rawUpdate(
        'UPDATE customers SET tailor_id = ? WHERE tailor_id = ?',
        [userEmail, 'tailor_001']
      );
      Logger.info('TailorIdMigration', 'Updated $customersUpdated customers');
      
      // Update payments if they have tailor_id column (they might not)
      try {
        final paymentsUpdated = await db.rawUpdate(
          'UPDATE payment SET tailor_id = ? WHERE tailor_id = ?',
          [userEmail, 'tailor_001']
        );
        Logger.info('TailorIdMigration', 'Updated $paymentsUpdated payments');
      } catch (e) {
        Logger.debug('TailorIdMigration', 'Payments table might not have tailor_id column: $e');
      }
      
      Logger.info('TailorIdMigration', '✅ Migration completed successfully!');
      Logger.info('TailorIdMigration', 'Total records updated: ${ordersUpdated + customersUpdated}');
      
    } catch (e, stackTrace) {
      Logger.error('TailorIdMigration', 'Migration failed', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Check if migration is needed (if any records have tailor_001)
  static Future<bool> isMigrationNeeded() async {
    try {
      final dbService = LocalDatabaseService();
      final db = await dbService.database;
      
      final orders = await db.rawQuery(
        'SELECT COUNT(*) as count FROM orders WHERE tailor_id = ?',
        ['tailor_001']
      );
      
      final customers = await db.rawQuery(
        'SELECT COUNT(*) as count FROM customers WHERE tailor_id = ?',
        ['tailor_001']
      );
      
      final orderCount = orders.first['count'] as int;
      final customerCount = customers.first['count'] as int;
      
      if (orderCount > 0 || customerCount > 0) {
        Logger.info('TailorIdMigration', 'Found $orderCount orders and $customerCount customers needing migration');
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('TailorIdMigration', 'Error checking migration status', error: e);
      return false;
    }
  }
}
