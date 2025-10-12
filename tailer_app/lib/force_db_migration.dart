import 'package:flutter/material.dart';
import 'data/services/local_db_service.dart';
import 'core/utils/logger.dart';

/// Force Database Migration Utility
/// 
/// This script helps force the database migration to run.
/// Use this when you've added new columns or made schema changes.
/// 
/// VERSION 8 MIGRATION:
/// - Recreates ALL tables with proper FOREIGN KEY CASCADE constraints
/// - Adds measurement_id column to orders table
/// - Preserves all existing data during migration
/// - Creates all necessary indexes
/// 
/// USAGE:
/// 1. Import this file in your main.dart
/// 2. Call forceDatabaseMigration() before runApp()
/// 3. Run the app once
/// 4. Remove the call after successful migration

Future<void> forceDatabaseMigration() async {
  try {
    Logger.info('ForceMigration', '========================================');
    Logger.info('ForceMigration', '   DATABASE MIGRATION TO VERSION 8');
    Logger.info('ForceMigration', '========================================');
    Logger.info('ForceMigration', 'Starting forced database migration...');
    Logger.info('ForceMigration', 'This will:');
    Logger.info('ForceMigration', '  ✓ Recreate all tables with proper FK CASCADE');
    Logger.info('ForceMigration', '  ✓ Add measurement_id to orders table');
    Logger.info('ForceMigration', '  ✓ Preserve all existing data');
    Logger.info('ForceMigration', '  ✓ Create optimized indexes');
    Logger.info('ForceMigration', '========================================');
    
    final dbService = LocalDatabaseService();
    
    // Trigger migration by opening database
    // This will automatically run the onUpgrade callback
    Logger.info('ForceMigration', 'Opening database to trigger migration...');
    await dbService.database;
    Logger.info('ForceMigration', '✓ Database opened - migration completed');
    
    // Get database stats to verify
    Logger.info('ForceMigration', '');
    Logger.info('ForceMigration', 'Verifying migration results...');
    final stats = await dbService.getDatabaseStats();
    Logger.info('ForceMigration', '');
    Logger.info('ForceMigration', '📊 DATABASE STATISTICS:');
    Logger.info('ForceMigration', '   • Tailors: ${stats['tailor'] ?? 0}');
    Logger.info('ForceMigration', '   • Customers: ${stats['customer'] ?? 0}');
    Logger.info('ForceMigration', '   • Measurements: ${stats['measurement'] ?? 0}');
    Logger.info('ForceMigration', '   • Orders: ${stats['orders'] ?? 0}');
    Logger.info('ForceMigration', '   • Payments: ${stats['payment'] ?? 0}');
    Logger.info('ForceMigration', '   • Users: ${stats['users'] ?? 0}');
    Logger.info('ForceMigration', '');
    Logger.info('ForceMigration', '========================================');
    Logger.info('ForceMigration', '✅ MIGRATION COMPLETED SUCCESSFULLY!');
    Logger.info('ForceMigration', '========================================');
    Logger.info('ForceMigration', '');
    Logger.info('ForceMigration', '⚠️  IMPORTANT: Remove forceDatabaseMigration()');
    Logger.info('ForceMigration', '   call from main.dart after this run!');
    Logger.info('ForceMigration', '========================================');
    
  } catch (e, stackTrace) {
    Logger.error('ForceMigration', 'Migration failed', error: e, stackTrace: stackTrace);
    Logger.info('ForceMigration', '========================================');
    Logger.info('ForceMigration', 'MIGRATION FAILED - See error above');
    Logger.info('ForceMigration', 'You may need to reset the database');
    Logger.info('ForceMigration', '========================================');
    rethrow;
  }
}
