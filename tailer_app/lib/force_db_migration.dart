import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'data/services/local_db_service.dart';
import 'core/utils/logger.dart';

/// Force Database Creation & Migration Utility
/// 
/// This script ensures the database is created on app startup.
/// It will create the database file if it doesn't exist.
/// 
/// VERSION 13 - WITH is_active FIELD:
/// - Creates database file if missing
/// - Creates ALL tables with proper schema
/// - Includes is_active field in tailor table
/// - Adds proper FOREIGN KEY CASCADE constraints
/// - Creates all necessary indexes
/// 
/// USAGE:
/// 1. This runs automatically on app startup (called in main.dart)
/// 2. Safe to keep - checks if database exists first
/// 3. Creates database on first app launch

Future<void> forceDatabaseMigration() async {
  try {
    Logger.info('ForceMigration', '========================================');
    Logger.info('ForceMigration', '   DATABASE INITIALIZATION (v13)');
    Logger.info('ForceMigration', '========================================');
    
    // Get database path
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'tailor_app.db');
    
    Logger.info('ForceMigration', 'Database path: $path');
    
    // Check if database file exists
    final dbFile = File(path);
    final existsBefore = await dbFile.exists();
    
    if (existsBefore) {
      Logger.info('ForceMigration', '✅ Database already exists');
    } else {
      Logger.info('ForceMigration', '⚠️  Database does NOT exist - creating now...');
    }
    
    final dbService = LocalDatabaseService();
    
    // Open database - this will create it if it doesn't exist
    Logger.info('ForceMigration', 'Opening/creating database...');
    final db = await dbService.database;
    Logger.info('ForceMigration', '✅ Database opened successfully');
    
    // Verify database file was created
    final existsAfter = await dbFile.exists();
    if (existsAfter) {
      Logger.info('ForceMigration', '✅ Database file confirmed to exist');
      
      final stats = await dbFile.stat();
      Logger.info('ForceMigration', '💾 Database size: ${(stats.size / 1024).toStringAsFixed(2)} KB');
    } else {
      Logger.error('ForceMigration', '❌ Database file was NOT created!');
    }
    
    // Verify database version
    final version = await db.getVersion();
    Logger.info('ForceMigration', '📌 Database version: $version');
    
    // Verify tailor table has is_active column
    Logger.info('ForceMigration', '');
    Logger.info('ForceMigration', 'Verifying tailor table schema...');
    final tailorSchema = await db.rawQuery('PRAGMA table_info(tailor)');
    final hasIsActive = tailorSchema.any((col) => col['name'] == 'is_active');
    Logger.info('ForceMigration', hasIsActive 
      ? '✅ is_active column exists in tailor table' 
      : '❌ is_active column MISSING from tailor table'
    );
    
    // Get database stats to verify
    Logger.info('ForceMigration', '');
    Logger.info('ForceMigration', 'Checking database tables...');
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
    Logger.info('ForceMigration', '✅ DATABASE INITIALIZATION COMPLETED!');
    Logger.info('ForceMigration', '========================================');
    Logger.info('ForceMigration', '');
    Logger.info('ForceMigration', '💡 Database location: $path');
    Logger.info('ForceMigration', '✅ Safe to keep this call - it checks existence first');
    Logger.info('ForceMigration', '========================================');
    
  } catch (e, stackTrace) {
    Logger.error('ForceMigration', 'Database initialization failed', error: e, stackTrace: stackTrace);
    Logger.info('ForceMigration', '========================================');
    Logger.info('ForceMigration', '❌ DATABASE INITIALIZATION FAILED');
    Logger.info('ForceMigration', 'Error: $e');
    Logger.info('ForceMigration', '========================================');
    
    // Don't rethrow - allow app to continue
    // The splash screen will also attempt database initialization
    Logger.warning('ForceMigration', 'Continuing app startup - splash screen will retry initialization');
  }
}
